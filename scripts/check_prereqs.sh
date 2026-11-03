#!/usr/bin/env bash
# check_prereqs.sh — 工作区自检
#
# 用法:
#   KIT=~/sony-kit bash scripts/check_prereqs.sh
#   (Windows Git Bash) KIT=/c/sony-kit bash scripts/check_prereqs.sh
#
# 退出码: 0 = 全部就绪, 1 = 有缺失或校验失败

set -u

KIT="${KIT:-$HOME/sony-kit}"

# Windows (Git Bash / MSYS / Cygwin) 下可执行文件带 .exe
case "$(uname -s 2>/dev/null)" in
  MINGW*|MSYS*|CYGWIN*) EXE=".exe" ;;
  *)                    EXE=""    ;;
esac

ADB="$KIT/tools/platform-tools/adb$EXE"
FB="$KIT/tools/platform-tools/fastboot$EXE"

ok=0; bad=0; skip=0

say()  { printf '  %-46s %s\n' "$1" "$2"; }
good() { say "$1" "OK";      ok=$((ok+1)); }
fail() { say "$1" "MISSING"; bad=$((bad+1)); }
skipn(){ say "$1" "SKIP";    skip=$((skip+1)); }

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

size_of() {
  stat -c%s "$1" 2>/dev/null || stat -f%z "$1" 2>/dev/null
}

check_file() {  # path label [exec]
  local f="$1" label="$2" need_exec="${3:-}"
  if [ ! -f "$f" ]; then fail "$label"; return 1; fi
  if [ -n "$need_exec" ] && [ ! -x "$f" ]; then
    say "$label" "not executable (chmod +x)"
    bad=$((bad+1)); return 1
  fi
  good "$label"; return 0
}

check_hash() {  # path expected
  local f="$1" want="$2" got
  [ -f "$f" ] || return 1
  got=$(sha256_of "$f")
  if [ "$got" = "$want" ]; then
    good "$(basename "$f") hash"
  else
    say "$(basename "$f") hash" "MISMATCH"
    echo "      want: $want"
    echo "      got : $got"
    bad=$((bad+1))
  fi
}

echo "KIT = $KIT"
echo

echo "[工具]"
check_file "$ADB" "adb" exec
check_file "$FB"  "fastboot" exec
check_file "$KIT/tools/newflasher.x64" "newflasher.x64"
check_file "$KIT/tools/xperable/xperable$EXE" "xperable$EXE"
check_file "$KIT/tools/xperable/LinuxLoader-p114.pe" "LinuxLoader-p114.pe"
check_file "$KIT/tools/bindershell/bindershell" "bindershell"
check_file "$KIT/tools/Magisk-v31.1.apk" "Magisk-v31.1.apk"
[ -f "$KIT/tools/zadig.exe" ] && good "zadig.exe (Windows 必需)" || say "zadig.exe" "optional (非 Windows 可忽略)"

echo
echo "[关键文件]"
XFL="$KIT/tools/xfl-o77.mbn"
if [ -f "$XFL" ]; then
  good "xfl-o77.mbn"
  sz=$(size_of "$XFL")
  if [ "$sz" = "13153250" ]; then good "xfl-o77.mbn size"; else
    say "xfl-o77.mbn size" "WRONG ($sz, expected 13153250)"; bad=$((bad+1))
  fi
  check_hash "$XFL" "c745a32721d68bb7499a0e929bd9bcfec307cb922d0c17c22f064a51e6e1a7c7"
else
  fail "xfl-o77.mbn"
fi

echo
echo "[固件]"
[ -d "$KIT/firmware/docomo-8.0" ] && good "firmware/docomo-8.0/" || fail "firmware/docomo-8.0/"

P114=""
for cand in "$KIT/firmware/p114" "$KIT/firmware/P114-bootloader" "$KIT/firmware/bootloader"; do
  [ -d "$cand" ] && { P114="$cand"; break; }
done
if [ -n "$P114" ]; then good "firmware/p114/ ($(basename "$P114"))"; else fail "firmware/p114/"; fi

[ -d "$KIT/firmware/lineage" ] && good "firmware/lineage/" || skipn "firmware/lineage/ (仅 P6 需要)"

echo
echo "[Magisk 补丁工具]"
MP="$KIT/tools/magisk-patch"
if [ -d "$MP" ]; then
  for f in boot_patch.sh util_functions.sh magiskboot magiskinit magisk init-ld; do
    [ -f "$MP/$f" ] && good "magisk-patch/$f" || fail "magisk-patch/$f"
  done
else
  fail "magisk-patch/ (见 DOWNLOADS.md §A6)"
fi

echo
echo "[设备]"
if [ -x "$ADB" ]; then
  out=$("$ADB" devices 2>/dev/null | awk 'NR>1 && NF>=2 && $2!="" {print $1" "$2}')
  if [ -n "$out" ]; then
    while read -r serial state; do say "adb: $serial" "$state"; done <<< "$out"
    ok=$((ok+1))
  else
    say "adb device" "none（正常：手机接在别的机器上时此处为空）"
  fi
fi

echo
echo "----------------------------------------"
echo "结果: $ok OK, $bad 缺失/异常, $skip 跳过"
[ "$bad" -eq 0 ] || { echo "未就绪，按 DOWNLOADS.md 补齐后重试。"; exit 1; }
echo "环境就绪，可以开始 AI-GUIDE.md 的 Phase 1。"
