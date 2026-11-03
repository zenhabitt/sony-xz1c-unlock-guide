# 03 · Temporary Root and XFL Replacement

[中文](../03-临时root与XFL.md) | **English**

> Goal: obtain a temporary root shell and overwrite the beginning of the **XFL partition**
> with the O77 blob. Without this, xperable only ever prints `test2 not hit`.

| Difficulty | Time | Risk | Prerequisite |
|---|---|---|---|
| ★★☆ | 15 min | Medium (writes next to the bootloader — back up first) | [02](02-flash-8.0-and-p114.md) |

---

## 3.1 Why bindershell

CVE-2019-2215 (binder UAF) works on this 4.4 kernel and yields **temporary root**
(lost on reboot). Stock Sony 8.0 is in its offset table, so nothing else is needed.

Get it per [DOWNLOADS](../../DOWNLOADS.en.md) §A5.

---

## 3.2 Get temporary root

```bash
$ADB push "$KIT/tools/bindershell/bindershell" /data/local/tmp/
$ADB shell
```

Inside the adb shell:

```sh
cd /data/local/tmp
chmod 755 ./bindershell
./bindershell
```

Success:

```
bindershell - temp root shell for xperia XZ1c/XZ1/XZp using CVE-2019-2215
...
got root, start shell...
SO-02K:/data/local/tmp #
```

The prompt must become `#`.

> This shell lives in memory only. It is **not** how you install Magisk —
> its only job is writing the XFL.

---

## 3.3 Back up the original partitions (strongly recommended)

```sh
dd if=/dev/block/bootdevice/by-name/xfl of=/sdcard/xfl-current.img
dd if=/dev/block/bootdevice/by-name/abl of=/sdcard/abl-current.img
dd if=/dev/block/bootdevice/by-name/boot of=/sdcard/boot-current.img
```

`xfl-current.img` should be **31,457,280 bytes**.

Pull to the PC:

```bash
$ADB pull /sdcard/xfl-current.img "$KIT/backup/"
$ADB pull /sdcard/abl-current.img "$KIT/backup/"
$ADB pull /sdcard/boot-current.img "$KIT/backup/"
```

---

## 3.4 Write the O77 XFL

```bash
$ADB push "$KIT/tools/xfl-o77.mbn" /sdcard/
```

Back in the root shell:

```sh
dd if=/sdcard/xfl-o77.mbn of=/dev/block/bootdevice/by-name/xfl
sync
```

---

## 3.5 Verify (do not skip)

```sh
sha256sum /sdcard/xfl-o77.mbn
```

Must be:

```
c745a32721d68bb7499a0e929bd9bcfec307cb922d0c17c22f064a51e6e1a7c7
```

Then compare the first 13,153,250 bytes of the partition:

```sh
dd if=/dev/block/bootdevice/by-name/xfl of=/sdcard/xfl_head.bin bs=1024 count=12845
sha256sum /sdcard/xfl_head.bin
```

Both hashes **must be identical**.

> `xfl-o77.mbn` is 13,153,250 bytes; the XFL partition is 31,457,280.
> The new content sits at the start; the remainder is untouched — the exploit only reads
> the beginning.

---

## 3.6 Troubleshooting

| Symptom | Fix |
|---|---|
| `permission denied` | not chmod'ed, or not in `/data/local/tmp` |
| prompt still `$` | bindershell failed to escalate; retry |
| hash mismatch | re-push and re-dd (never `cp`) |
| bindershell crashes immediately | kernel/offsets mismatch — confirm 8.0 + P114 |

---

Previous ← [02 · Flash 8.0 and P114](02-flash-8.0-and-p114.md) | Next → [04 · xperable unlock](04-xperable-unlock.md)
