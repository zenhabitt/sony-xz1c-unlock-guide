# Sony Xperia XZ1 Compact (SO-02K) · Bootloader 解锁 + Root 实录

![license](https://img.shields.io/badge/license-MIT-blue.svg)
![device](https://img.shields.io/badge/device-SO--02K%20%2F%20lilac-informational)
![status](https://img.shields.io/badge/verified-real%20device-success)
![rom](https://img.shields.io/badge/rom-LineageOS%2023.2-lightgrey)

> 一台 docomo 版 SO-02K 的完整解锁记录 —— **不需要索尼官方解锁码**，
> **不擦 TA/DRM**，最终拿到可刷 ROM、可装 Magisk 的解锁状态。
> 本文档由实机操作过程整理，命令、参数、报错原文均来自真实执行。

---

## 30 秒判断适不适用

| 问题 | 需要是 |
|---|---|
| 机型是 **Xperia XZ1 Compact SO-02K**（docomo 日版，代号 `lilac`）？ | ✅ 是 |
| 能接受**多次清除数据**？ | ✅ 能 |
| 有 **Windows/Linux 电脑 + 数据线**？ | ✅ 有 |
| 想要的是"解锁 + root"，不是"救砖"？ | ✅ 是 |

有一条不满足，这个仓库可能帮不上你。

---

## 它解决什么问题

docomo 版 SO-02K 拿不到解锁码，设置里也没有「OEM 解锁」开关：

```console
$ fastboot oem unlock
FAILCommand not allowed
```

原因不是你不会操作，而是**这条路被运营商封死了**。绕过去需要一条 exploit 链：

```
┌─────────────────────────────────────────────────────────────┐
│  原厂 Android 8.0 (47.1.F.1.105)                            │
│         │                                                   │
│         ├─► 刷入 P114 bootloader（Android 9 的 ABL）         │
│         │                                                   │
│         ├─► bindershell 拿临时 root（CVE-2019-2215）         │
│         │        └─► 把 XFL 分区换成 O77 blob（关键前提）     │
│         │                                                   │
│         ├─► xperable 内存补丁 Fastboot（CVE-2021-1931）      │
│         │        └─► oem unlock Y  ──►  解锁完成              │
│         │                                                   │
│         └─► Magisk 给 boot.img 打补丁 ──► Root               │
└─────────────────────────────────────────────────────────────┘
```

**最大好处**：`xperable` 只改内存和 boot，**不碰 TA 分区** ——
DRM 密钥、相机调校参数全部保留（官方解锁会擦掉）。

---

## 实测验证结果

| 项目 | 结果 |
|---|---|
| 解锁 | ✅ `unlocked: yes` / `flash.locked: 0` / `verifiedbootstate: orange` |
| Root | ✅ Magisk 31.1，`magiskd` 常驻 |
| DRM/TA | ✅ 未被擦除 |
| NFC | ✅ docomo CXD224x 正常识别（需 `libnfc-nci-cxd224x.conf`） |
| ROM | ✅ LineageOS 23.2（Android 16） |
| 可用参数 | `-s 0xf69880 -5` |

未验证的部分在对应文档里都标了「未验证」，不臆测。

---

## 仓库结构

```
sony-xz1c-unlock-guide/
├─ README.md            ← 本文件
├─ AI-GUIDE.md          ★ 给 AI/自动化的可执行状态机（Phase 0–6）
├─ DOWNLOADS.md         ★ 外部文件来源 + SHA256（仓库不含二进制）
├─ CHECKLIST.md         ★ 可打印的操作清单
├─ NOTICE.md            第三方归属与许可证
├─ LICENSE              MIT
├─ docs/
│   ├─ 01-准备.md               驱动 / 三种模式 / 备份
│   ├─ 02-刷8.0与P114.md        降级 + 换 bootloader
│   ├─ 03-临时root与XFL.md      bindershell + 写 O77
│   ├─ 04-xperable解锁.md       ★ 补丁 + 解锁
│   ├─ 05-Magisk-root.md        boot.img 打补丁
│   ├─ 06-刷LineageOS.md        第三方 ROM
│   ├─ 07-排错手册.md           ★ 15 条实测踩坑
│   └─ 08-回滚与还原.md         变砖分级与恢复
└─ scripts/
    ├─ check_prereqs.sh         工作区自检（会校验哈希）
    ├─ sweep_xperable.ps1       批量试 -s 值
    ├─ partinfo.sh              分区信息（需临时 root）
    ├─ dump_bl.sh               备份 bootloader 分区
    └─ xfl_info.py              解析 boot 镜像 / SIN
```

---

## 工作目录约定

仓库**不含固件和工具**，执行前准备好：

```
$KIT/                          ← 你自己建，例如 ~/sony-kit
├─ tools/
│   ├─ platform-tools/         adb / fastboot
│   ├─ xperable/               xperable + LinuxLoader-p114.pe
│   ├─ bindershell/            bindershell (arm64)
│   ├─ magisk-patch/           boot_patch.sh + 提取的二进制
│   ├─ Magisk-v31.1.apk
│   └─ newflasher.x64
├─ firmware/
│   ├─ docomo-8.0/             47.1.F.1.105 固件（newflasher 结构）
│   ├─ p114/                   P114 bootloader
│   └─ lineage/                LineageOS（可选）
└─ backup/                     你自己的分区备份
```

来源与校验值见 [DOWNLOADS.md](DOWNLOADS.md)。准备好后：

```bash
KIT=~/sony-kit bash scripts/check_prereqs.sh
```

全部 `OK` 再开始。

---

## 三种设备状态（最容易搞错）

| 状态 | 操作 | LED | 电脑看到 | 用于 |
|---|---|---|---|---|
| **Fastboot** | 关机 → 按住 **音量上** → 插 USB | **蓝** | `<serial> fastboot` | xperable、刷 boot/recovery |
| **Flash mode** | 关机 → 按住 **音量下** → 插 USB | **绿** | `SOMC Flash Device` | newflasher 刷固件 |
| 正常开机 | 按电源 | — | `<serial> device` | adb shell |

> 「关机」= 电源菜单选关机，等完全断电。不是熄屏。

---

## 三个必须记住的技术事实

**1. XFL 必须是 O77 blob**

```
文件: xfl-o77.mbn
长度: 13,153,250 字节
SHA256: c745a32721d68bb7499a0e929bd9bcfec307cb922d0c17c22f064a51e6e1a7c7
```

对不上 → xperable 永远输出 `test2 not hit`。这不是"版本太新"，是内容不对。

**2. `-s` 参数因机而异**

| 设备 | 可用值 |
|---|---|
| 本文档实机 | `0xf69880` |
| XDA 另一台 SO-02K | `0xf99880` |
| 官方默认 | `0xf3f880`（实机无效） |

内存随机化导致的，属正常现象。见 `docs/04` §4.5 的试值表。

**3. exploit 成功到解锁之间不能重启**

补丁只存在于内存。`patched successfully` 之后立刻 `oem unlock Y`，
中间不拔线、不重启、不跑别的命令。

---

## 怎么开始

**人类读者** → 从 [docs/01-准备.md](docs/01-准备.md) 顺序读到 08，配合 [CHECKLIST.md](CHECKLIST.md) 打勾。

**AI / 自动化执行者** → 直接读 [AI-GUIDE.md](AI-GUIDE.md)：
```
Phase 0 环境自检 → Phase 1 版本确认 → Phase 2 P114 →
Phase 3 临时root+XFL → Phase 4 解锁 → Phase 5 Magisk → Phase 6 (可选) LineageOS
```
每个 Phase 都有：前置校验命令、操作、成功判据、失败分支、STOP 条件。

**只想看踩坑** → [docs/07-排错手册.md](docs/07-排错手册.md)。

---

## 风险与免责

- 流程会**多次清除数据**，并修改 bootloader 相关状态
- 仅适用于**你自己拥有的**设备
- 实机验证过，但**不保证你的机器变体一致**（尤其 `-s` 值、ABL 变体）
- 作者不对设备损坏、数据丢失、保修失效负责

---

## 致谢

| 项目 | 作者 | 许可证 |
|---|---|---|
| [xperable](https://github.com/j4nn/xperable) | j4nn | GPL-3.0 |
| [renoshell](https://github.com/j4nn/renoshell) | j4nn | GPL-2.0 |
| [newflasher](https://github.com/munjeni/newflasher) | munjeni | MIT |
| [Magisk](https://github.com/topjohnwu/Magisk) | John Wu | GPL-3.0 |

流程最初参考 XDA 帖子（作者 Omrad），本仓库的文档基于实机过程重写，
与原帖出入处（如 TWRP 不可用、改用 Lineage recovery）已在正文标注。

---

## English

**TL;DR** — Relocking-free bootloader unlock for the docomo-only Sony Xperia XZ1 Compact
(SO-02K / `lilac`) **without an official unlock code**, via the `xperable` exploit chain:

```
Android 8.0.0 (47.1.F.1.105) → flash P114 bootloader → bindershell temp root
→ overwrite XFL with the O77 blob → xperable (CVE-2021-1931) patches fastboot in RAM
→ `oem unlock Y` → unlocked. TA/DRM preserved. Then Magisk-patch boot.img for root.
```

- **Critical**: `xfl-o77.mbn` must be exactly 13,153,250 bytes
  (`c745a32721d68bb7499a0e929bd9bcfec307cb922d0c17c22f064a51e6e1a7c7`).
- **Critical**: `xperable` needs `-s 0xf69880 -5` on the tested unit (`-s` varies per device).
- **Critical**: never reboot between `patched successfully` and `oem unlock Y`.

`AI-GUIDE.md` contains a verifiable phase-by-phase state machine (preconditions, commands,
success criteria, failure branches, stop conditions) intended for automated execution.
`DOWNLOADS.md` lists upstream sources and SHA256 hashes — **no firmware or binaries are
redistributed here**.
