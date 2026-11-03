#!/system/bin/sh
# dump_bl.sh — 备份 bootloader 相关分区（需要临时 root）
# 用法: adb push dump_bl.sh /data/local/tmp/ && adb shell "sh /data/local/tmp/dump_bl.sh"
# 产物在 /sdcard/bl-backup/，之后 adb pull 下来

OUT=/sdcard/bl-backup
mkdir -p "$OUT"

for p in xfl abl ablbak boot; do
  dev=/dev/block/bootdevice/by-name/$p
  if [ -e "$dev" ]; then
    echo ">>> dumping $p"
    dd if="$dev" of="$OUT/$p.img" 2>&1 | tail -1
    sync
    sha256sum "$OUT/$p.img" 2>/dev/null
  else
    echo ">>> skip $p (not present)"
  fi
done

echo "---"
echo "done. pull with:"
echo "  adb pull $OUT"
