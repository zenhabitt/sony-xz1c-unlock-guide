# DOWNLOADS · sources and checksums

[中文](DOWNLOADS.md) | **English**

> This repository contains **no binaries, no firmware and no copyrighted images**.
> The table below lists every external file: what it is for, where to get it, its size and
> SHA256. Verify after downloading — **do not use a file that fails the check**.

---

## A. Required (phases P0–P5)

### A1. Android Platform Tools (adb / fastboot)

| Field | Value |
|---|---|
| Source | <https://developer.android.com/studio/releases/platform-tools> |
| Extract to | `$KIT/tools/platform-tools/` |
| Needed | `adb`, `fastboot` (Windows also `AdbWinApi.dll`, `AdbWinUsbApi.dll`) |
| Checksum | version-dependent; `adb version` working is enough |

### A2. Zadig (Windows only, for the fastboot driver)

| Field | Value |
|---|---|
| Source | <https://zadig.akeo.ie/> |
| Place at | `$KIT/tools/zadig.exe` |
| Size | 5,334,088 |
| SHA256 | `4ecaa95df3da3621486a043aef8b3050b8bafe7c901402871e816229ef82039b` |

### A3. newflasher (flashing stock firmware)

| Field | Value |
|---|---|
| Source | <https://github.com/munjeni/newflasher> (MIT) |
| Place at | `$KIT/tools/newflasher.x64` |
| Size | 1,106,920 |
| SHA256 | `5f293b90e0e676ae253392585165c0d69f98ec3e236af12e7cdc5a59eaf68068` |

> Upstream releases change; a hash mismatch is not necessarily a problem,
> just make sure the source is trustworthy.

### A4. xperable (the unlock tool)

| Field | Value |
|---|---|
| Source | <https://github.com/j4nn/xperable> (GPL-3.0) |
| Place at | `$KIT/tools/xperable/` |
| Needed | `xperable` / `xperable.exe` + `LinuxLoader-p114.pe` |

| File | Size | SHA256 |
|---|---|---|
| `xperable.exe` | 3,090,670 | `6d332b1c82470afeb9a2379db026ac151f3c60c0090cee13edb2c6836ebf4932` |
| `LinuxLoader-p114.pe` | 1,052,672 | `e8919094432714805980fd113806faaa65648dc9fabd7ae5912540579ef1e51b` |

> `LinuxLoader-p114.pe` is extracted from the device ABL and **may differ between
> ABL variants**. Use the one matching your variant (C93B / 5ADA / 5D31).

### A5. bindershell (temporary root)

| Field | Value |
|---|---|
| Source | <https://github.com/j4nn/renoshell> (branch `CVE-2019-2215`, GPL-2.0) |
| Place at | `$KIT/tools/bindershell/bindershell` |
| Size | 19,648 (arm64) |
| SHA256 | `d528b0888dc920937c91cf879f38bda31b3775a407c50c676111cb31e85adb41` |

> You may need to build it yourself with the NDK. Note: `jni/Android.mk` needs `-fcommon`,
> otherwise you get duplicate-symbol errors for `policydb` / `sidtab`.

### A6. Magisk

| Field | Value |
|---|---|
| Source | <https://github.com/topjohnwu/Magisk/releases> (GPL-3.0) |
| Place at | `$KIT/tools/Magisk-v31.1.apk` |
| Size | 10,679,283 |
| SHA256 | `89cefac0a318afa39fb3880c45c87b036c05bc1ebf02a7a715b7f8d7c26ac6e7` |

**Extract the patch tools from the APK** into `tools/magisk-patch/`:

```bash
unzip -j Magisk-v31.1.apk 'lib/arm64-v8a/libmagiskboot.so' -d mp
unzip -j Magisk-v31.1.apk 'lib/arm64-v8a/libmagiskinit.so' -d mp
unzip -j Magisk-v31.1.apk 'lib/arm64-v8a/libmagisk.so'    -d mp
unzip -j Magisk-v31.1.apk 'lib/arm64-v8a/libinit-ld.so'   -d mp
unzip -j Magisk-v31.1.apk 'assets/boot_patch.sh'          -d mp
unzip -j Magisk-v31.1.apk 'assets/util_functions.sh'      -d mp

cd mp
mv libmagiskboot.so magiskboot
mv libmagiskinit.so magiskinit
mv libmagisk.so magisk
mv libinit-ld.so init-ld
chmod +x magiskboot magiskinit magisk init-ld
```

