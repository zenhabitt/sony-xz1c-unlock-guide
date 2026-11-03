# 操作清单 · 可打印

> 打印出来，或复制到你自己的笔记里，做一步勾一步。
> 每项后面的 `→` 是**判据**：不满足就不要打勾。

---

## 第 0 步：准备

```
[ ] 确认机型是 SO-02K（而非 SO-01K / G8441 国际版）        → 设置→关于手机→型号
[ ] 电量 > 50%
[ ] 数据已备份（这流程会清好几次）
[ ] 数据线是能传数据的（不是纯充电线）
[ ] 工作目录建好（$KIT/tools、firmware、backup）
[ ] 跑过 check_prereqs.sh                                 → 输出 "环境就绪"
```

**我的设备序列号**：`__________________`
**工作目录**：`__________________`

---

## 第 1 步：驱动与模式

```
[ ] adb 能识别                                             → adb devices 显示 device
[ ] fastboot 能识别                                       → fastboot devices 显示 fastboot
[ ] flash mode 能识别                                     → 设备管理器出现 SOMC Flash Device
[ ] 会进 Fastboot（音量上+插线，蓝灯）
[ ] 会进 Flash mode（音量下+插线，绿灯）
```

---

## 第 2 步：降到 Android 8.0

```
[ ] 进 Flash mode
[ ] 在 firmware/docomo-8.0 运行 newflasher
[ ] 提示 1（GordonGate）       答 n
[ ] 提示 2（dump TA）          答 n     ← 答 y 会崩溃
[ ] 提示 3（双槽刷写）         答 n
[ ] 提示 4（persist）          答 n     ← 绝对不能 y
[ ] 看到 "Device is put now out of flash mode."
[ ] 开机成功
[ ] 版本确认                                              → ro.build.id = 47.1.F.1.105
```

**日志摘录**：`________________________________________`

---

## 第 3 步：刷 P114 bootloader

```
[ ] 组装 firmware/p114/boot/（.sin + MiscTA.ta）
[ ] 进 Flash mode
[ ] 运行 newflasher，提示全答 n
[ ] 看到 "flash:bootloader OKAY"
[ ] 开机后进 Fastboot
[ ] 版本确认                                              → 含 LA2.0_P_114
```

**匹配的 ABL 变体**：`[ ] 5ADA  [ ] 5D31  [ ] C93B`

> 本机实测 = **C93B**

---

## 第 4 步：临时 root + 写 XFL

```
[ ] 开启 USB 调试，adb 授权
[ ] push bindershell 到 /data/local/tmp
[ ] 运行 bindershell                                     → 提示符变 #
[ ] 备份 xfl 分区                                        → 31,457,280 字节
[ ] 备份 abl 分区                                        → 1,572,864 字节
[ ] 备份 boot 分区                                       → ~19.6 MB
[ ] 三个备份已 pull 到电脑
[ ] push xfl-o77.mbn 到 /sdcard
[ ] dd 写入 xfl 分区
[ ] 校验分区前 13,153,250 字节                            → c745a327… 一致
```

**xfl-backup 校验值**：`________________________________`

---

## 第 5 步：xperable 解锁 ★

```
[ ] 进 Fastboot（蓝灯）
[ ] fastboot devices 有输出
[ ] 运行 xperable -v -V -B -U -s ___ -5
[ ] 出现 "Got LinuxLoader base addr"
[ ] 出现 "patched successfully"                          ← 两行缺一不可
[ ] 【立即】xperable -v -V -c "oem unlock Y" -1
[ ] 出现 "OKAY"
[ ] xperable -v -V -c reboot -1
[ ] 开机成功
[ ] 进 Fastboot 复查                                     → unlocked: yes
[ ] 系统内确认                                           → verifiedbootstate = orange
```

**成功的 `-s` 值**：`_____________`

> ⚠️ 从 `patched successfully` 到 `oem unlock Y` 之间：
> **不拔线、不重启、不跑别的 fastboot 命令**。

---

## 第 6 步：Magisk root

```
[ ] 从 APK 提取 magisk 二进制到 tools/magisk-patch/
[ ] 取得 boot.img（原厂备份，或从 ROM zip / kernel.sin）
[ ] 在 Linux/WSL 执行 boot_patch.sh                          → 生成 new-boot.img
[ ] fastboot flash boot new-boot.img
[ ] 开机成功
[ ] 安装 Magisk App
[ ] App 首页显示 "已安装"                                     → 或 adb shell magisk -v
[ ] (可选) 装个需要 root 的 App 实测授权
```

---

## 第 7 步（可选）：LineageOS

```
[ ] 确认 ROM 是 NFC 变体（日版需要）
[ ] fastboot boot lineage-*-recovery-lilac.img
[ ] recovery 内：Apply update → Apply from ADB
[ ] adb sideload lineage-*.zip
[ ] Factory reset → Format data
[ ] Reboot system
[ ] 开机成功（首次较慢）
[ ] ro.lineage.version 非空
[ ] NFC 配置正确                                          → libnfc-nci-cxd224x.conf
[ ] 重新做第 6 步（boot 已被覆盖）
```

---

## 绝对不要做的事

```
✗ 在 newflasher 问 "dump trim area" 时答 y
✗ 在 newflasher 问 "flash persist" 时答 y
✗ 在 "patched successfully" 之后重启或拔线
✗ 用别人的分区备份刷自己的机器
✗ 执行 fastboot oem lock（重新上锁，极易变砖）
✗ 在 boot 不是原厂镜像时上锁
✗ 用 TWRP 直接 fastboot boot（本机型卡白 logo）
✗ 在原厂 recovery 里 sideload LineageOS（会报 E3004）
```

---

## 出问题时

| 现象 | 先看 |
|---|---|
| `test2 not hit` | docs/03 §3.5 校验 XFL |
| `FAILCommand not allowed` | docs/04 §4.3 重新打补丁 |
| 开机循环 | docs/07 §② |
| bootloader 刷不进 | docs/02 §2.2 换 ABL 变体 |
| 完全无响应 | docs/08 §8.1 判断损坏等级 |

**通用原则**：能进 fastboot 就还有救；能进 flash mode 基本都能救回来。
