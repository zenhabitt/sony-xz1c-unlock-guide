# DOWNLOADS · 外部文件来源与校验

> 本仓库**不包含任何二进制、固件或版权文件**。
> 下表列出每个文件的作用、从哪拿、多大、SHA256 是多少。
> 下载后请务必校验，**校验不通过不要用**。

---

## A. 必需文件（P0–P5 需要）

### A1. Android Platform Tools（adb / fastboot）

| 项 | 值 |
|---|---|
| 来源 | <https://developer.android.com/studio/releases/platform-tools> |
| 解压到 | `$KIT/tools/platform-tools/` |
| 需要 | `adb`、`fastboot`（Windows 另需 `AdbWinApi.dll`、`AdbWinUsbApi.dll`） |
| 校验 | 版本随上游更新，无固定值；能跑 `adb version` 即可 |

### A2. Zadig（仅 Windows，装 fastboot 驱动）

| 项 | 值 |
|---|---|
| 来源 | <https://zadig.akeo.ie/> |
| 放到 | `$KIT/tools/zadig.exe` |
| 大小 | 5,334,088 |
| SHA256 | `4ecaa95df3da3621486a043aef8b3050b8bafe7c901402871e816229ef82039b` |

### A3. newflasher（刷原厂固件）

| 项 | 值 |
|---|---|
| 来源 | <https://github.com/munjeni/newflasher>（MIT） |
| 放到 | `$KIT/tools/newflasher.x64` |
| 大小 | 1,106,920 |
| SHA256 | `5f293b90e0e676ae253392585165c0d69f98ec3e236af12e7cdc5a59eaf68068` |

> 上游版本会变，哈希对不上不一定是坏事；确认来源可信即可。

### A4. xperable（解锁核心工具）

| 项 | 值 |
|---|---|
| 来源 | <https://github.com/j4nn/xperable>（GPL-3.0） |
| 放到 | `$KIT/tools/xperable/` |
| 需要 | `xperable`（或 `xperable.exe`）+ `LinuxLoader-p114.pe` |

| 文件 | 大小 | SHA256 |
|---|---|---|
| `xperable.exe` | 3,090,670 | `6d332b1c82470afeb9a2379db026ac151f3c60c0090cee13edb2c6836ebf4932` |
| `LinuxLoader-p114.pe` | 1,052,672 | `e8919094432714805980fd113806faaa65648dc9fabd7ae5912540579ef1e51b` |

> `LinuxLoader-p114.pe` 是从设备 ABL 里提取的，**不同 ABL 变体可能不同**。
> 用你设备匹配的 ABL 变体（C93B / 5ADA / 5D31）对应的那份。

### A5. bindershell（临时 root）

| 项 | 值 |
|---|---|
| 来源 | <https://github.com/j4nn/renoshell>（分支 `CVE-2019-2215`，GPL-2.0） |
| 放到 | `$KIT/tools/bindershell/bindershell` |
| 大小 | 19,648（arm64） |
| SHA256 | `d528b0888dc920937c91cf879f38bda31b3775a407c50c676111cb31e85adb41` |

> 上游可能需要自己编译（NDK）。编译注意：`jni/Android.mk` 要加 `-fcommon`，
> 否则会出现 `policydb`/`sidtab` 重复符号错误。

### A6. Magisk

| 项 | 值 |
|---|---|
| 来源 | <https://github.com/topjohnwu/Magisk/releases>（GPL-3.0） |
| 放到 | `$KIT/tools/Magisk-v31.1.apk` |
| 大小 | 10,679,283 |
| SHA256 | `89cefac0a318afa39fb3880c45c87b036c05bc1ebf02a7a715b7f8d7c26ac6e7` |

**还需要从 APK 里提取补丁工具**（`tools/magisk-patch/`）：

```bash
# 从 APK 提取（arm64）
unzip -j Magisk-v31.1.apk 'lib/arm64-v8a/libmagiskboot.so' -d mp
unzip -j Magisk-v31.1.apk 'lib/arm64-v8a/libmagiskinit.so' -d mp
unzip -j Magisk-v31.1.apk 'lib/arm64-v8a/libmagisk.so'    -d mp
unzip -j Magisk-v31.1.apk 'lib/arm64-v8a/libinit-ld.so'   -d mp
unzip -j Magisk-v31.1.apk 'assets/boot_patch.sh'          -d mp
unzip -j Magisk-v31.1.apk 'assets/util_functions.sh'      -d mp

# 重命名成 boot_patch.sh 期望的名字
cd mp
mv libmagiskboot.so magiskboot
mv libmagiskinit.so magiskinit
mv libmagisk.so magisk
mv libinit-ld.so init-ld
chmod +x magiskboot magiskinit magisk init-ld
```

