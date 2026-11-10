# Gaebong station rent radar - daily data collector
# Source: Seoul Open Data Plaza, tbLnOpendataRentV (official rent contract reports)
# Usage:  powershell -ExecutionPolicy Bypass -File update.ps1
# API key: env SEOUL_API_KEY, or first line of apikey.txt next to this script. Falls back to "sample" (5 rows only).

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$key = $env:SEOUL_API_KEY
$keyFile = Join-Path $root 'apikey.txt'
if (-not $key -and (Test-Path $keyFile)) { $key = (Get-Content $keyFile -TotalCount 1).Trim() }
if (-not $key) { $key = 'sample'; Write-Warning 'No API key found - using "sample" key (only 5 rows per query).' }

$GU = '11530'                                   # Guro-gu
$DONGS = @('10700', '10600', '10800')           # Gaebong-dong, Gocheok-dong, Oryu-dong
$today = Get-Date
$years = @(($today.Year - 1), $today.Year)
$cutoff = $today.AddDays(-400).ToString('yyyyMMdd')
$pageSize = if ($key -eq 'sample') { 5 } else { 1000 }

function Esc([string]$s) {
    if ($null -eq $s) { return '' }
    return ($s -replace '\\', '\\' -replace '"', '\"' -replace "[\x00-\x1f]", ' ')
}
function Num($v) {
    if ($null -eq $v -or "$v".Trim() -eq '') { return 'null' }
    $d = 0.0
    if ([double]::TryParse("$v", [Globalization.NumberStyles]::Any, [Globalization.CultureInfo]::InvariantCulture, [ref]$d)) {
        return $d.ToString([Globalization.CultureInfo]::InvariantCulture)
    }
    return 'null'
}

$rows = New-Object System.Collections.Generic.List[string]
$seen = @{}

foreach ($dong in $DONGS) {
    foreach ($yr in $years) {
        $start = 1
        $total = 1
        while ($start -le $total) {
            $end = $start + $pageSize - 1
            $url = "http://openapi.seoul.go.kr:8088/$key/json/tbLnOpendataRentV/$start/$end/$yr/$GU/%20/$dong"
            $res = $null
            for ($try = 1; $try -le 3 -and -not $res; $try++) {
                try { $res = Invoke-RestMethod -Uri $url -TimeoutSec 60 }
                catch { Write-Warning "retry $try : $($_.Exception.Message)"; Start-Sleep -Seconds 3 }
            }
            if (-not $res) { throw "Request failed: dong=$dong year=$yr start=$start" }
            $body = $res.tbLnOpendataRentV
            if (-not $body) {
                $code = $res.RESULT.CODE
                if ($code -eq 'INFO-200') { break }   # no data
                throw "API error: $($res.RESULT.CODE) $($res.RESULT.MESSAGE)"
            }
            $total = [int]$body.list_total_count
            if ($key -eq 'sample') { $total = [Math]::Min($total, 5) }
            foreach ($r in $body.row) {
                if ($r.CTRT_DAY -lt $cutoff) { continue }
                $id = "$($r.CTRT_DAY)|$($r.STDG_CD)|$($r.MNO)-$($r.SNO)|$($r.FLR)|$($r.RENT_AREA)|$($r.GRFE)|$($r.RTFE)"
                if ($seen.ContainsKey($id)) { continue }
                $seen[$id] = 1
                $jibun = ("$([int]("0$($r.MNO)"))" + $(if ([int]("0$($r.SNO)") -gt 0) { "-$([int]("0$($r.SNO)"))" } else { '' }))
                # [date, dong, usage, type, area, deposit, rent, floor, name, builtYear, new/renew, prevDeposit, prevRent, jibun, period]
                $rows.Add(('["{0}","{1}","{2}","{3}",{4},{5},{6},{7},"{8}",{9},"{10}",{11},{12},"{13}","{14}"]' -f `
                    (Esc $r.CTRT_DAY), (Esc $r.STDG_NM), (Esc $r.BLDG_USG), (Esc $r.RENT_SE), (Num $r.RENT_AREA),
                    (Num $r.GRFE), (Num $r.RTFE), (Num $r.FLR), (Esc $r.BLDG_NM), (Num $r.ARCH_YR),
                    (Esc $r.NEW_UPDT_YN), (Num $r.BFR_GRFE), (Num $r.BFR_RTFE), (Esc $jibun), (Esc $r.CTRT_PRD)))
            }
            Write-Host ("dong {0} / {1}: {2}-{3} of {4}" -f $dong, $yr, $start, $end, $total)
            $start = $end + 1
        }
    }
}

$stamp = $today.ToString('yyyy-MM-dd HH:mm')
$sampleFlag = if ($key -eq 'sample') { 'true' } else { 'false' }
$js = "window.RENT_DATA={`"updated`":`"$stamp`",`"sample`":$sampleFlag,`"rows`":[" + ($rows -join ",`n") + "]};"
$outDir = Join-Path $root 'docs'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
[IO.File]::WriteAllText((Join-Path $outDir 'data.js'), $js, (New-Object Text.UTF8Encoding $false))
Write-Host "Saved $($rows.Count) contracts -> docs/data.js ($stamp)"
