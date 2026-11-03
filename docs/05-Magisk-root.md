# 05 · Magisk Root

> 解锁之后 root 很简单：**给 boot.img 打补丁，刷回 boot 分区**。
> 不动 system，不破坏 OTA。

---

## 5.1 需要什么

| 文件 | 来源 |
|---|---|
| `boot.img` | 你自己的备份，或从 ROM zip / `kernel.sin` 提取 |
| `Magisk-v31.1.apk` | [DOWNLOADS.md](../DOWNLOADS.md) §A6 |
| `boot_patch.sh` + magisk 二进制 | 从同一个 APK 提取（见 §5.2） |

---

## 5.2 从 APK 提取补丁工具

```bash
cd "$KIT/tools"
mkdir -p magisk-patch && cd magisk-patch

unzip -j ../Magisk-v31.1.apk 'lib/arm64-v8a/*' 'assets/boot_patch.sh' 'assets/util_functions.sh'

mv lib/arm64-v8a/libmagiskboot.so magiskboot 2>/dev/null || mv libmagiskboot.so magiskboot
mv lib/arm64-v8a/libmagiskinit.so magiskinit 2>/dev/null || mv libmagiskinit.so magiskinit
mv lib/arm64-v8a/libmagisk.so     magisk     2>/dev/null || mv libmagisk.so magisk
mv lib/arm64-v8a/libinit-ld.so    init-ld    2>/dev/null || mv libinit-ld.so init-ld
chmod +x magiskboot magiskinit magisk init-ld
```

目录应包含：

```
boot_patch.sh  util_functions.sh  magiskboot  magiskinit  magisk  init-ld
```

---

## 5.3 取 boot.img

**原厂 8.0**：用你自己 dump 的 `boot-current.img`，
或从 `firmware/docomo-8.0/kernel.sin` 解出（SIN = gzip + tar，解开是 `ANDROID!` 开头的 boot.img）。

**LineageOS**：

```bash
unzip lineage-*.zip boot.img
```

---

## 5.4 打补丁

> `boot_patch.sh` 是 bash 脚本，需要 **Linux / WSL**。

```bash
cd "$KIT/tools/magisk-patch"
cp /path/to/boot.img .
sh boot_patch.sh boot.img
```

成功输出末尾：

```
Creating new image: [new-boot.img]
```

---

## 5.5 刷入

手机进 Fastboot（音量上 + 插线，蓝灯）：

```bash
$FB flash boot new-boot.img
$FB reboot
```

---

## 5.6 安装 App 并验证

```bash
$ADB install -r "$KIT/tools/Magisk-v31.1.apk"
$ADB shell "magisk -v"        # 例如 31.1
$ADB shell "pidof magiskd"    # 非空
```

Magisk App 首页应显示：

```
Magisk    已安装   31.1
Ramdisk   是
```

> **Magisk 31 起**：`adb shell su` 会被拒（`su: request rejected (2000)`）。
> 这是设计行为（移除了超级用户全局开关），**App 内 root 正常**。
> 需要 ADB root 请用 Magisk 26/27。

---

## 5.7 LineageOS 上重新 root

刷 ROM 会覆盖 boot，需要重做：

```bash
unzip lineage-*.zip boot.img
cd "$KIT/tools/magisk-patch" && cp /path/to/boot.img . && sh boot_patch.sh boot.img
$FB flash boot new-boot.img
```

每次 OTA 后都要重复。

---

## 5.8 常见问题

| 现象 | 处理 |
|---|---|
| 刷完卡 logo | boot 与系统不匹配 → 刷回原 boot |
| Magisk 显示"未安装" | 刷的不是打好补丁的镜像 |
| `boot_patch.sh` 报找不到 magiskboot | §5.2 重命名没做对 |
| 打完补丁开不了机 | 脚本与 APK 版本不匹配（用同一 APK 提取的） |

---

上一篇 ← [04 · xperable 解锁](04-xperable解锁.md) ｜ 下一篇 → [06 · 刷 LineageOS](06-刷LineageOS.md)
