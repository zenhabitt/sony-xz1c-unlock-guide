#!/usr/bin/env bash
# check_prereqs.sh — 环境自检
# 用法: KIT=~/sony-kit bash scripts/check_prereqs.sh
set -u

KIT="${KIT:-$HOME/sony-kit}"
ADB="$KIT/tools/platform-tools/adb"
FB="$KIT/tools/platform-tools/fastboot"
ok=0; bad=0

say() { printf '%-52s %s\n' "$1" "$2"; }
good() { say "$1" "OK"; ok=$((ok+1)); }
fail() { say "$1" "MISSING"; bad=$((bad+1)); }

echo "KIT = $KIT"
echo

echo "--- 工具 ---"
[ -x "$ADB" ] && good "adb" || fail "adb ($ADB)"
[ -x "$FB" ]  && good "fastboot" || fail "fastboot ($FB)"
[ -x "$KIT/tools/newflasher.x64" ] && good "newflasher" || fail "newflasher.x64"
[ -f "$KIT/tools/xperable/xperable.exe" ] || [ -f "$KIT/tools/xperable/xperable" ] \
  && good "xperable" || fail "xperable"
[ -f "$KIT/tools/xperable/LinuxLoader-p114.pe" ] && good "LinuxLoader-p114.pe" || fail "LinuxLoader-p114.pe"
[ -f "$KIT/tools/bindershell/bindershell" ] && good "bindershell" || fail "bindershell"
[ -f "$KIT/tools/Magisk-v31.1.apk" ] && good "Magisk APK" || fail "Magisk-v31.1.apk"

echo
echo "--- 关键文件校验 ---"

check_hash() { # path expected_sha
  local f="$1" want="$2"
  if [ ! -f "$f" ]; then say "$(basename "$f")" "MISSING"; bad=$((bad+1)); return; fi
  local got
  if command -v sha256sum >/dev/null 2>&1; then
    got=$(sha256sum "$f" | awk '{print $1}')
  else
    got=$(shasum -a 256 "$f" | awk '{print $1}')
  fi
  if [ "$got" = "$want" ]; then good "$(basename "$f")"; else
    say "$(basename "$f")" "HASH MISMATCH"
    echo "    want: $want"
    echo "    got : $got"
    bad=$((bad+1))
  fi
}

check_hash "$KIT/tools/xfl-o77.mbn" \
  "c745a32721d68bb7499a0e929bd9bcfec307cb922d0c17c22f064a51e6e1a7c7"

[ -f "$KIT/tools/xfl-o77.mbn" ] && {
  sz=$(stat -c%s "$KIT/tools/xfl-o77.mbn" 2>/dev/null || stat -f%z "$KIT/tools/xfl-o77.mbn")
  [ "$sz" = "13153250" ] && good "xfl-o77.mbn size" || say "xfl-o77.mbn size" "WRONG ($sz)"
}

echo
echo "--- 固件 ---"
[ -d "$KIT/firmware/docomo-8.0" ] && good "firmware/docomo-8.0/" || fail "firmware/docomo-8.0/"
[ -d "$KIT/firmware/p114" ] && good "firmware/p114/" || fail "firmware/p114/"
[ -d "$KIT/firmware/lineage" ] && good "firmware/lineage/ (可选)" || say "firmware/lineage/" "optional"

echo
echo "--- 设备 ---"
if [ -x "$ADB" ]; then
  devs=$("$ADB" devices 2>/dev/null | awk 'NR>1 && $2=="device"{print $1}')
  if [ -n "$devs" ]; then say "adb device" "OK ($devs)"; else say "adb device" "none"; fi
fi

echo
echo "结果: $ok OK, $bad 项缺失/异常"
[ "$bad" -eq 0 ] || exit 1
