# 04 · Unlocking the Bootloader with xperable ★

[中文](../04-xperable解锁.md) | **English**

> Patch fastboot in memory so it accepts `oem unlock`. No partition changes, no TA wipe,
> no official unlock code.

| Difficulty | Time | Risk | Prerequisite |
|---|---|---|---|
| ★★★ | 20 min (excluding `-s` sweeps) | **High** — the only step that can brick | All of [03](03-temp-root-and-xfl.md) passed |

---

## 4.1 How it works

`xperable` exploits a buffer overflow in the ABL fastboot command parser (CVE-2021-1931)
to place a `LinuxLoader` PE image in memory and jump to it.

The patched fastboot no longer verifies the `oem unlock` permission bit, so it returns `OKAY`.

**This is memory-only. It disappears on reboot.**

So the order must be:

```
patch → oem unlock Y → reboot
```

No unplugging, no rebooting, no other fastboot command in between.

---

## 4.2 Preconditions

- [ ] Android 8.0 / 47.1.F.1.105
- [ ] `fastboot getvar version-bootloader` contains `P_114`
- [ ] XFL written with O77 and verified by SHA256 ([03](03-temp-root-and-xfl.md))

---

## 4.3 Patch

Power off → hold **Vol UP** → plug USB → blue LED.

```bash
cd "$KIT/tools/xperable"
./xperable.exe -v -V -B -U -s 0xf69880 -5     # Windows
# ./xperable -v -V -B -U -s 0xf69880 -5       # Linux
```

| Flag | Meaning |
|---|---|
| `-v -V` | verbose USB tracing |
| `-B -U` | bind and use the device |
| `-s 0xf69880` | **overflow size** (value that worked here, see 4.5) |
| `-5` | test5: memory-patch mode |

### Success criteria (both lines required)

```
[+] Got LinuxLoader base addr 0x98dbe000 (0x98de6dc8)
[+] LinuxLoader @ 0x98dbe000 patched successfully (usb buff @ 0x97e79000, distance = 0x00f45000)
```

Preceded by:

```
version-bootloader: 1306-5035_X_Boot_MSM8998_LA2.0_P_114
[.] Using p114 xperable target (offset = 0x30, size = 0xf3f880)
[.] Code boundary of LinuxLoader-p114.pe is 0x000e7000
[+] Starting test5 size = 0xf69880, offset = 0x30, payloadsize = 0xe7000
```

> Only `patched successfully` counts. Exiting right after `OKAY`, or
> `FAILCommand not allowed`, means the patch did not land.

---

## 4.4 Unlock immediately

```bash
./xperable.exe -v -V -c "oem unlock Y" -1
```

Success:

```
{0000000c->0000000c:OK} "oem unlock Y"
{00000040<-00000004:OK} "OKAY"
[.] Finished test1: res = 0
```

Then reboot:

```bash
./xperable.exe -v -V -c reboot -1
```

---

## 4.5 Finding the right `-s`

`-s` controls the overflow size. Because of **memory randomisation**, it differs per unit.

| Device | Working value |
|---|---|
| Reference unit | `0xf69880` |
| Another SO-02K (XDA) | `0xf99880` |
| Upstream default | `0xf3f880` (did not work here) |

### Typical failure modes (none of them mean the device is damaged)

- exits immediately after `Starting test5 ...`
- `FAILCommand not allowed`
- device leaves fastboot and starts charging
- `libusb_bulk_transfer failed: Pipe error`

### Sweep order

```
0xf49880  0xf59880  0xf69880*  0xf79880  0xf89880  0xf99880**
0xfa9880  0xfb9880  0xfc9880  0xfd9880  0xfe9880
```

Finer (0x20000 apart):

```
0xf63880 0xf65880 0xf67880 0xf69880 0xf6b880 0xf6d880 0xf6f880
```

Script: `pwsh scripts/sweep_xperable.ps1 -Kit "$KIT"`

> Before each attempt, confirm `fastboot devices` still sees the device.
> If it dropped out, re-enter: off → Vol UP → USB.

---

## 4.6 Verify the unlock

After reboot, re-enter fastboot:

```bash
$FB getvar unlocked              # unlocked: yes
$FB getvar all | grep -i "lock"  # flash.locked: 0
```

In system:

```bash
$ADB shell getprop ro.boot.verifiedbootstate   # orange
```

---

## 4.7 State after unlocking

- Any partition can be flashed; custom recovery/ROM/Magisk are possible
- **TA / DRM untouched** — the key advantage over the official unlock
- The unlocked state survives reflashing stock firmware

---

## 4.8 Quick troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `test2/test5 not hit` | XFL is not O77 | back to [03](03-temp-root-and-xfl.md) |
| `FAILCommand not allowed` | patch not applied / device rebooted | redo 4.3 |
| `Pipe error`, device leaves fastboot | `-s` too large | try a smaller neighbour |
| OKAY but still locked | not rebooted yet | reboot and recheck |
| Boot loop | /data cannot decrypt | [07](07-troubleshooting.md) §2 |

---

Previous ← [03 · Temp root and XFL](03-temp-root-and-xfl.md) | Next → [05 · Magisk root](05-magisk-root.md)
