# AI-GUIDE · 可执行状态机

> 这份文件是给 **AI agent / 自动化脚本** 用的。
> 每一步都有：前置校验 → 操作 → 成功判据 → 失败分支。
> 严格按顺序执行，**任何一步判据不满足就不要进入下一步**。

---

## 0. 执行规则（先读）

```
R1  每次状态转换前先跑"前置校验"，不要假设上一步成功了。
R2  涉及 fastboot 的操作前，确认 `fastboot devices` 有输出。
R3  涉及 flash mode 的操作前，确认设备管理器出现 SOMC Flash Device。
R4  exploit 成功（P4.2）到 oem unlock Y（P4.3）之间：
    禁止重启、禁止拔线、禁止执行其他 fastboot 命令。
R5  任何 SHA256 校验不通过 → 回到对应的"写入"步骤，不要往下走。
R6  出现 STOP 条件（见 §8）→ 立即停止并报告，不要尝试"修一下"。
R7  每完成一个 Phase，记录：phase id、关键输出、时间戳。
```

工作目录变量：

```bash
KIT=${KIT:-$HOME/sony-kit}     # 或 C:\sony-kit
ADB="$KIT/tools/platform-tools/adb"
FB="$KIT/tools/platform-tools/fastboot"
```

---

## Phase 0 · 环境自检

**目标**：确认工具链可用、设备可识别。

```bash
bash scripts/check_prereqs.sh        # 检查 adb/fastboot/文件齐全
$ADB devices                          # → 期望: <serial>  device
```

**成功判据**
- `adb devices` 至少一行以 `device` 结尾
- `$KIT/tools/platform-tools/fastboot` 可执行
- `DOWNLOADS.md` 里 P1-P4 必需的文件都存在且 SHA256 匹配

**失败分支**

| 现象 | 动作 |
|---|---|
| `unauthorized` | 让用户在手机上点「允许 USB 调试」 |
| 无输出 | 检查驱动（见 docs/01） |
| 文件缺失/校验失败 | 重新下载，见 DOWNLOADS.md |

---

## Phase 1 · 确认系统版本（必要时降级）

**目标**：系统必须是 **Android 8.0 / 47.1.F.1.105**。

```bash
$ADB shell getprop ro.build.version.release    # 期望: 8.0.0
$ADB shell getprop ro.build.id                 # 期望: 47.1.F.1.105
$ADB shell getprop ro.product.device           # 期望: lilac
```

**成功判据**：三个值都匹配。

**失败分支**：版本不是 8.0 → 执行 `docs/02-刷8.0与P114.md` §2.1
（newflasher，四个提示全部答 `n`），完成后回到本 Phase 重新校验。

---

## Phase 2 · 刷入 P114 bootloader

**目标**：`version-bootloader` 包含 `P_114`。

```bash
# 1) 手机关机 → 按住音量上 → 插 USB（蓝灯）
$FB devices                                  # 期望: <serial>  fastboot
$FB getvar version-bootloader
```

若已是 `...LA2.0_P_114` → **跳过本 Phase**。

否则：

```bash
# 进入 flash mode：关机 → 按住音量下 → 插 USB（绿灯）
cd "$KIT/firmware/p114"
"$KIT/tools/newflasher.x64"          # 提示全部答 n
# 完成后开机，再进 fastboot 复查
$FB getvar version-bootloader
```

**成功判据**：输出包含 `1306-5035_X_Boot_MSM8998_LA2.0_P_114`。

**失败分支**

| 现象 | 动作 |
|---|---|
| bootloader 被拒 / delivery mismatch | 换 ABL 变体（5ADA / 5D31 / C93B），见 docs/02 §2.2 |
| newflasher 找不到设备 | 驱动没装（docs/01 §1.1C） |

---

## Phase 3 · 临时 root + 写入 O77 XFL

**目标**：XFL 分区前 13,153,250 字节 = O77 blob。

### 3.1 拿临时 root

```bash
$ADB push "$KIT/tools/bindershell/bindershell" /data/local/tmp/
$ADB shell "cd /data/local/tmp && chmod 755 ./bindershell && ./bindershell"
```

**成功判据**：出现 `got root, start shell...` 且提示符为 `#`。

### 3.2 备份原始分区（必做）

```sh
dd if=/dev/block/bootdevice/by-name/xfl of=/sdcard/xfl-current.img
dd if=/dev/block/bootdevice/by-name/abl of=/sdcard/abl-current.img
```
```bash
$ADB pull /sdcard/xfl-current.img "$KIT/backup/"
$ADB pull /sdcard/abl-current.img "$KIT/backup/"
```

**成功判据**：`xfl-current.img` 为 `31,457,280` 字节。

### 3.3 写入并校验

```bash
$ADB push "$KIT/tools/xfl-o77.mbn" /sdcard/
```
```sh
# 在 root shell 内
dd if=/sdcard/xfl-o77.mbn of=/dev/block/bootdevice/by-name/xfl
sync
dd if=/dev/block/bootdevice/by-name/xfl of=/sdcard/xfl_head.bin bs=1024 count=12845
sha256sum /sdcard/xfl-o77.mbn /sdcard/xfl_head.bin
```

**成功判据**：两个 SHA256 都是
`c745a32721d68bb7499a0e929bd9bcfec307cb922d0c17c22f064a51e6e1a7c7`

**失败分支**

| 现象 | 动作 |
|---|---|
| 提示符还是 `$` | bindershell 没提权成功，重跑 3.1 |
| 校验不一致 | 重新 push + dd；不要用 `cp` |
| `Permission denied` | 不在 root shell |

