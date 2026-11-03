# 06 · Flashing LineageOS (optional)

[中文](../06-刷LineageOS.md) | **English**

> Unlocking and rooting are enough; a custom ROM is optional.
> This is the flow that actually worked here — **it differs from the XDA TWRP approach**.

| Difficulty | Time | Risk | Prerequisite |
|---|---|---|---|
| ★★☆ | 30 min | Medium (wipes data; must redo root) | [04](04-xperable-unlock.md) completed |

---

## 6.1 Why not TWRP

The original post recommends `fastboot flash recovery twrp-3.5.2_9-0-lilac.img`, but here:

- `fastboot boot twrp-3.5.2_9-0-lilac.img` → **hangs at the white SONY logo**
- Lineage's own recovery → works fine

The SO-02K also has **no dedicated recovery partition** (it uses `FOTAKernel`),
so `fastboot boot` is more reliable than `fastboot flash recovery`.

**Conclusion: `fastboot boot` the Lineage recovery, do not flash it.**

---

## 6.2 Prepare

Get the ROM per [DOWNLOADS](../../DOWNLOADS.en.md) §B4 into `$KIT/firmware/lineage/`:

```
lineage-*-lilac.zip            ROM
lineage-*-recovery-lilac.img   recovery
```

> **Use the `nfc` variant if you need NFC** (docomo CXD224x).
> Official builds may not include it — check before flashing.

---

## 6.3 Flash

### 1. Enter fastboot (Vol UP + USB, blue LED)

### 2. Temporarily boot the recovery

```bash
$FB boot "$KIT/firmware/lineage/lineage-*-recovery-lilac.img"
```

### 3. In recovery, enter sideload mode

`Apply update` → `Apply from ADB`

### 4. Push the ROM

```bash
$ADB sideload "$KIT/firmware/lineage/lineage-*-lilac.zip"
```

Wait for `Total xfer`.

> **If it fails with `E3004: This package is for "lilac"`**
> you are sideloading from stock recovery (which reports `SO-02K`).
> You must sideload from **Lineage recovery** (reports `product:lineage_lilac`).

### 5. Format data (required)

Recovery main menu: `Factory reset` → `Format data/factory reset`

> Coming from stock 8.0, `/data` is encrypted with the stock key; without formatting
> the device hangs at the boot animation.

### 6. Reboot

`Reboot system now`. First boot is slow.

---

## 6.4 Verify

```bash
$ADB shell getprop ro.lineage.version          # non-empty
$ADB shell getprop ro.boot.verifiedbootstate   # orange
$ADB shell dumpsys nfc | grep conf             # libnfc-nci-cxd224x.conf on docomo
```

boot was overwritten by the ROM → **redo [05](05-magisk-root.md)** to regain root.

---

## 6.5 Known issues

| Symptom | Note |
|---|---|
| first boot takes 5–10 min | normal |
| no call audio | known docomo 8.0 bug, see [07](07-troubleshooting.md) |
| TWRP will not boot | known on this unit; use Lineage recovery |
| NFC not working | you flashed a non-`nfc` variant |

---

Previous ← [05 · Magisk root](05-magisk-root.md) | Next → [07 · Troubleshooting](07-troubleshooting.md)
