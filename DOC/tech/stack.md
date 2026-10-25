# 技術選型

日期：2026-10-23　階段：4. 技術可行性評估／6. 最小設計

| 項目 | 選擇 | 理由／備註 |
| --- | --- | --- |
| 平台 | 手機優先的 PWA（只加 manifest，不做 service worker 與離線） | 記錄多在店裡用手機；免上架。未來拍照用 `<input type="file" accept="image/*" capture="environment">` 即可，不受影響 |
| 前端 | Next.js（App Router）＋ TypeScript ＋ Tailwind，不加 UI 元件庫 | 技術驗證已用 Next.js |
| 後端 | Next.js Route Handlers（`app/api/.../route.ts`），以 `postgres` 套件直接寫 SQL | 前端只呼叫後端，不碰資料庫；見 [ADR 0002](../adr/0002-own-backend-api-and-auth.md) |
| 登入 | 自己做：`crypto.scrypt` 密碼雜湊、資料庫 session | 不用 Supabase Auth；見下方規則 |
| 地圖 | MapLibre GL JS ＋ pmtiles，自抽 Protomaps 台灣圖資 | 見 [custom-map-prototype.md](custom-map-prototype.md)；只在 client 端執行 |
| 資料庫 | Supabase 免費方案，只當託管 Postgres：PostGIS、pg_trgm | 後端經連線池（transaction 模式）連線 |
| 網站部署 | Vercel Hobby | 推 git 自動部署；Hobby 不可商用，收費前要換方案 |
| 圖資放置 | Cloudflare R2（試用期用 r2.dev 網址） | 流量免費；Protomaps 官方推薦的放置位置。前端直接以 Range 讀取，不用 Worker。CORS 設定見下方 |
| 測試 | Vitest（計數、亮度、後端權限）＋ 一條 Playwright 主流程（註冊 → 新增店家 → 到訪 → 地圖出現篝火） | 只測錯了會出事、又不易發現的規則 |

## 規則

- **權限**：到訪（含筆記）與回憶一律經過強制帶入目前使用者的資料存取函式，route 裡不直接查這些資料表；存取別人的資料一律回 404。資料表開 RLS 但不寫政策，只有後端的 service 連線能存取。
- **密碼**：`crypto.scrypt` 加每人隨機 salt，比對用 `crypto.timingSafeEqual`。
- **Session**：32 bytes 隨機 token，放在 httpOnly、Secure、SameSite=Lax 的 cookie；資料庫只存 token 的 SHA-256。一個月有效，每次使用往後延；登出、重設密碼時刪除，修改密碼時刪除其他裝置的 session。
- **防暴力破解**：同一 email 連續登入失敗 10 次鎖 15 分鐘；錯誤訊息一律「email 或密碼錯誤」。ponytail：只依 email 計數，換 email 試不會被擋；正式開放時加 IP 限制。
- **CSRF**：非 GET 請求檢查 `Origin` 必須是自己的網域，不符回 403。
- **寄信**：系統完全不寄信。忘記密碼用本機腳本 `npm run reset-password -- <email>` 產生臨時密碼並刪掉該使用者所有 session，系統方手動回信。有自有網域後改接 Resend。
- **時間**：資料庫一律存 UTC（`timestamptz`），後端讀出時換算成 `Asia/Taipei`；到訪時間由後端寫入，不收前端日期。
- **Google 連結**：後端只展開 `maps.app.goo.gl`，存展開後的完整網址並取出店家代碼；展開失敗就存原短網址。只打一次（`redirect: 'manual'`），讀第一跳的 `Location`，host 必須是 `google.com`、`www.google.com` 或 `maps.google.com`；5 秒逾時。代碼當字串存，長度不固定。
- **資料庫結構**：一律用 Supabase CLI 的 migration 檔管理並放進 git，不在後台手動改。
- **Design system 先行**：任何畫面開發前，先定好顏色、字級、間距與基本元件，寫成 Tailwind theme，並做一頁元件總覽。畫面只能使用 design system 定義的值。
- **風格必須是自己的**：絕對不接受 AI 或框架的預設長相，見下方「畫面風格」。
- **網域**：先用 Vercel 免費網址。

## 測試與 Code Review 建議

