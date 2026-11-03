# 08 · Rollback and Recovery

[中文](../08-回滚与还原.md) | **English**

> This device is very hard to truly brick: as long as the bootloader and flash mode exist,
> there is a way back.

| Difficulty | Time | Risk | Prerequisite |
|---|---|---|---|
| ★★☆ | 10–60 min depending on damage | Medium (recovery is safe, but be precise) | fastboot or flash mode reachable |

---

## 8.1 Classify the damage

| Symptom | Layer | Recoverable |
|---|---|---|
| Stuck at logo / boot loop | boot or data | ✅ reflash boot or firmware |
| No system, but fastboot works (blue) | boot / system | ✅ `fastboot flash` |
| No system, but flash mode works (green) | almost everything | ✅ full newflasher reflash |
| Neither fastboot nor flash mode | bootloader area | ⚠️ needs EDL |
| Device manager shows `QUSB_BULK` / `9008` | EDL mode | ⚠️ needs signed firehose |

Normal operation never goes past the third row.

---

## 8.2 Minimal rollback: restore boot only

```bash
$FB flash boot "$KIT/backup/boot-current.img"
$FB reboot
```

(No backup? Extract a stock boot from the firmware.)

---

## 8.3 Restoring modified partitions

| Partition | Backup file | Reference size |
|---|---|---|
| `abl` | `abl-current.img` | 1,572,864 |
| `boot` | `boot-current.img` | ~19,615,744 |
| `xfl` | `xfl-current.img` | 31,457,280 |

**Option 1: fastboot**

```bash
$FB flash abl "$KIT/backup/abl-current.img"
```

> `xfl` is a bootloader component — **do not** `fastboot flash` it casually; a bad write can
> make fastboot unreachable. Prefer the full reflash in §8.4.

**Option 2: dd from a temporary root shell**

```sh
dd if=/sdcard/abl-current.img of=/dev/block/bootdevice/by-name/abl
```

---

## 8.4 Full rollback to stock 8.0

The most reliable recovery, and the standard fix for the post-unlock boot loop.

1. Power off → Vol DOWN → USB (green LED)
2. ```bash
   cd "$KIT/firmware/docomo-8.0"
   "$KIT/tools/newflasher.x64"
   ```
3. Answer `n` to all four prompts
4. Wait for `Device is put now out of flash mode.`
5. Unplug and boot

> Reflashing stock does **not** relock the bootloader; the unlocked state persists.

---

## 8.5 About relocking (do not do it)

```bash
fastboot oem lock      # do not run casually
```

Risks:

- If the boot partition is not a **pristine, unmodified stock image**, the device refuses to
  boot after locking → brick
- Sony verifies signatures of all partitions
- A bricked device needs EDL + signed firehose, which is not user-recoverable

**Conclusion: once unlocked, stay unlocked. Relocking gains nothing.**

---

## 8.6 Backup checklist

Before flashing anything, make sure you have:

| Item | Required | Note |
|---|---|---|
| Stock firmware | ✅ | the foundation of any rescue |
| Original `xfl` partition | recommended | restores a bootloader component |
| Original `abl` partition | recommended | — |
| Stock `boot` | ✅ | roll back a bad boot patch |
| Current ROM | recommended | reflash the system |
| TA / DRM | ❌ not needed | xperable never touches TA |

> The big advantage of xperable: **it does not touch TA**. DRM keys and camera tuning data
> survive, so unlike an official unlock you do not need a TA backup first.

---

Previous ← [07 · Troubleshooting](07-troubleshooting.md) | Back to [README](../../README.en.md)
