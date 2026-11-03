# Sony Xperia XZ1 Compact (SO-02K) Bootloader 解锁 + Root 实录

> 适用机型：**Sony Xperia XZ1 Compact SO-02K（NTT docomo 日版，代号 lilac）**
> 本文档记录一台实机完整走通的流程，包含参数、报错、判据。
> 不含任何版权文件，全部通过 [DOWNLOADS.md](DOWNLOADS.md) 从上游获取。

---

## 这个仓库解决什么问题

docomo 版 SO-02K **拿不到官方解锁码**，系统里也没有「OEM 解锁」开关：

```
$ fastboot oem unlock
FAILCommand not allowed
```

本仓库记录的流程可以在**不需要索尼解锁码**的情况下解锁，且：

- **不擦 TA / DRM 分区**（相机优化、DRM 密钥都保留）
- 解锁后可刷第三方 ROM、装 Magisk

```
原厂 Android 8.0  ──►  刷入 P114 bootloader
        │
        ▼
  bindershell 临时 root（CVE-2019-2215）
        │
        ▼
  把 XFL 分区替换成 O77 版本（关键前提）
        │
        ▼
  xperable 内存补丁 Fastboot（CVE-2021-1931）
        │
        ▼
  oem unlock Y  ──►  Bootloader 已解锁
        │
        ▼
  Magisk 打补丁 boot.img  ──►  Root
```

---

## 仓库结构

```
sony-xz1c-unlock-guide/
├─ README.md          ← 本文件
├─ AI-GUIDE.md        ★ 给 AI / 自动化执行者：可逐步验证的状态机
├─ DOWNLOADS.md       ★ 所有外部文件的来源 + SHA256（仓库不含二进制）
├─ NOTICE.md          第三方归属与许可证
├─ LICENSE            MIT
├─ docs/
│   ├─ 01-准备.md               驱动、两种模式、备份清单
│   ├─ 02-刷8.0与P114.md        降级 + 换 bootloader
│   ├─ 03-临时root与XFL.md      bindershell + 写 O77 XFL
│   ├─ 04-xperable解锁.md       ★ 核心：补丁 + 解锁
│   ├─ 05-Magisk-root.md        boot.img 打补丁
│   ├─ 06-刷LineageOS.md        第三方 ROM（可选）
│   ├─ 07-排错手册.md           ★ 15 条实测踩坑
│   └─ 08-回滚与还原.md         变砖分级与恢复
└─ scripts/
    ├─ check_prereqs.sh         环境自检
    ├─ partinfo.sh              列出分区信息（需临时 root）
    ├─ dump_bl.sh               dump bootloader 分区
    ├─ xfl_info.py              解析 boot 镜像
    └─ sweep_xperable.ps1       批量试 -s 值
```

---

## 工作目录约定

仓库本身**不含固件和工具**。执行前在工作区准备好这些：

```
$KIT/                          ← 你自己建的目录，例如 ~/sony-kit
├─ tools/
│   ├─ platform-tools/         adb / fastboot
│   ├─ xperable/               xperable + LinuxLoader-p114.pe
│   ├─ bindershell/            bindershell（arm64）
│   ├─ Magisk-v31.1.apk
│   ├─ newflasher.x64
│   └─ zadig.exe               （仅 Windows）
├─ firmware/
│   ├─ docomo-8.0/             SO-02K 47.1.F.1.105 固件（newflasher 目录结构）
│   ├─ p114/                   P114 bootloader 包
│   └─ lineage/                LineageOS zip + recovery
└─ backup/                     放你自己的分区备份
```

具体来源与校验值见 [DOWNLOADS.md](DOWNLOADS.md)。

---

## 两种模式（最容易搞错的地方）

| 模式 | 操作 | LED | 设备名 | 用于 |
|---|---|---|---|---|
| **Fastboot** | 关机 → 按住 **音量上** → 插 USB | **蓝** | `xxx fastboot` | xperable、刷 boot/recovery |
| **Flash mode** | 关机 → 按住 **音量下** → 插 USB | **绿** | `SOMC Flash Device` | newflasher 刷固件 |
| 正常 | 直接开机 | — | `xxx device`（adb） | adb shell |

「关机」= 电源键菜单里选关机并等完全断电。

---

## 三个必须记住的技术事实

1. **XFL 必须是 O77 的 blob**
   `xfl-o77.mbn` 长度 `13,153,250` 字节，SHA256
   `c745a32721d68bb7499a0e929bd9bcfec307cb922d0c17c22f064a51e6e1a7c7`。
   对不上 → xperable 永远输出 `test2 not hit`。

2. **xperable 的 `-s` 参数因机而异**
   本机可用：`-s 0xf69880 -5`
   官方默认 `0xf3f880` 无效；另一台 SO-02K 用 `0xf99880`。
   原因是内存随机化，属正常现象。

3. **exploit 成功到 `oem unlock Y` 之间不能重启/拔线**
   补丁只存在于内存，重启即失效。

---

## 怎么开始

- **人类读者**：`docs/01` → `docs/08` 顺序读，边读边做。
- **AI / 自动化执行者**：直接读 [AI-GUIDE.md](AI-GUIDE.md)，
  里面每一步都有「前置校验 → 操作 → 成功判据 → 失败分支」。

---

## 风险与免责

- 本流程会**多次清除数据**，且会修改 bootloader 相关状态。
- 仅适用于**你自己拥有的** SO-02K。
- 按文档操作在实机上验证过，但**不保证你的设备变体完全一致**（尤其 `-s` 值）。
- 作者不对设备损坏、数据丢失、保修失效负责。

---

## 来源与致谢

| 项目 | 作者 | 许可证 |
|---|---|---|
| [xperable](https://github.com/j4nn/xperable) | j4nn | GPL-3.0 |
| [renoshell（bindershell）](https://github.com/j4nn/renoshell) | j4nn | GPL-2.0 |
| [newflasher](https://github.com/munjeni/newflasher) | munjeni | MIT |
| [Magisk](https://github.com/topjohnwu/Magisk) | John Wu | GPL-3.0 |

流程最初参考 XDA 帖子（作者 Omrad），本仓库的文档是**基于实机过程重写**的，
命令、参数、报错现象均来自实机验证，与原作者描述有出入处已在文档中注明。
