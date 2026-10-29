# 從 Protomaps 全球圖資抽出台灣，產出 tiles/taiwan.pmtiles（約 124 MB），再手動上傳到 R2。
# 用法：pwsh scripts/fetch-tiles.ps1            用最新一天的 build
#       pwsh scripts/fetch-tiles.ps1 20261023   指定日期（清單：maps.protomaps.com/builds）
# 沒裝 pmtiles CLI 時，Windows 會自動下載到 scripts/.bin；其他系統請自行安裝 go-pmtiles。
param([string]$Build)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot

if (-not $Build) {
  $Build = (Invoke-RestMethod https://build-metadata.protomaps.dev/builds.json)[-1].key -replace '\.pmtiles$'
}

$pmtiles = (Get-Command pmtiles -ErrorAction SilentlyContinue).Source
if (-not $pmtiles) {
  $pmtiles = Join-Path $PSScriptRoot '.bin/pmtiles.exe'
  if (-not (Test-Path $pmtiles)) {
    if (-not $IsWindows -and $PSVersionTable.PSEdition -eq 'Core') { throw '找不到 pmtiles，請安裝 go-pmtiles：https://github.com/protomaps/go-pmtiles/releases' }
    $zip = Join-Path $env:TEMP 'go-pmtiles.zip'
    Invoke-WebRequest https://github.com/protomaps/go-pmtiles/releases/download/v1.31.2/go-pmtiles_1.31.2_Windows_x86_64.zip -OutFile $zip
    Expand-Archive $zip (Split-Path $pmtiles) -Force
  }
}

New-Item -ItemType Directory -Force (Join-Path $root 'tiles') | Out-Null
$out = Join-Path $root 'tiles/taiwan.pmtiles'
Write-Host "抽出 $Build → $out"
& $pmtiles extract "https://build.protomaps.com/$Build.pmtiles" $out --bbox=118.1,21.8,122.1,26.4 --maxzoom=14
if ($LASTEXITCODE) { throw "pmtiles extract 失敗（$LASTEXITCODE）" }
