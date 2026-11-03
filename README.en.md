# Sony Xperia XZ1 Compact (SO-02K) · Bootloader Unlock + Root Guide

[中文](README.md) | **English**

![license](https://img.shields.io/badge/license-MIT-blue.svg)
![device](https://img.shields.io/badge/device-SO--02K%20%2F%20lilac-informational)
![status](https://img.shields.io/badge/verified-real%20device-success)
![rom](https://img.shields.io/badge/rom-LineageOS%2023.2-lightgrey)

> A complete, real-device record of unlocking and rooting the docomo-only
> Xperia XZ1 Compact **without an official Sony unlock code**, without wiping
> the TA/DRM partition, ending with a bootloader that accepts custom ROMs and Magisk.
> Every command, parameter and error text below was taken from an actual run.

---

## Is this for you? (30-second check)

| Question | Must be |
|---|---|
| Device is **Xperia XZ1 Compact SO-02K** (docomo, codename `lilac`)? | ✅ yes |
| You accept **losing all data** (multiple times)? | ✅ yes |
| You have a **Windows/Linux PC + data cable**? | ✅ yes |
| You want "unlock + root", not "unbrick"? | ✅ yes |

If any answer is no, this repo probably can't help you.

---

## The problem

docomo units have no unlock code and no "OEM unlocking" toggle:

```console
$ fastboot oem unlock
FAILCommand not allowed
```

This is not user error — the path is closed by the carrier. Getting around it takes an
exploit chain:

```
┌─────────────────────────────────────────────────────────────┐
│  Stock Android 8.0 (47.1.F.1.105)                           │
│         │                                                   │
│         ├─► flash P114 bootloader (Android 9 ABL)           │
│         │                                                   │
│         ├─► bindershell temporary root (CVE-2019-2215)      │
│         │        └─► overwrite XFL partition with O77 blob  │
│         │                                                   │
│         ├─► xperable patches fastboot in RAM (CVE-2021-1931)│
│         │        └─► oem unlock Y  ──►  unlocked            │
│         │                                                   │
│         └─► Magisk-patch boot.img ──► Root                  │
└─────────────────────────────────────────────────────────────┘
```

**Biggest win**: `xperable` only touches memory and `boot` — it **never erases TA**,
so DRM keys and camera tuning data survive (official unlock destroys them).

---

## Verified on a real device

| Item | Result |
|---|---|
| Unlock | ✅ `unlocked: yes` / `flash.locked: 0` / `verifiedbootstate: orange` |
| Root | ✅ Magisk 31.1, `magiskd` running |
| DRM / TA | ✅ untouched |
| NFC | ✅ docomo CXD224x detected (`libnfc-nci-cxd224x.conf`) |
| ROM | ✅ LineageOS 23.2 (Android 16) |
| Working parameter | `-s 0xf69880 -5` |

Anything not verified is explicitly marked as such in the docs.

---

## Repository layout

```
sony-xz1c-unlock-guide/
├─ README.md / README.en.md       this file (中文 / English)
├─ AI-GUIDE.md / .en.md           ★ executable state machine (Phase 0–6)
├─ DOWNLOADS.md / .en.md          ★ upstream sources + SHA256 (no binaries)
├─ CHECKLIST.md / .en.md          ★ printable checklist
├─ NOTICE.md                      third-party attribution & licenses
├─ LICENSE                        MIT
├─ docs/
│   ├─ 01-准备.md … 08-回滚与还原.md     (Chinese originals)
│   └─ en/
│       ├─ 01-preparation.md
│       ├─ 02-flash-8.0-and-p114.md
│       ├─ 03-temp-root-and-xfl.md
│       ├─ 04-xperable-unlock.md
│       ├─ 05-magisk-root.md
│       ├─ 06-lineageos.md
│       ├─ 07-troubleshooting.md
│       └─ 08-rollback-and-recovery.md
└─ scripts/
    ├─ check_prereqs.sh           workspace self-check (verifies hashes)
    ├─ sweep_xperable.ps1         brute-force the -s value
    ├─ partinfo.sh                partition info (needs temp root)
    ├─ dump_bl.sh                 back up bootloader partitions
    └─ xfl_info.py                inspect boot images / SIN files
```

---

## Workspace convention

This repo ships **no firmware and no binaries**. Prepare a workspace first:

```
$KIT/                          # e.g. ~/sony-kit
├─ tools/
│   ├─ platform-tools/         adb / fastboot
│   ├─ xperable/               xperable + LinuxLoader-p114.pe
│   ├─ bindershell/            bindershell (arm64)
│   ├─ magisk-patch/           boot_patch.sh + extracted binaries
│   ├─ Magisk-v31.1.apk
│   └─ newflasher.x64
├─ firmware/
│   ├─ docomo-8.0/             47.1.F.1.105 (newflasher layout)
│   ├─ p114/                   P114 bootloader
│   └─ lineage/                LineageOS (optional)
└─ backup/                     your own partition dumps
```

Sources and checksums: [DOWNLOADS.en.md](DOWNLOADS.en.md). Then:

```bash
KIT=~/sony-kit bash scripts/check_prereqs.sh
```

Everything must report `OK` before you start.

---

## Three device states (easy to confuse)

| State | How | LED | Host sees | Used for |
|---|---|---|---|---|
| **Fastboot** | power off → hold **Vol UP** → plug USB | **blue** | `<serial> fastboot` | xperable, flashing boot/recovery |
| **Flash mode** | power off → hold **Vol DOWN** → plug USB | **green** | `SOMC Flash Device` | newflasher |
| Normal | just power on | — | `<serial> device` | adb shell |

> "Power off" means fully powered down from the power menu, not just screen off.

---

## Three facts you must remember

**1. The XFL partition must contain the O77 blob**

```
file:   xfl-o77.mbn
size:   13,153,250 bytes
sha256: c745a32721d68bb7499a0e929bd9bcfec307cb922d0c17c22f064a51e6e1a7c7
```

Mismatch → xperable always prints `test2 not hit`. It is *not* about the version being "too new".

**2. The `-s` value is device-specific**

| Device | Working value |
|---|---|
| The unit these docs were written on | `0xf69880` |
| Another SO-02K reported on XDA | `0xf99880` |
| Upstream default | `0xf3f880` (did not work here) |

This is memory randomisation. See `docs/en/04` §4.5 for the sweep list.

**3. Never reboot between the patch and the unlock command**

The patch lives in RAM only. Right after `patched successfully`,
immediately run `oem unlock Y`. No unplugging, no rebooting, no other fastboot commands.

---

## Getting started

**Humans** → read [docs/en/01-preparation.md](docs/en/01-preparation.md) through 08,
using [CHECKLIST.en.md](CHECKLIST.en.md) to tick things off.

**AI / automation** → read [AI-GUIDE.en.md](AI-GUIDE.en.md):
```
Phase 0 env check → Phase 1 ROM check → Phase 2 P114 →
Phase 3 temp root + XFL → Phase 4 unlock → Phase 5 Magisk → Phase 6 (optional) LineageOS
```
Each phase has preconditions, commands, success criteria, failure branches and stop conditions.

**Just want the pitfalls** → [docs/en/07-troubleshooting.md](docs/en/07-troubleshooting.md).

---

## Risk & disclaimer

- The flow **wipes data multiple times** and modifies bootloader-related state
- Only for devices **you own**
- Verified on one unit, but **your variant may differ** (especially `-s` and the ABL variant)
- No warranty: use at your own risk

---

## Credits

| Project | Author | License |
|---|---|---|
| [xperable](https://github.com/j4nn/xperable) | j4nn | GPL-3.0 |
| [renoshell](https://github.com/j4nn/renoshell) | j4nn | GPL-2.0 |
| [newflasher](https://github.com/munjeni/newflasher) | munjeni | MIT |
| [Magisk](https://github.com/topjohnwu/Magisk) | John Wu | GPL-3.0 |

The flow was first learned from an XDA thread (author: Omrad). The documents here are
rewritten from an actual run; differences from the original post (e.g. TWRP not usable,
Lineage recovery used instead) are noted inline.
