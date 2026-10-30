# 從 Protomaps 全球圖資抽出台灣，產出 tiles/taiwan.pmtiles（約 124 MB），再手動上傳到 R2。
# 用法：pwsh scripts/fetch-tiles.ps1            用最新一天的 build
#       pwsh scripts/fetch-tiles.ps1 20261023   指定日期（清單：maps.protomaps.com/builds）
# 沒裝 pmtiles CLI 時，Windows 會自動下載到 scripts/.bin；其他系統請自行安裝 go-pmtiles。

# 接受參數 string 存入 Build 變數
param([string]$Build)  
# 當遇到 cmdlet 的錯誤時停下腳本 並顯示錯誤訊息 但要注意這管不到外部程式 外部程式需要用最後的 $LASTEXITCODE 檢查是否有成功
$ErrorActionPreference = 'Stop'
# 用 $PSScriptRoot 取得腳本存在的目錄 並去掉最後一層 也就是 scripts 做成字串存到 $root 因為執行的位置可以在任何地方 只要下對路徑就可以執行不是在當下位置的檔案
# 所以要用 PSScriptRoot 取得腳本位置 以確保檔案不會出現預料之外的路徑
$root = Split-Path $PSScriptRoot

# 如果沒有帶參數
if (-not $Build) {
# 透過Invoke-RestMethod https://build-metadata.protomaps.dev/builds.json 取得所有半版 然後 [-1] 取得最新版 然後把後面檔名拿掉取得最新版的日期當作 $Build
  $Build = (Invoke-RestMethod https://build-metadata.protomaps.dev/builds.json)[-1].key -replace '\.pmtiles$'
}

# 嘗試取得 pmtiles 的 source 拿不到就算了 安靜跳過
$pmtiles = (Get-Command pmtiles -ErrorAction SilentlyContinue).Source
# 如果拿不到 $pmtiles 的時候執行
if (-not $pmtiles) {
  # 在腳本存在的目錄加上 .bin/pmtiles.exe 做成字串存在 pmtiles
  $pmtiles = Join-Path $PSScriptRoot '.bin/pmtiles.exe'
  # 確認這個路徑上有沒有檔案
  if (-not (Test-Path $pmtiles)) {
    # 當不是 windows 環境 同時也確定不是舊版的 PS 時發出錯誤訊息
    if (-not $IsWindows -and $PSVersionTable.PSEdition -eq 'Core') { throw '找不到 pmtiles，請安裝 go-pmtiles：https://github.com/protomaps/go-pmtiles/releases' }
    # 製作出環境加上TEMP/go-pmtiles.zip 的路徑
    $zip = Join-Path $env:TEMP 'go-pmtiles.zip'
    # 在下方連結下載檔案並放在 $zip 的位置 同時也命名檔案
    Invoke-WebRequest https://github.com/protomaps/go-pmtiles/releases/download/v1.31.2/go-pmtiles_1.31.2_Windows_x86_64.zip -OutFile $zip
    # 解壓縮檔案
    Expand-Archive $zip (Split-Path $pmtiles) -Force
  }
}

# 新增一個 /tiles 資料夾已經存在就不做也不報錯 並且不用回傳結果
New-Item -ItemType Directory -Force (Join-Path $root 'tiles') | Out-Null
# 設定檔案輸出的位置及檔名
$out = Join-Path $root 'tiles/taiwan.pmtiles'
# 顯示文字 抽出 某日期的檔案 放在 $out 的位置
Write-Host "抽出 $Build → $out"
# 用 & 讓字串當成指令執行 抽出指定座標及指定 zoomin 的圖塊 
& $pmtiles extract "https://build.protomaps.com/$Build.pmtiles" $out --bbox=118.1,21.8,122.1,26.4 --maxzoom=14
# 如果外部程式失敗了 列出外部程式失敗
if ($LASTEXITCODE) { throw "pmtiles extract 失敗（$LASTEXITCODE）" }
