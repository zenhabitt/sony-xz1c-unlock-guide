<#
.SYNOPSIS
  批量尝试 xperable 的 -s 值，直到命中。

.DESCRIPTION
  内存随机化导致 -s 因机而异。本脚本按列表逐个尝试，
  检测到 "patched successfully" 就停下并报告。

.PARAMETER Kit
  工作目录，默认 $HOME/sony-kit 或 C:\sony-kit。
  脚本会在 $Kit\tools\xperable 下找 xperable.exe。

.PARAMETER Sizes
  逗号分隔的十六进制值列表。默认值来自实测与 XDA 记录。

.EXAMPLE
  pwsh scripts/sweep_xperable.ps1 -Kit C:\sony-kit
#>
param(
    [string]$Kit  = $(if ($env:KIT) { $env:KIT } else { Join-Path $HOME 'sony-kit' }),
    [string]$Sizes = "0xf49880,0xf59880,0xf69880,0xf79880,0xf89880,0xf99880,0xfa9880,0xfb9880,0xfc9880,0xfd9880,0xfe9880"
)

$ErrorActionPreference = 'Continue'
$xp = Join-Path $Kit 'tools\xperable\xperable.exe'
$fb = Join-Path $Kit 'tools\platform-tools\fastboot.exe'
$adb = Join-Path $Kit 'tools\platform-tools\adb.exe'

if (-not (Test-Path $xp)) { throw "xperable.exe not found: $xp" }
if (-not (Test-Path $fb)) { throw "fastboot.exe not found: $fb" }

function Wait-Fastboot([int]$timeoutSec = 30) {
    $deadline = (Get-Date).AddSeconds($timeoutSec)
    while ((Get-Date) -lt $deadline) {
        $out = (& $fb devices 2>&1 | Out-String)
        if ($out -match 'fastboot') { return $true }
        Start-Sleep -Seconds 2
    }
    return $false
}

$list = $Sizes -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
Write-Host "trying $($list.Count) values against $xp" -ForegroundColor Cyan

foreach ($s in $list) {
    Write-Host ("`n===== -s {0} =====" -f $s) -ForegroundColor Yellow

    if (-not (Wait-Fastboot 10)) {
        Write-Host "[!] device not in fastboot" -ForegroundColor Red
        if (Test-Path $adb) {
            $a = (& $adb devices 2>&1 | Out-String)
            if ($a -match '\sdevice$' -or $a -match '\sdevice\s') {
                Write-Host "[.] rebooting to bootloader via adb"
                & $adb reboot bootloader 2>&1 | Out-Null
                Start-Sleep -Seconds 12
            }
        }
        if (-not (Wait-Fastboot 60)) {
            Write-Host "[!] still no fastboot - put device in fastboot manually (Vol UP + USB)" -ForegroundColor Red
            break
        }
    }

    Push-Location (Split-Path $xp)
    $out = (& $xp -v -V -B -U -s $s -5 2>&1 | Out-String)
    Pop-Location

    ($out -split "`n") | Where-Object { $_ -match 'Starting test5|base addr|patched successfully|FAIL|error|Pipe' } |
        ForEach-Object { $_.TrimEnd() }

    if ($out -match 'patched successfully') {
        Write-Host "[+] HIT with -s $s" -ForegroundColor Green
        Write-Host "next: xperable.exe -v -V -c `"oem unlock Y`" -1" -ForegroundColor Green
        exit 0
    }
    Start-Sleep -Seconds 2
}

Write-Host "`n[-] no value worked. see docs/04 section 4.5 for finer steps" -ForegroundColor Red
exit 1
