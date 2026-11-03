# 02 · Flash Android 8.0 and the P114 Bootloader

[中文](../02-刷8.0与P114.md) | **English**

> **Why 8.0**: the ABL / LinuxLoader layout xperable depends on only exists in this firmware combination.
> **Why P114**: only the P114 bootloader's `LinuxLoader-p114.pe` can be patched.

| Difficulty | Time | Risk | Prerequisite |
|---|---|---|---|
| ★★☆ | 20–40 min | Medium (firmware flash, wipes data) | [01](01-preparation.md) |

---

## 2.1 Flash Android 8.0 (47.1.F.1.105)

Get the firmware per [DOWNLOADS](../../DOWNLOADS.en.md) §B1 and place it in `$KIT/firmware/docomo-8.0/`.

newflasher requires this layout:

```
docomo-8.0/
├─ boot/                 bootloader_*.sin + Lilac_Docomo_XBootConfig_MiscTA.ta
├─ partition/            partition-image-LUN*.sin
├─ system.sin  userdata.sin  vendor.sin  kernel.sin ...
├─ boot_delivery.xml
└─ partition_delivery.xml
```

### Procedure

1. Power off → hold **Vol DOWN** → plug USB → **green LED**
2. Run newflasher inside the firmware directory:

```bash
cd "$KIT/firmware/docomo-8.0"
"$KIT/tools/newflasher.x64"
```

### Four prompts — answer `n` to all

| # | Prompt | Answer | Why |
|---|---|---|---|
| 1 | need GordonGate flash driver? | `n` | driver installed separately |
| 2 | dump trim area (TA)? | `n` | **'y' triggers a buffer overflow crash** |
| 3 | flash bootloader/bluetooth/dsp/modem to both slots? | `n` | single-SIM; dual-slot is risky |
| 4 | flash persist partition? | `n` | **never flash persist** — loses the attestation key |

### Success

```
Device is put now out of flash mode.
Sent command: Sync

End. You can disconnect your device when you close newflasher.exe
```

Unplug, power on. First boot may take minutes.

---

## 2.2 Flash the P114 bootloader

Stock 8.0 ships an **O_82** (LA1.1) bootloader; we need **P114** (LA2.0).

Three ABL variants: `5ADA` / `5D31` / `C93B`.

**How to choose**: newflasher validates the boot delivery and prints the match, e.g.

```
Found bootdelivery match: COMMERCIAL_0005E0E1
```

The reference unit matched **C93B**.

> The three variants' ABL binaries are nearly identical apart from a 256-byte RSA
> signature at the end — but **the signature must match** or the bootloader rejects it.

### Assemble the newflasher directory

```bash
mkdir -p "$KIT/firmware/p114/boot"
cp "$KIT/firmware/p114/C93B/bootloader_X_Boot_MSM8998_LA2_0_P_114_X-FLASH-ALL-C93B.sin" \
   "$KIT/firmware/p114/boot/"
cp "$KIT/firmware/docomo-8.0/boot/Lilac_Docomo_XBootConfig_MiscTA.ta" \
   "$KIT/firmware/p114/boot/"
```

### Flash

1. Power off → Vol DOWN → USB (green LED)
2. Run newflasher in `$KIT/firmware/p114`
3. Answer `n` / `n` / `n`

Expected output:

```
Found boot_delivery.xml in boot folder.
- Boot delivery version: 1306-5035
- Verifying if boot delivery match with device...
Found bootdelivery match: COMMERCIAL_0005E0E1
TA file: Lilac_Docomo_XBootConfig_MiscTA.ta
Processing bootloader_X_Boot_MSM8998_LA2_0_P_114_X-FLASH-ALL-C93B.sin
...
flash:bootloader
OKAY.
```

### Verify

Enter fastboot (Vol UP + USB):

```bash
$KIT/tools/platform-tools/fastboot getvar version-bootloader
```

Must contain:

```
1306-5035_X_Boot_MSM8998_LA2.0_P_114
```

**Do not continue without `P_114`.**

---

## 2.3 Boot up and enable USB debugging

1. Boot normally, finish setup (Google account optional)
2. Settings → About phone → tap "Build number" 7 times
3. Developer options → enable **USB debugging**
4. Plug in, allow the authorisation prompt

```bash
$ADB devices     # should show "device"
```

---

## 2.4 Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `*** buffer overflow detected ***` | answered 'y' to TA dump | rerun, answer `n` |
| `getvar:max-download-size` timeout | flash session wedged | unplug/replug, re-enter flash mode |
| bootloader rejected | ABL variant signature mismatch | try 5ADA / 5D31 / C93B |
| stuck at Sony logo after flashing | incomplete partitions | flash 8.0 again |

---

Previous ← [01 · Preparation](01-preparation.md) | Next → [03 · Temp root and XFL](03-temp-root-and-xfl.md)
