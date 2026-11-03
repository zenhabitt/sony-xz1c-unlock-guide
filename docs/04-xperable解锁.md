# 04 · xperable 解锁 Bootloader ★核心

> 在内存里把 Fastboot 打补丁，让它接受 `oem unlock`。
> 不改分区、不擦 TA、不需要官方解锁码。

| 难度 | 耗时 | 风险 | 前置 |
|---|---|---|---|
| ★★★ | 20 分钟（不含试 `-s` 值） | **高** —— 全流程唯一可能变砖的步骤 | [03](03-临时root与XFL.md) 全部通过 |

---

## 4.1 原理

`xperable` 利用 ABL Fastboot 命令解析的缓冲区溢出（CVE-2021-1931），
把 `LinuxLoader` PE 镜像写入内存并跳转执行。

被 patch 的 Fastboot 不再校验 `oem unlock` 的权限位，于是返回 `OKAY`。

**这是纯内存操作：重启即失效。**

所以顺序只能是：

```
打补丁 → oem unlock Y → 重启
```

中间**不能拔线、不能重启、不能跑别的 fastboot 命令**。

---

## 4.2 前提检查

- [ ] Android 8.0 / 47.1.F.1.105
- [ ] `fastboot getvar version-bootloader` 含 `P_114`
- [ ] XFL 已写入 O77 并通过 SHA256 校验（[03](03-临时root与XFL.md)）

---

## 4.3 打补丁

手机关机 → 按住 **音量上** → 插 USB → 蓝灯。

```bash
cd "$KIT/tools/xperable"
./xperable.exe -v -V -B -U -s 0xf69880 -5     # Windows
# ./xperable -v -V -B -U -s 0xf69880 -5       # Linux
```

| 参数 | 含义 |
|---|---|
| `-v -V` | 打印 USB 交互细节 |
| `-B -U` | 绑定并使用设备 |
| `-s 0xf69880` | **溢出尺寸**（本机可用值，见 4.5） |
| `-5` | test5：内存 patch 模式 |

### 成功判据（两行都要有）

```
[+] Got LinuxLoader base addr 0x98dbe000 (0x98de6dc8)
[+] LinuxLoader @ 0x98dbe000 patched successfully (usb buff @ 0x97e79000, distance = 0x00f45000)
```

中间还会有：

```
version-bootloader: 1306-5035_X_Boot_MSM8998_LA2.0_P_114
[.] Using p114 xperable target (offset = 0x30, size = 0xf3f880)
[.] Code boundary of LinuxLoader-p114.pe is 0x000e7000
[+] Starting test5 size = 0xf69880, offset = 0x30, payloadsize = 0xe7000
```

> 只有 `patched successfully` 才算成功。
> 只看到 `OKAY` 就退出、或返回 `FAILCommand not allowed`，都说明没打进去。

---

## 4.4 立即解锁

```bash
./xperable.exe -v -V -c "oem unlock Y" -1
```

成功：

```
{0000000c->0000000c:OK} "oem unlock Y"
{00000040<-00000004:OK} "OKAY"
[.] Finished test1: res = 0
```

然后重启：

```bash
./xperable.exe -v -V -c reboot -1
```

---

## 4.5 `-s` 参数怎么找

`-s` 控制溢出尺寸。由于**内存随机化**，同一型号不同机器可能不同。

| 设备 | 可用值 |
|---|---|
| 本文档实机 | `0xf69880` |
| XDA 另一台 SO-02K | `0xf99880` |
| 官方默认 | `0xf3f880`（本机无效） |

### 失败的典型表现（都不代表设备损坏）

- 打印 `Starting test5 ...` 后立刻退出
- `FAILCommand not allowed`
- 手机退出 Fastboot 开始充电
- `libusb_bulk_transfer failed: Pipe error`

### 试值顺序

```
0xf49880  0xf59880  0xf69880★  0xf79880  0xf89880  0xf99880☆
0xfa9880  0xfb9880  0xfc9880  0xfd9880  0xfe9880
```

细化（每 0x20000）：

```
0xf63880 0xf65880 0xf67880 0xf69880 0xf6b880 0xf6d880 0xf6f880
```

脚本：`pwsh scripts/sweep_xperable.ps1 -Kit "$KIT"`

> 每试一个值前确认还在 fastboot（`fastboot devices`），掉出来就重新 关机→音量上→插线。

---

## 4.6 验证解锁

重启进系统后，再进 Fastboot：

```bash
$FB getvar unlocked              # unlocked: yes
$FB getvar all | grep -i "lock"  # flash.locked: 0
```

系统内：

```bash
$ADB shell getprop ro.boot.verifiedbootstate   # orange
```

---

## 4.7 解锁后的状态

- 可刷任意分区、第三方 recovery/ROM、Magisk
- **TA / DRM 未被擦除**（xperable 相对官方解锁的最大优势）
- 解锁状态在重新刷固件后依然保留

---

## 4.8 失败速查

| 现象 | 原因 | 处理 |
|---|---|---|
| `test2/test5 not hit` | XFL 不是 O77 | 回 [03](03-临时root与XFL.md) |
| `FAILCommand not allowed` | 补丁没打上 / 已重启 | 重跑 4.3 |
| `Pipe error` 后退出 Fastboot | `-s` 偏大 | 换相邻更小值 |
| OKAY 但仍 locked | 还没重启 | 重启后复查 |
| 开机循环 | /data 加密失效 | [07](07-排错手册.md) §② |

---

上一篇 ← [03 · 临时 root 与 XFL](03-临时root与XFL.md) ｜ 下一篇 → [05 · Magisk root](05-Magisk-root.md)