---

## Phase 4 · xperable 补丁 + 解锁

**目标**：`unlocked: yes`。

### 4.1 进入 Fastboot

手机关机 → 按住音量上 → 插 USB（蓝灯）。

```bash
$FB devices
```

**成功判据**：有 `fastboot` 设备。

### 4.2 打内存补丁

```bash
cd "$KIT/tools/xperable"
./xperable.exe -v -V -B -U -s 0xf69880 -5      # Windows
# 或 ./xperable -v -V -B -U -s 0xf69880 -5     # Linux
```

**成功判据**（两行都要出现）：

```
[+] Got LinuxLoader base addr 0x........
[+] LinuxLoader @ 0x........ patched successfully
```

**失败分支**：见 §7 的 `-s` 试值表。**不要**在失败后继续执行 4.3。

### 4.3 立即解锁（中间不要做任何其他事）

```bash
./xperable.exe -v -V -c "oem unlock Y" -1
```

**成功判据**：出现 `{...<-00000004:OK} "OKAY"`。

### 4.4 重启

```bash
./xperable.exe -v -V -c reboot -1
```

### 4.5 验证

```bash
# 开机后重新进 fastboot
$FB getvar unlocked          # 期望: unlocked: yes
$ADB shell getprop ro.boot.verifiedbootstate   # 期望: orange
$ADB shell getprop ro.boot.flash.locked        # 期望: 0
```

**失败分支**

| 现象 | 动作 |
|---|---|
| `unlocked: no` | 解锁未生效，回 4.2 重来（注意可能需重新进 fastboot） |
| 开机循环 / 卡防水动画 | `/data` 加密失效 → `$FB -w` 或重刷固件（docs/07 §②） |

---

## Phase 5 · Magisk root

**目标**：Magisk App 显示已安装，`magiskd` 在跑。

### 5.1 取得 boot.img

- 原厂 8.0：用你自己的备份，或从 `firmware/docomo-8.0/kernel.sin` 解出
- LineageOS：`unzip lineage-*.zip boot.img`

### 5.2 打补丁（Linux/WSL）

```bash
cd "$KIT/tools/magisk-patch"
cp /path/to/boot.img .
sh boot_patch.sh boot.img
# 产物: new-boot.img
```

**成功判据**：输出 `Creating new image: [new-boot.img]` 且文件存在。

### 5.3 刷入

```bash
$FB flash boot "$KIT/tools/magisk-patch/new-boot.img"
$FB reboot
```

### 5.4 验证

```bash
$ADB install -r "$KIT/tools/Magisk-v31.1.apk"
$ADB shell "magisk -v"          # 期望: 版本号，例如 31.1
$ADB shell "pidof magiskd"      # 期望: 非空
```

**已知**：Magisk 31 起 `adb shell su` 会被拒（`request rejected (2000)`），
这是设计行为，不代表 root 失败。用 App 授权验证。

---

## Phase 6（可选）· 刷 LineageOS

**目标**：`ro.lineage.version` 有值，NFC 正常。

```bash
$FB boot "$KIT/firmware/lineage/lineage-*-recovery-lilac.img"
# recovery 内进入 Apply from ADB
$ADB sideload "$KIT/firmware/lineage/lineage-*-lilac.zip"
# recovery 内 Format data / Factory reset
```

**成功判据**
- `$ADB shell getprop ro.lineage.version` 非空
- `$ADB shell dumpsys nfc | grep conf` 出现 `libnfc-nci-cxd224x.conf`
- 开机后 boot 已被 ROM 覆盖 → 需要重做 Phase 5

> **不要**用 TWRP `fastboot boot`：本机型实测卡白 Sony logo。
> **不要**在原厂 recovery 里 sideload：会报 `E3004`。

---

## 7. `-s` 参数试值表

按顺序试，命中即停：

```
0xf49880  0xf59880  0xf69880★  0xf79880  0xf89880  0xf99880☆
0xfa9880  0xfb9880  0xfc9880  0xfd9880  0xfe9880
```

★ = 本机验证可用　☆ = XDA 另一台 SO-02K 验证可用

细化步长（每 0x20000）：

```
0xf63880 0xf65880 0xf67880 0xf69880 0xf6b880 0xf6d880 0xf6f880
```

脚本：

```powershell
pwsh scripts/sweep_xperable.ps1 -Kit "C:\sony-kit"
```

**每试一个值前**：确认手机仍在 fastboot（`fastboot devices`），
如果掉出了就重新 关机→音量上→插线。

---

## 8. STOP 条件（立即停止并报告）

满足任一条即停止，不要自行尝试修复：

1. `newflasher` 输出 `flash:bootloader FAILED`
2. 设备管理器出现 `QUSB_BULK` 或 `9008`（EDL 模式）
3. 连续两次刷 P114 都失败，且报错不同
4. `oem unlock Y` 连续 3 次返回 `FAILCommand not allowed`（说明 exploit 完全没打进去）
5. 用户要求"重新上锁"（`fastboot oem lock`）—— 风险极高，见 docs/08 §8.5

---

## 9. 进度记录格式

每个 Phase 结束后追加一行到执行日志：

```
[phase] [timestamp] [result] [key_output]
P3.3    2026-11-03T02:11  OK   sha256 c745a327... 匹配
```

失败时记录：

```
P4.2    2026-11-03T02:20  FAIL -s=0xf3f880 -> "OKAY" 立即退出，无 patched 行
```
