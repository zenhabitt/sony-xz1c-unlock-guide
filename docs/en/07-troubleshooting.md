# 07 · Troubleshooting

[中文](../07-排错手册.md) | **English**

> Every entry below actually happened on the reference unit. Look up by symptom.

| Type | When to use |
|---|---|
| Reference | while debugging, or read once before starting |
| Risk | — (read-only) |

---

## 7.1 Quick table

| # | Symptom | Real cause | Fix |
|---|---|---|---|
| 1 | every `-s` gives `test2 not hit` | **XFL content is wrong**, not a version issue | confirm you wrote `xfl-o77.mbn` (13,153,250 B / `c745a327…`) |
| 2 | `oem unlock Y` returns OKAY but `unlocked: no` | unlock needs a reboot | reboot, then recheck |
| 3 | infinite boot loop after unlocking (splash) | `/data` key invalid | format data or reflash |
| 4 | newflasher `*** buffer overflow detected ***` | answered `y` to TA dump | rerun, answer `n` |
| 5 | newflasher `getvar:max-download-size` timeout | flash session wedged | unplug/replug, re-enter flash mode |
| 6 | `fastboot boot twrp-*.img` hangs at white logo | TWRP incompatible here | use Lineage recovery |
| 7 | sideload fails with `E3004` | sideloading from stock recovery | sideload from Lineage recovery |
| 8 | `adb shell su` → `request rejected (2000)` | Magisk 31 removed the ADB su toggle | apps still work; downgrade Magisk for adb root |
| 9 | proxy/HTTPS reports "secure connection failed" | **wrong system time**, TLS validation fails | set the clock manually |
| 10 | xperable `Pipe error`, device leaves fastboot | `-s` too large | try a smaller neighbour |
| 11 | P114 bootloader rejected | ABL variant signature mismatch | pick 5ADA/5D31/C93B per bootdelivery |
| 12 | no call audio after unlocking | known docomo 8.0 bug | flash Android 9 stock to fix |
| 13 | `fastboot devices` empty | driver is not WinUSB | reinstall with Zadig |
| 14 | `adb devices` shows `unauthorized` | authorisation not granted | replug, tap Allow |
| 15 | NFC dead after LineageOS | flashed a non-NFC variant | reflash the `-nfc-` build |

---

## 7.2 Details

### 1. "test2 not hit" — the most common misdiagnosis

Many guides claim the XFL version is "too new". **That is wrong.**

xperable needs an **O77 blob at a specific offset** in the XFL partition. It is unrelated
to the rest of the partition or the system version.

Do it properly: `dd` `xfl-o77.mbn` to the start of the partition, then verify the first
13,153,250 bytes:

```sh
sha256sum /sdcard/xfl_head.bin
# must be c745a32721d68bb7499a0e929bd9bcfec307cb922d0c17c22f064a51e6e1a7c7
```

Mismatch means the write did not land, or the downloaded blob is corrupt.

---

### 2. Boot loop after unlocking

Symptom: Sony splash → black → reboot → repeat.

Cause: `/data` is encrypted with a key held in TEE. Unlocking the bootloader changes the TEE
state, the old key no longer decrypts, `/data` cannot mount, the system never boots.

Try in increasing order of effort:

```bash
fastboot -w            # 1. format first
# 2. reflash stock 8.0 with newflasher
# 3. full reflash + format
```

On the reference unit, reflashing stock 8.0 recovered it.

---

### 3. Why all four newflasher prompts are `n`

| Prompt | Why not `y` |
|---|---|
| GordonGate driver | install it separately if needed |
| dump trim area (TA) | **triggers a buffer overflow crash**, and without sake auth you cannot get DRM anyway |
| flash to both a/b slots | single-SIM device; dual-slot is risky |
| flash persist | **loses the attestation key permanently** |

---

### 4. Magisk 31 and ADB su

```
su: request rejected (2000)
```

Newer Magisk removed the global "superuser access" toggle, so ADB-initiated su is denied
by default.

Impact: `adb root` and su inside scripts fail. App-level root is unaffected.

Need adb root → install Magisk 26.x / 27.x.

---

### 5. The "random" network failure caused by the clock

Proxy software reporting "secure connection failed", certificate errors — after a long
debugging session the cause was a **system clock off by more than two hours**.

```bash
$ADB shell date
```

Fix: set the time manually in Settings (auto-sync needs NTP, UDP 123 is often blocked).

---

## 7.3 Diagnostic commands

```bash
# device state
$ADB shell getprop ro.boot.verifiedbootstate   # orange = unlocked
$ADB shell getprop ro.boot.flash.locked        # 0 = unlocked
$ADB shell getprop ro.build.version.release
$ADB shell getprop ro.build.id

# fastboot
$FB getvar unlocked
$FB getvar version-bootloader
$FB getvar all 2>&1 | grep -iE "unlock|lock|slot"

# partitions (needs root)
$ADB shell "ls -l /dev/block/bootdevice/by-name/"

# logs
$ADB logcat -d | grep -iE "fatal|panic|avc"
$ADB shell dmesg | grep -i error
```

---

## 7.4 When to stop

- `newflasher` prints `flash:bootloader FAILED`
- Device manager shows `QUSB_BULK` / `9008` (EDL)
- Two consecutive flashes fail with different symptoms

EDL recovery requires a signed firehose; it is not user-recoverable. Normal operation
**never** enters EDL.

---

Previous ← [06 · LineageOS](06-lineageos.md) | Next → [08 · Rollback and recovery](08-rollback-and-recovery.md)
