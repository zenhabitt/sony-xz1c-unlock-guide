# 06 · 刷 LineageOS（可选）

**中文** | [English](en/06-lineageos.md)

> 解锁 + root 之后，刷不刷第三方 ROM 都行。
> 这里记录的是实机走通的流程，**与原帖的 TWRP 流程不同**。

| 难度 | 耗时 | 风险 | 前置 |
|---|---|---|---|
| ★★☆ | 30 分钟 | 中（会清数据；刷完需重做 root） | [04](04-xperable解锁.md) 已完成解锁 |

---

## 6.1 为什么不用 TWRP

原帖推荐 `fastboot flash recovery twrp-3.5.2_9-0-lilac.img`，但实机测试：

- `fastboot boot twrp-3.5.2_9-0-lilac.img` → **卡在白 SONY logo**，进不去
- 换 Lineage 自带 recovery → 正常

另外 SO-02K **没有独立 recovery 分区**（走 `FOTAKernel`），
`fastboot flash recovery` 的可靠性不如 `fastboot boot`。

**结论：`fastboot boot` 临时引导 Lineage recovery，不要刷进去。**

---

## 6.2 准备

ROM 来源见 [DOWNLOADS.md](../DOWNLOADS.md) §B4，放到 `$KIT/firmware/lineage/`：

```
lineage-*-lilac.zip            ROM
lineage-*-recovery-lilac.img   recovery
```

> **要 NFC 就用带 `nfc` 标记的变体**（docomo CXD224x）；
> 官方构建不一定包含，刷前确认。

---

## 6.3 刷入

### 1. 进 Fastboot（音量上 + 插线，蓝灯）

### 2. 临时引导 recovery

```bash
$FB boot "$KIT/firmware/lineage/lineage-*-recovery-lilac.img"
```

### 3. recovery 内进入 sideload

`Apply update` → `Apply from ADB`

### 4. 推包

```bash
$ADB sideload "$KIT/firmware/lineage/lineage-*-lilac.zip"
```

进度到 `Total xfer` 结束。

> **如果报 `E3004: This package is for "lilac"`**
> 说明你是在原厂 recovery 里 sideload 的（原厂上报 `SO-02K`）。
> 必须从 **Lineage recovery** 里刷（上报 `product:lineage_lilac`）。

### 5. 格式化 data（必须）

recovery 主界面：`Factory reset` → `Format data/factory reset`

> 从原厂 8.0 过来时 `/data` 的加密密钥是原厂的，不格式化会卡开机动画。

### 6. 重启

`Reboot system now`，首次启动较慢。

---

## 6.4 验证

```bash
$ADB shell getprop ro.lineage.version          # 非空
$ADB shell getprop ro.boot.verifiedbootstate   # orange
$ADB shell dumpsys nfc | grep conf             # 日版应为 libnfc-nci-cxd224x.conf
```

刷完 boot 已被覆盖 → **需要重做 [05](05-Magisk-root.md)** 重新 root。

---

## 6.5 已知问题

| 现象 | 说明 |
|---|---|
| 首次开机 5–10 分钟 | 正常，首次启动要优化 |
| 通话无声 | docomo 8.0 已知 bug，见 [07](07-排错手册.md) |
| TWRP 进不去 | 实机已知，用 Lineage recovery |
| NFC 不工作 | 刷了非 `nfc` 变体 |

---

上一篇 ← [05 · Magisk root](05-Magisk-root.md) ｜ 下一篇 → [07 · 排错手册](07-排错手册.md)
