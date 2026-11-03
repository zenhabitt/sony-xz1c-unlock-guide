# 01 · Preparation

[中文](../01-准备.md) | **English**

> Goal: get the PC to reliably recognise all three device states and confirm adb / fastboot work.

| Difficulty | Time | Risk | Prerequisite |
|---|---|---|---|
| ★☆☆ | 20–30 min | Low (device untouched) | none |

---

## 1.1 Create a workspace

```bash
mkdir -p ~/sony-kit/{tools,firmware,backup}
export KIT=~/sony-kit          # referenced as $KIT throughout
```

Populate it according to [DOWNLOADS](../../DOWNLOADS.en.md).

---

## 1.2 Install drivers (Windows)

### A. ADB driver

Usually installed automatically once USB debugging is on:

```powershell
$KIT\tools\platform-tools\adb devices
# List of devices attached
# XXXXXXXXXXXX    device
```

`unauthorized` → tap "Allow USB debugging" on the phone.

### B. Fastboot driver (critical)

Windows' built-in driver often refuses Sony devices. Use Zadig:

1. Power off → hold **Vol UP** → plug USB (wait for the blue LED)
2. Device Manager should show an unknown device with a warning icon
3. Right-click `zadig.exe` → **Run as administrator**
4. `Options` → `List All Devices`
5. Select the Sony device (VID `0FCE`)
6. Pick **WinUSB** → `Install Driver` / `Replace Driver`

Verify:

```powershell
$KIT\tools\platform-tools\fastboot devices
# XXXXXXXXXXXX    fastboot
```

### C. Flash mode driver

newflasher needs the device to appear as `SOMC Flash Device`.
If not recognised, install the GordonGate driver as prompted by newflasher,
or the Flashmode driver from Flashtool.

---

## 1.3 The three states

| State | How | LED | Host sees | Used for |
|---|---|---|---|---|
| **Fastboot** | off → hold **Vol UP** → USB | blue | `<serial> fastboot` | xperable, boot/recovery flashing |
| **Flash mode** | off → hold **Vol DOWN** → USB | green | `SOMC Flash Device` | newflasher |
| Normal | power on | — | `<serial> device` | adb shell |

> "Off" means fully powered down from the power menu.

---

## 1.4 Confirm the model

```bash
$ADB shell getprop ro.product.model      # SO-02K
$ADB shell getprop ro.product.device     # lilac
$ADB shell getprop ro.build.version.release   # 8.0.0
$ADB shell getprop ro.build.id                # 47.1.F.1.105
```

**This flow requires Android 8.0 (47.1.F.1.105)** — otherwise do [02](02-flash-8.0-and-p114.md) first.

---

## 1.5 Backups (immediately after temp root in step 03)

| Partition | Command | Reference size |
|---|---|---|
| `xfl` | `dd if=/dev/block/bootdevice/by-name/xfl of=/sdcard/xfl-current.img` | 31,457,280 |
| `abl` | `dd if=/dev/block/bootdevice/by-name/abl of=/sdcard/abl-current.img` | 1,572,864 |
| `boot` | `dd if=/dev/block/bootdevice/by-name/boot of=/sdcard/boot-current.img` | ~19,615,744 |

Pull them to the PC:

```bash
$ADB pull /sdcard/xfl-current.img $KIT/backup/
$ADB pull /sdcard/abl-current.img $KIT/backup/
$ADB pull /sdcard/boot-current.img $KIT/backup/
```

Helpers: `scripts/partinfo.sh` (list partitions), `scripts/dump_bl.sh` (batch dump).

> **Never reuse another device's backups.** Dump your own.

---

## 1.6 Driver troubleshooting

| Symptom | Fix |
|---|---|
| `fastboot devices` empty | reinstall WinUSB via Zadig |
| `adb devices` shows `offline` | replace the cable, re-authorise |
| device keeps reconnecting | try a USB 2.0 port |
| newflasher cannot see the device | install the flash mode driver |

---

Next → [02 · Flash 8.0 and P114](02-flash-8.0-and-p114.md)
