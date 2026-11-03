# NOTICE · 第三方归属与许可证

**中文** | [English](#english-version)

本仓库**只包含文档和脚本**（原创内容），不包含下列项目的二进制或源码。
下面是流程中用到的上游项目及其许可证，使用时请遵守各自条款。

---

## 上游工具

### xperable

- 作者：j4nn
- 仓库：<https://github.com/j4nn/xperable>
- 许可证：**GNU General Public License v3.0**
- 用途：利用 CVE-2021-1931 在内存中 patch Xperia ABL 的 Fastboot，使其接受 `oem unlock`
- 本仓库不包含其二进制或源码，仅在文档中描述调用方式

### renoshell / bindershell

- 作者：j4nn
- 仓库：<https://github.com/j4nn/renoshell>（分支 `CVE-2019-2215`）
- 许可证：**GNU General Public License v2.0**
- 用途：利用 CVE-2019-2215 获取临时 root shell
- 本仓库不包含其二进制或源码

### newflasher

- 作者：munjeni
- 仓库：<https://github.com/munjeni/newflasher>
- 许可证：**MIT License**
- 用途：在 Flash mode 下刷写 Sony 固件（`.sin`）

### Magisk

- 作者：John Wu（topjohnwu）
- 仓库：<https://github.com/topjohnwu/Magisk>
- 许可证：**GNU General Public License v3.0**
- 用途：boot 镜像补丁式 root
- 本仓库不包含 APK；从上游 Releases 下载

### Android Platform Tools

- 提供方：Google
- 来源：<https://developer.android.com/studio/releases/platform-tools>
- 许可证：Android SDK 条款
- 用途：`adb` / `fastboot`

### Zadig

- 来源：<https://zadig.akeo.ie/>
- 许可证：GPL（libwdi）
- 用途：Windows 下为 fastboot 安装 WinUSB 驱动

---

## 固件与系统镜像

以下内容**版权归 Sony / NTT docomo / 各自权利人所有**，本仓库不提供、不镜像：

- Xperia XZ1 Compact (SO-02K) 原厂固件（Android 8.0 / 47.1.F.1.105）
- P114 bootloader 包（`bootloader_*.sin`、`*.mbn`）
- `xfl-o77.mbn`（Xperia Flash Loader 片段）
- 从设备 dump 出的任何分区镜像（`xfl`、`abl`、`boot` 等）
- LineageOS 构建产物（含厂商闭源 blobs）

获取与使用请遵守相应权利人的条款。本仓库仅提供**校验值**用于确认文件完整性。

---

## 参考资料

- XDA 讨论帖：《Unlocking the Bootloader on Sony Xperia XZ1 Compact SO-02K (Docomo) Without an Official Sony Unlock Code (Xperable)》
  <https://xdaforums.com/t/unlocking-the-bootloader-on-sony-xperia-xz1-compact-so-02k-docomo-without-an-official-sony-unlock-code-xperable.4794149/>
- CVE-2021-1931（xperable 利用的漏洞）
- CVE-2019-2215（bindershell 利用的漏洞）

本仓库的文档是根据**一台实机的实际操作过程重写**的，不是对上文的翻译或复制。
与原文有出入的地方（例如本机 TWRP 不可用、改用 Lineage recovery）已在正文标注。

---

## 本仓库自身

- 文档与脚本：MIT（见 [LICENSE](LICENSE)）
- 引用上游项目时已注明作者与许可证

---

## English version

**This repository contains documentation and scripts only.** It does **not** bundle,
mirror, or redistribute any binary, source archive, firmware image, or other copyrighted
material from the projects below.

### Upstream tools

| Project | Author | License | Purpose |
|---|---|---|---|
| [xperable](https://github.com/j4nn/xperable) | j4nn | GPL-3.0 | CVE-2021-1931: patches Xperia ABL fastboot in memory so `oem unlock` is accepted |
| [renoshell](https://github.com/j4nn/renoshell) (branch `CVE-2019-2215`) | j4nn | GPL-2.0 | CVE-2019-2215: temporary root shell |
| [newflasher](https://github.com/munjeni/newflasher) | munjeni | MIT | flashes Sony firmware (`.sin`) in flash mode |
| [Magisk](https://github.com/topjohnwu/Magisk) | John Wu | GPL-3.0 | boot-image patch based root |
| [Android Platform Tools](https://developer.android.com/studio/releases/platform-tools) | Google | Android SDK terms | `adb`, `fastboot` |
| [Zadig](https://zadig.akeo.ie/) | — | GPL (libwdi) | installs WinUSB for fastboot on Windows |

### Firmware and system images

Copyright belongs to Sony / NTT docomo / their respective owners. **Not provided or mirrored
by this repository:**

- Xperia XZ1 Compact (SO-02K) stock firmware (Android 8.0 / 47.1.F.1.105)
- P114 bootloader package (`bootloader_*.sin`, `*.mbn`)
- `xfl-o77.mbn` (Xperia Flash Loader blob)
- any partition dump taken from a device (`xfl`, `abl`, `boot`, …)
- LineageOS build artifacts (they contain proprietary vendor blobs)

This repository only publishes **checksums** so you can confirm file integrity.

### References

- XDA thread: "Unlocking the Bootloader on Sony Xperia XZ1 Compact SO-02K (Docomo) Without
  an Official Sony Unlock Code (Xperable)" —
  <https://xdaforums.com/t/unlocking-the-bootloader-on-sony-xperia-xz1-compact-so-02k-docomo-without-an-official-sony-unlock-code-xperable.4794149/>
- CVE-2021-1931 (used by xperable)
- CVE-2019-2215 (used by bindershell)

The documents here were rewritten from an actual device run; they are not a translation or
copy of the material above. Differences from the original post (e.g. TWRP being unusable on
this unit, Lineage recovery used instead) are noted inline.

### This repository

- Documentation and scripts: MIT (see [LICENSE](LICENSE))
