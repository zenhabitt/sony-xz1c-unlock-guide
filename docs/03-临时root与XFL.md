# 03 · 临时 root 与替换 XFL

**中文** | [English](en/03-temp-root-and-xfl.md)

> 目标：拿一个临时 root shell，把 **XFL 分区**开头换成 O77 blob。
> 少了这步，xperable 只会输出 `test2 not hit`。

| 难度 | 耗时 | 风险 | 前置 |
|---|---|---|---|
| ★★☆ | 15 分钟 | 中（写 bootloader 相邻分区，务必先备份） | [02](02-刷8.0与P114.md) |

---

## 3.1 为什么需要 bindershell

CVE-2019-2215（binder UAF）在 4.4 内核上可用，能拿到**临时 root**（重启即失效）。
原生索尼 8.0 固件正好在它的偏移表里，无需额外条件。

工具来源见 [DOWNLOADS.md](../DOWNLOADS.md) §A5。

---

## 3.2 拿临时 root

```bash
$ADB push "$KIT/tools/bindershell/bindershell" /data/local/tmp/
$ADB shell
```

进入 adb shell 后：

```sh
cd /data/local/tmp
chmod 755 ./bindershell
./bindershell
```

成功：

```
bindershell - temp root shell for xperia XZ1c/XZ1/XZp using CVE-2019-2215
...
got root, start shell...
SO-02K:/data/local/tmp #
```

提示符变成 `#` 才算成功。

> 这个 shell 只活在内存里，**重启就没了**，也不要指望用它装 Magisk。
> 它的唯一用途是把 XFL 写进去。

---

## 3.3 备份原始分区（强烈建议）

```sh
dd if=/dev/block/bootdevice/by-name/xfl of=/sdcard/xfl-current.img
dd if=/dev/block/bootdevice/by-name/abl of=/sdcard/abl-current.img
dd if=/dev/block/bootdevice/by-name/boot of=/sdcard/boot-current.img
```

`xfl-current.img` 应为 **31,457,280 字节**（30 MB）。

取回电脑：

```bash
$ADB pull /sdcard/xfl-current.img "$KIT/backup/"
$ADB pull /sdcard/abl-current.img "$KIT/backup/"
$ADB pull /sdcard/boot-current.img "$KIT/backup/"
```

---

## 3.4 写入 O77 XFL

```bash
$ADB push "$KIT/tools/xfl-o77.mbn" /sdcard/
```

回到 root shell：

```sh
dd if=/sdcard/xfl-o77.mbn of=/dev/block/bootdevice/by-name/xfl
sync
```

---

## 3.5 校验（不能省）

```sh
sha256sum /sdcard/xfl-o77.mbn
```

必须是：

```
c745a32721d68bb7499a0e929bd9bcfec307cb922d0c17c22f064a51e6e1a7c7
```

再核对分区前 13,153,250 字节：

```sh
dd if=/dev/block/bootdevice/by-name/xfl of=/sdcard/xfl_head.bin bs=1024 count=12845
sha256sum /sdcard/xfl_head.bin
```

两个哈希**必须一样**。

> `xfl-o77.mbn` 本身 13,153,250 字节，XFL 分区 31,457,280 字节。
> 新内容写在开头，后面保持原样 —— exploit 只读前面这一段。

---

## 3.6 常见问题

| 现象 | 处理 |
|---|---|
| `permission denied` | 没 chmod，或不在 `/data/local/tmp` |
| 提示符仍是 `$` | bindershell 没提权成功，重跑 |
| 校验不一致 | 重新 push + dd（别用 `cp`） |
| bindershell 直接崩溃 | 内核/偏移不匹配 → 确认是 8.0 + P114 |

---

上一篇 ← [02 · 刷 8.0 与 P114](02-刷8.0与P114.md) ｜ 下一篇 → [04 · xperable 解锁](04-xperable解锁.md)
