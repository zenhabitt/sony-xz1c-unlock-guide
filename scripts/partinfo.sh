#!/system/bin/sh
# partinfo.sh — 列出关键分区信息（需要临时 root）
# 用法: adb push partinfo.sh /data/local/tmp/ && adb shell "sh /data/local/tmp/partinfo.sh"

id
echo ---PARTITIONS---
awk 'NR>2 {print $3, $4}' /proc/partitions \
  | grep -E '^(abl|ablbak|xbl|tz|hyp|xfl|boot|misc|persist|recovery|FOTAKernel)$'

echo ---SIZES---
for p in xfl abl ablbak boot recovery FOTAKernel; do
  dev=/dev/block/bootdevice/by-name/$p
  if [ -e "$dev" ]; then
    sz=$(wc -c < "$dev" 2>/dev/null)
    echo "$p size=$sz"
  fi
done

echo ---XFL-STRINGS---
strings /dev/block/bootdevice/by-name/xfl 2>/dev/null \
  | grep -iE 'X_Boot|LA1_[0-9]_[A-Z]_[0-9]+|LA2_[0-9]_[A-Z]_[0-9]+' | head -20

echo ---ABL-STRINGS---
strings /dev/block/bootdevice/by-name/abl 2>/dev/null \
  | grep -iE 'X_Boot_MSM8998|LA1_[0-9]_[A-Z]_[0-9]+|LA2_[0-9]_[A-Z]_[0-9]+' | head -20

echo ---BOOT-MAGIC---
dd if=/dev/block/bootdevice/by-name/boot bs=1 count=8 2>/dev/null

echo ---DONE---