每次涉及程式邏輯的 code review，盡量完成以下三項；沿用專案既有工具，先檢查本次變更與受影響的核心邏輯。

| 檢查 | 目的與執行重點 |
| --- | --- |
| 單元測試 | 用 Vitest 驗證正常、錯誤與邊界情境，優先涵蓋計數、亮度、權限、登入與 session。測試應驗證需求與結果；修 bug 時先確認測試能重現問題。 |
| CRAP | 結合函式的循環複雜度與實際測試涵蓋率，找出複雜又缺少測試保護的函式。可評估 `crap-typescript` 搭配 Vitest；超過 30 作為檢查提示，並觀察本次變更是否惡化，不直接當成全面重寫或阻擋合併的硬門檻。 |
| 變異測試 | 可用 StrykerJS 配合 Vitest，優先對本次變更的核心邏輯執行。檢查存活變異是否暴露缺少斷言或邊界案例；等價變異另行說明，不為追求分數寫無意義測試。 |

- 建議順序：單元測試通過並產生涵蓋率 → 計算 CRAP → 執行變異測試。單元測試失敗時先回報或在獲授權的修正範圍內處理，再跑後續檢查。
- 涵蓋率不等於斷言有效，CRAP 低分也不代表沒有 bug；三者互補，仍需人工檢查需求、權限與資料流。
- Review 結果須分別列出三項的執行命令、範圍與結果；CRAP 列出高分函式，變異測試列出值得處理的存活變異。未執行要寫明原因與下一步，不得省略或標為通過。
- 尚未配置工具時，列出缺少的設定；首次建立測試流程時再整合三項工具。純文件或不涉及程式邏輯的修改可以不跑，但需註明不適用原因。
- 可重用的 Codex skill：`$review-test-quality`，在 code review 時提醒並執行上述三項；skill 是流程指引，實際執行仍需專案內的測試工具與設定。