最终 `$KIT/tools/magisk-patch/` 里应有：
`boot_patch.sh`、`util_functions.sh`、`magiskboot`、`magiskinit`、`magisk`、`init-ld`

---

## B. 固件与系统镜像（版权内容，请自行获取）

> ⚠️ 以下均为 Sony / docomo 版权内容。本仓库**不提供下载**，也不镜像。
> 请从官方或社区认可的渠道获取，并自行承担合规责任。

### B1. SO-02K Android 8.0 固件（47.1.F.1.105）

| 项 | 值 |
|---|---|
| 用途 | 降级到 8.0（exploit 前提） |
| 参考来源 | XDA 帖子内提供的固件链接 |
| 放到 | `$KIT/firmware/docomo-8.0/`（newflasher 目录结构） |
| 关键文件 | `system.sin` |

| 文件 | 大小 | SHA256 |
|---|---|---|
| `system.sin` | 见你自己下载的包 | `30932350dcaadf6598486dbb719fd383c9b51f0e9bb616f9c4b5688d44d15e75` |

**目录要求**（newflasher 能识别的结构）：

```
docomo-8.0/
├─ boot/                 ← 含 bootloader_*.sin + Lilac_Docomo_XBootConfig_MiscTA.ta
├─ partition/            ← 含 partition-image-LUN*.sin
├─ *.sin                 ← system / userdata / vendor / kernel …
├─ boot_delivery.xml
└─ partition_delivery.xml
```

### B2. P114 Bootloader 包

| 项 | 值 |
|---|---|
| 用途 | 换成可被 patch 的 bootloader |
| 参考来源 | XDA 帖子内提供的 bootloader 包 |
| 放到 | `$KIT/firmware/p114/` |

本机匹配变体 **C93B**：

| 文件 | 大小 | SHA256 |
|---|---|---|
| `bootloader_X_Boot_MSM8998_LA2_0_P_114_X-FLASH-ALL-C93B.sin` | 16,527,033 | `5592cdf29ea63b1226cb071e6dcf699163c677acc506b001efd1af16b8525e81` |

另有两个变体 `5ADA`、`5D31`，**按设备报的 bootdelivery 选择**（见 docs/02 §2.2）。

### B3. xfl-o77.mbn（关键 blob）

| 项 | 值 |
|---|---|
| 用途 | 写进 XFL 分区，让 exploit 能命中 |
| 来源 | 包含在 XDA 帖子的 `4.bindershell` 资源里 |
| 放到 | `$KIT/tools/xfl-o77.mbn` |
| 大小 | **13,153,250** |
| SHA256 | **`c745a32721d68bb7499a0e929bd9bcfec307cb922d0c17c22f064a51e6e1a7c7`** |

> 这是整个流程里**最重要的校验值**。长度或哈希不对，xperable 一定失败。

### B4. LineageOS（可选，P6 才需要）

| 项 | 值 |
|---|---|
| 官方 | <https://download.lineageos.org/devices/lilac> |
| 注意 | 官方构建**可能不含 docomo 的 CXD224x NFC 支持**；需要 NFC 请用带 `nfc` 的变体 |
| 放到 | `$KIT/firmware/lineage/` |

本机使用的版本（用于对照）：

| 文件 | 大小 | SHA256 |
|---|---|---|
| `lineage-23.2-20260817-nfc-UNOFFICIAL-lilac.zip` | 1,124,965,580 | `771676ab7b54f4c3d153264cd3b74f7157cd289621f1b006c1b384009d21ac57` |
| `lineage-23.2-20260817-nfc-recovery-lilac.img` | 30,879,744 | `549785535112f614464d33d525c6284f8fc5cafbb2e0ba69b675e4a495428866` |

---

## C. 校验方法

**Windows**

```powershell
Get-FileHash .\tools\xfl-o77.mbn -Algorithm SHA256
```

**Linux / macOS**

```bash
sha256sum tools/xfl-o77.mbn
```

**批量校验**

```bash
bash scripts/check_prereqs.sh        # 会检查必需文件是否存在并比对已知哈希
```

---

## D. 为什么要这样分发

1. **固件是版权内容**：索尼/运营商的固件不能随意镜像分发，仓库里放链接是合规做法。
2. **GPL 工具需要配套源码**：直接传二进制而不提供源码不符合 GPL 要求，
   链接到上游仓库则天然满足。
3. **版本更新**：上游工具会更新，链接始终指向最新有效版本。

---

## E. 本仓库不含的项目（自己造或找上游）

| 项目 | 说明 |
|---|---|
| 分区备份 | 你自己 `dd` 出来的 `xfl-current.img` / `abl-current.img` / `boot.img` |
| 已打补丁的 boot | 用 `boot_patch.sh` 现做，或用你自己的备份 |
| ABL 提取工具 | `LinuxLoader-p114.pe` 来自上游包 |
