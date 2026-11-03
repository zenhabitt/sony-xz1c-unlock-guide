# 05 · Magisk Root

[中文](../05-Magisk-root.md) | **English**

> Once unlocked, rooting is simple: **patch boot.img and flash it back to the boot partition**.
> `system` is untouched, OTA stays viable.

| Difficulty | Time | Risk | Prerequisite |
|---|---|---|---|
| ★★☆ | 20 min | Low (rolling back boot is easy) | [04](04-xperable-unlock.md) |

---

## 5.1 What you need

| File | Source |
|---|---|
| `boot.img` | your own backup, or extracted from a ROM zip / `kernel.sin` |
| `Magisk-v31.1.apk` | [DOWNLOADS](../../DOWNLOADS.en.md) §A6 |
| `boot_patch.sh` + magisk binaries | extracted from the same APK (§5.2) |

---

## 5.2 Extract the patch tools from the APK

```bash
cd "$KIT/tools"
mkdir -p magisk-patch && cd magisk-patch

unzip -j ../Magisk-v31.1.apk 'lib/arm64-v8a/*' 'assets/boot_patch.sh' 'assets/util_functions.sh'

mv libmagiskboot.so magiskboot 2>/dev/null || mv lib/arm64-v8a/libmagiskboot.so magiskboot
mv libmagiskinit.so magiskinit 2>/dev/null || mv lib/arm64-v8a/libmagiskinit.so magiskinit
mv libmagisk.so     magisk     2>/dev/null || mv lib/arm64-v8a/libmagisk.so magisk
mv libinit-ld.so    init-ld    2>/dev/null || mv lib/arm64-v8a/libinit-ld.so init-ld
chmod +x magiskboot magiskinit magisk init-ld
```

The directory should contain:
`boot_patch.sh  util_functions.sh  magiskboot  magiskinit  magisk  init-ld`

---

## 5.3 Obtain boot.img

**Stock 8.0**: your own `boot-current.img`, or extract from
`firmware/docomo-8.0/kernel.sin` (SIN = gzip + tar; inside is a boot image starting with `ANDROID!`).

**LineageOS**:

```bash
unzip lineage-*.zip boot.img
```

---

## 5.4 Patch

> `boot_patch.sh` is a bash script — use **Linux or WSL**.

```bash
cd "$KIT/tools/magisk-patch"
cp /path/to/boot.img .
sh boot_patch.sh boot.img
```

Success ends with:

```
Creating new image: [new-boot.img]
```

---

## 5.5 Flash

Enter fastboot (Vol UP + USB, blue LED):

```bash
$FB flash boot new-boot.img
$FB reboot
```

---

## 5.6 Install the app and verify

```bash
$ADB install -r "$KIT/tools/Magisk-v31.1.apk"
$ADB shell "magisk -v"        # e.g. 31.1
$ADB shell "pidof magiskd"    # non-empty
```

The Magisk home screen should show:

```
Magisk    Installed   31.1
Ramdisk   Yes
```

> **Since Magisk 31**: `adb shell su` is denied (`su: request rejected (2000)`).
> This is by design (the global superuser toggle was removed); **root inside apps works**.
> Need adb root? Use Magisk 26/27.

---

## 5.7 Re-rooting on LineageOS

Flashing a ROM overwrites boot, so redo it:

```bash
unzip lineage-*.zip boot.img
cd "$KIT/tools/magisk-patch" && cp /path/to/boot.img . && sh boot_patch.sh boot.img
$FB flash boot new-boot.img
```

Repeat after every OTA.

---

## 5.8 Troubleshooting

| Symptom | Fix |
|---|---|
| stuck at logo after flashing | boot does not match the system → flash back your original boot |
| Magisk says "not installed" | you flashed an unpatched image |
| `boot_patch.sh` cannot find magiskboot | the renaming in §5.2 went wrong |
| unbootable after patching | script/APK version mismatch (use binaries from the same APK) |

---

Previous ← [04 · xperable unlock](04-xperable-unlock.md) | Next → [06 · LineageOS](06-lineageos.md)
