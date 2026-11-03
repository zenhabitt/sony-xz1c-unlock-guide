# Checklist · printable

[中文](CHECKLIST.md) | **English**

> Print it, or copy into your notes, and tick as you go.
> Everything after `→` is a **pass criterion**: do not tick if it does not hold.

---

## Step 0 · Preparation

```
[ ] Device is SO-02K (not SO-01K / international G8441)     → Settings > About > Model
[ ] Battery above 50%
[ ] Data backed up (this flow wipes several times)
[ ] USB cable actually carries data (not charge-only)
[ ] Workspace created ($KIT/tools, firmware, backup)
[ ] Ran check_prereqs.sh                                   → prints "环境就绪" (ready)
```

**Device serial**: `__________________`
**Workspace**: `__________________`

---

## Step 1 · Drivers and modes

```
[ ] adb sees the device                                     → adb devices shows "device"
[ ] fastboot sees the device                                → fastboot devices shows "fastboot"
[ ] flash mode recognised                                   → SOMC Flash Device in device manager
[ ] Can enter Fastboot (Vol UP + cable, blue LED)
[ ] Can enter Flash mode (Vol DOWN + cable, green LED)
```

---

## Step 2 · Downgrade to Android 8.0

```
[ ] Enter flash mode
[ ] Run newflasher inside firmware/docomo-8.0
[ ] Prompt 1 (GordonGate)     answer n
[ ] Prompt 2 (dump TA)        answer n     <- 'y' crashes
[ ] Prompt 3 (both slots)     answer n
[ ] Prompt 4 (persist)        answer n     <- never 'y'
[ ] "Device is put now out of flash mode."
[ ] Device boots
[ ] Version check                                          → ro.build.id = 47.1.F.1.105
```

**Log excerpt**: `________________________________________`

---

## Step 3 · Flash P114 bootloader

```
[ ] Assembled firmware/p114/boot/ (.sin + MiscTA.ta)
[ ] Enter flash mode
[ ] Run newflasher, answer n to all prompts
[ ] "flash:bootloader OKAY"
[ ] Boot up, enter fastboot
[ ] Version check                                          → contains LA2.0_P_114
```

**Matching ABL variant**: `[ ] 5ADA  [ ] 5D31  [ ] C93B`

> Reference unit = **C93B**

---

## Step 4 · Temporary root + write XFL

```
[ ] USB debugging on, adb authorised
[ ] Push bindershell to /data/local/tmp
[ ] Run bindershell                                       → prompt becomes #
[ ] Back up xfl partition                                 → 31,457,280 bytes
[ ] Back up abl partition                                 → 1,572,864 bytes
[ ] Back up boot partition                                → ~19.6 MB
[ ] All three pulled to the PC
[ ] Push xfl-o77.mbn to /sdcard
[ ] dd into the xfl partition
[ ] Verify first 13,153,250 bytes                         → c745a327... matches
```

**xfl backup hash**: `________________________________`

---

## Step 5 · xperable unlock ★

```
[ ] Enter fastboot (blue LED)
[ ] fastboot devices has output
[ ] Run xperable -v -V -B -U -s ___ -5
[ ] "Got LinuxLoader base addr"
[ ] "patched successfully"                                <- both lines required
[ ] IMMEDIATELY xperable -v -V -c "oem unlock Y" -1
[ ] "OKAY"
[ ] xperable -v -V -c reboot -1
[ ] Device boots
[ ] Re-enter fastboot and verify                          → unlocked: yes
[ ] In-system check                                       → verifiedbootstate = orange
```

**Working `-s` value**: `_____________`

> From `patched successfully` to `oem unlock Y`:
> **no unplugging, no rebooting, no other fastboot commands.**

---

## Step 6 · Magisk root

```
[ ] Extracted magisk binaries into tools/magisk-patch/
[ ] Obtained boot.img (own backup, or from ROM zip / kernel.sin)
[ ] Ran boot_patch.sh on Linux/WSL                          → new-boot.img
[ ] fastboot flash boot new-boot.img
[ ] Device boots
[ ] Magisk app installed
[ ] App shows "Installed"                                   → or adb shell magisk -v
[ ] (optional) test a root app and grant access
```

---

## Step 7 (optional) · LineageOS

```
[ ] ROM is the NFC variant (required for docomo)
[ ] fastboot boot lineage-*-recovery-lilac.img
[ ] In recovery: Apply update -> Apply from ADB
[ ] adb sideload lineage-*.zip
[ ] Factory reset -> Format data
[ ] Reboot system
[ ] Boots (first boot is slow)
[ ] ro.lineage.version non-empty
[ ] NFC config correct                                     → libnfc-nci-cxd224x.conf
[ ] Redo Step 6 (boot was overwritten)
```

---

## Never do this

```
X  Answer 'y' to newflasher "dump trim area"
X  Answer 'y' to newflasher "flash persist"
X  Reboot or unplug after "patched successfully"
X  Flash someone else's partition backup onto your device
X  Run fastboot oem lock (relocking, very likely to brick)
X  Relock while boot is not a pristine stock image
X  fastboot boot TWRP directly (hangs at white Sony logo on this model)
X  Sideload LineageOS from stock recovery (fails with E3004)
```

---

## When something goes wrong

| Symptom | Read |
|---|---|
| `test2 not hit` | docs/en/03 §3.5 verify XFL |
| `FAILCommand not allowed` | docs/en/04 §4.3 patch again |
| Boot loop | docs/en/07 §2 |
| Bootloader will not flash | docs/en/02 §2.2 switch ABL variant |
| Completely unresponsive | docs/en/08 §8.1 classify the damage |

**Rule of thumb**: if it still enters fastboot you can recover; if it enters flash mode you
can almost certainly recover.