Result in `$KIT/tools/magisk-patch/`:
`boot_patch.sh`, `util_functions.sh`, `magiskboot`, `magiskinit`, `magisk`, `init-ld`

---

## B. Firmware and system images (copyrighted — obtain yourself)

> ⚠️ The items below are Sony / docomo copyrighted material.
> This repository **does not host or mirror them**. Obtain them from official or
> community-recognised sources and take responsibility for compliance.

### B1. SO-02K Android 8.0 firmware (47.1.F.1.105)

| Field | Value |
|---|---|
| Purpose | downgrade to 8.0 (exploit precondition) |
| Reference source | firmware links inside the XDA thread |
| Place at | `$KIT/firmware/docomo-8.0/` (newflasher layout) |
| Key file | `system.sin` |

| File | Size | SHA256 |
|---|---|---|
| `system.sin` | as downloaded | `30932350dcaadf6598486dbb719fd383c9b51f0e9bb616f9c4b5688d44d15e75` |

**Required layout** (what newflasher expects):

```
docomo-8.0/
├─ boot/                 bootloader_*.sin + Lilac_Docomo_XBootConfig_MiscTA.ta
├─ partition/            partition-image-LUN*.sin
├─ *.sin                 system / userdata / vendor / kernel ...
├─ boot_delivery.xml
└─ partition_delivery.xml
```

### B2. P114 bootloader package

| Field | Value |
|---|---|
| Purpose | switch to a patchable bootloader |
| Reference source | bootloader package inside the XDA thread |
| Place at | `$KIT/firmware/p114/` |

Reference unit matched **C93B**:

| File | Size | SHA256 |
|---|---|---|
| `bootloader_X_Boot_MSM8998_LA2_0_P_114_X-FLASH-ALL-C93B.sin` | 16,527,033 | `5592cdf29ea63b1226cb071e6dcf699163c677acc506b001efd1af16b8525e81` |

Two other variants exist (`5ADA`, `5D31`). Choose by the bootdelivery the device reports
(see docs/en/02 §2.2).

### B3. xfl-o77.mbn (the critical blob)

| Field | Value |
|---|---|
| Purpose | written into the XFL partition so the exploit can land |
| Source | included in the XDA thread's `4.bindershell` package |
| Place at | `$KIT/tools/xfl-o77.mbn` |
| Size | **13,153,250** |
| SHA256 | **`c745a32721d68bb7499a0e929bd9bcfec307cb922d0c17c22f064a51e6e1a7c7`** |

> This is the single most important checksum in the whole flow.
> Wrong length or hash → xperable will always fail.

### B4. LineageOS (optional, phase P6 only)

| Field | Value |
|---|---|
| Official | <https://download.lineageos.org/devices/lilac> |
| Note | official builds may **lack docomo CXD224x NFC support**; use an `nfc` variant if you need NFC |
| Place at | `$KIT/firmware/lineage/` |

Reference build used here (for comparison):

| File | Size | SHA256 |
|---|---|---|
| `lineage-23.2-20260817-nfc-UNOFFICIAL-lilac.zip` | 1,124,965,580 | `771676ab7b54f4c3d153264cd3b74f7157cd289621f1b006c1b384009d21ac57` |
| `lineage-23.2-20260817-nfc-recovery-lilac.img` | 30,879,744 | `549785535112f614464d33d525c6284f8fc5cafbb2e0ba69b675e4a495428866` |

---

## C. Verifying

**Windows**

```powershell
Get-FileHash .\tools\xfl-o77.mbn -Algorithm SHA256
```

**Linux / macOS**

```bash
sha256sum tools/xfl-o77.mbn
```

**Batch check**

```bash
bash scripts/check_prereqs.sh
```

---

## D. Why it is distributed this way

1. **Firmware is copyrighted** — mirroring Sony/operator firmware is not appropriate;
   linking is.
2. **GPL tools require source availability** — linking upstream satisfies this,
   redistributing binaries without source does not.
3. **Upstream updates** — links always resolve to a current, supported version.

---

## E. Not included (build or fetch yourself)

| Item | Note |
|---|---|
| Partition backups | your own `xfl-current.img` / `abl-current.img` / `boot.img` |
| Patched boot image | make it with `boot_patch.sh` |
| ABL extraction tooling | `LinuxLoader-p114.pe` comes from the upstream package |