工具文件：[Vitest](https://vitest.dev/)、[crap-typescript](https://github.com/fabian-barney/crap-typescript)、[StrykerJS](https://stryker-mutator.io/docs/stryker-js/introduction/)。

## 畫面風格

風格是這個產品的一部分，不是開發完再補的外皮。AI 給的設計只能當候選，不能直接採用。

- **出發點**：從 [ideas.md](../brainstorm/ideas.md) 的「風格與意象」長出來：平靜、深夜小店、篝火、秘密基地；底圖已定為黑色陸地（見 [custom-map-prototype.md](custom-map-prototype.md)）。每個顏色、字體、元件形狀都要說得出跟這些意象的關係。
- **先定方向再做 theme**：先蒐集參考（喜歡的 App、店招、燈光、紙本等），決定方向與關鍵字，由自己拍板；之後才寫 Tailwind theme。
- **禁止的預設長相**：Tailwind／shadcn 範例式的灰白卡片、大圓角加陰影、紫藍漸層、預設 Inter 或系統字體不加思考地使用、emoji 當圖示、通用 SaaS 介面感。
- **AI 的角色**：每次提出 2～3 個明顯不同的方向給自己選，並說明取捨；不得自行決定風格，也不得在沒指定時套用預設樣式。
- **檢查方式**：元件總覽頁完成後問自己：「遮掉 logo，看得出是這個 App 嗎？」看不出來就重做。

### 目前方向（2026-10-25）

以「純黑與橘、霧面」為基準：炭黑底加細顆粒、無陰影無光暈、圓角 4px，橘色只用在少數重點（上緣線、價位、主要按鈕）。之後再延伸；黑魂創角畫面式的細雙框、兩端淡出的分隔線、火光光帶列為候選，不照搬其裝飾與佈局。試做頁見 `output/prototypes/preview-card.html`（預覽卡第 3 張）。

- 選中狀態與主要按鈕用實心橘底深字（表單試做 B，見 `output/prototypes/visit-form.html`）。
- 回憶頁用「淺灰燼」：底色變淺的暖灰（約 `#3a3835`），文字與次要按鈕為灰白，「復活」維持橘色；一般店家頁版面照試做。見 `output/prototypes/store-page.html`。

### 風格比重：功能骨架＋招牌時刻

不做遊戲式的沉浸介面（主要在店裡單手快速記錄、地圖 WebGL 已吃效能、試用者要一看就會），也不在每個元件平均套材質（最容易變回預設長相）。表單、清單、按鈕、登入頁維持清楚好按，靠 design system 統一的顏色、字體、間距撐起風格；風格預算集中在以下時刻：

| 時刻 | 做法方向 |
| --- | --- |
| 開啟畫面 | 地圖載入時顯示，載完淡出 |
| 一般載入 | 與開啟畫面同一個圖形，縮小 |
| 地圖與篝火 | 篝火三級亮度，輕微晃動 |
| 送出到訪 | 回到地圖時篝火點燃或變亮一下 |
| 回憶 | 火熄後的灰燼色系 |
| 空狀態 | 一堆還沒點的柴 |

- **開啟畫面**：寫在 HTML 裡（inline SVG＋CSS 動畫），不等 JS；地圖載完就淡出，不設最短顯示時間，動畫要隨時被打斷都好看。manifest 的 `background_color` 與開啟畫面相同，接上 PWA 系統啟動畫面不閃。
- **一般載入**：等待超過約 300ms 才顯示，置中小火苗，不做骨架畫面。
- **減少動態效果**（`prefers-reduced-motion`）：招牌動畫全部停掉，載入只留火光明暗。
- **效能**：材質優先用 CSS 與 SVG，少用點陣圖；內文用系統字體，另外載入的字型只用在標題或品牌字並只取用到的字。

## 已知限制

- Supabase 免費方案連續 7 天無使用會暫停專案。對策：外部排程（Codex 自動化）每週打一次 `/api/health`，該 API 會實際查資料庫（`select 1`）；仍被暫停再考慮升級 Pro（約每月 25 美元）。
- ponytail: 圖資以矩形範圍抽出，包含福建沿岸。有人反映再改用 `--region` 給台灣、澎湖、金門、馬祖的多邊形。
- 換資料庫時，資料與帳號（標準 Postgres）直接搬，後端只換連線字串。
- ponytail：r2.dev 網址官方定位為開發用，有未公開的速率限制，也沒有快取，每次 Range 讀取都算一次 Class B 操作（免費額度每月 1000 萬次）。試用規模可以接受；正式開放時改用自有網域（需在同一個 Cloudflare 帳號下），並為 `.pmtiles` 設 Cache Rule。Free 方案單一檔案超過 512 MB 不會被快取。

## R2 設定

- 圖資必須是 PMTiles v3 格式（pmtiles JS 4.x 已不支援 v2）。上傳時不要加 `Content-Encoding` metadata，圖磚本身已經壓縮。
- 重新上傳圖資後 ETag 會改變，pmtiles 函式庫會自動清掉快取並重試，不需要另外處理。
- CORS（R2 後台 Settings → CORS Policy）。每條規則最多一個萬用字元；Vercel preview 網址每次不同，要用一個萬用字元涵蓋，或逐一列出。改完最多 30 秒生效：

```json
[
  {
    "AllowedOrigins": ["https://<專案>.vercel.app", "http://localhost:3000"],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedHeaders": ["range", "if-match"],
    "ExposeHeaders": ["etag", "content-range"],
    "MaxAgeSeconds": 3000
  }
]
```

來源：[Protomaps：Cloud Storage](https://docs.protomaps.com/pmtiles/cloud-storage)、[R2 公開 bucket](https://developers.cloudflare.com/r2/buckets/public-buckets/)、[R2 CORS](https://developers.cloudflare.com/r2/buckets/cors/)、[R2 價格](https://developers.cloudflare.com/r2/pricing/)、[pmtiles JS CHANGELOG](https://github.com/protomaps/PMTiles/blob/main/js/CHANGELOG.md)。

## 開發前要實測

- R2 的 Range／CORS 設定是否能讓 pmtiles 正常讀取：網路調查結論為可行（2026-10-24，見上方「R2 設定」）；建立帳號、上傳圖資時再實際確認。網路上有說法指開通 R2 要綁付款方式，官方文件未寫明。
- Google 短網址（`maps.app.goo.gl`）能否在伺服器端展開並取出 `0x…:0x…` 識別碼：已測，可行（2026-10-24，見 [google-short-url-test.md](google-short-url-test.md)）；地點連結有代碼，清單與圖釘沒有。部署後要從 Vercel 實打一次，確認不會被導到同意頁面或限流。
