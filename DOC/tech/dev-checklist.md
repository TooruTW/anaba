# 開發清單

日期：2026-10-29　階段：6. 最小設計與開發清單

第 7 階段照順序做，前一項完成才開始下一項。順序是先打地基（環境、資料庫、登入），再照使用者情境往上蓋，最後做招牌時刻。每項的「完成」對應 [mvp-acceptance.md](../user_stories/mvp-acceptance.md) 的情境；標 `[自動]` 的條件在該項就寫好測試，不留到第 8 階段。

規格來源：技術規則見 [stack.md](stack.md)，資料表見 [data-model.md](data-model.md)，API 見 [api.md](api.md) 與 [admin-api.md](../admin-api.md)，顏色與元件見 [design-system.md](design-system.md)，畫面見 stack.md「畫面風格」與 `output/prototypes/`。

| # | 工作 | 內容 | 完成 |
| --- | --- | --- | --- |
| 1 | 帳號與環境（手動） | 建 Supabase 專案並開 PostGIS、pg_trgm；建 R2 bucket、上傳台灣 pmtiles、設 CORS；建 Vercel 專案接 git；環境變數：資料庫連線字串、邀請碼、管理 token、聯絡信箱、圖資網址 | 瀏覽器以 Range 讀得到 R2 上的 pmtiles（stack.md「開發前要實測」） |
| 2 | 專案骨架 | Next.js（App Router）＋ TypeScript ＋ Tailwind、`postgres` 套件、Vitest、Supabase CLI migration；`GET /api/health`；PWA manifest | 推 git 後 Vercel 部署成功，`/api/health` 回 200 |
| 3 | Design system | 把 design-system.md 寫成 Tailwind theme，字體依字切檔載入；做元件總覽頁（按鈕、選項、評價、輸入框、標籤、清單列、預覽卡、確認框、提示與錯誤訊息） | 元件總覽頁通過「遮掉 logo，看得出是這個 App 嗎？」 |
| 4 | 資料表 | 依 data-model.md 寫 migration：users、sessions、login_failures、stores、visits、memories；全部開 RLS 不寫政策 | migration 可在空資料庫從頭跑完 |
| 5 | 登入後端 | scrypt 雜湊、資料庫 session（只存 SHA-256、一個月滑動期限）、login_failures 鎖定、非 GET 檢查 `Origin`、未登入導向登入頁的 middleware；註冊、登入、登出、修改密碼四個 API；`npm run reset-password` 腳本 | 情境 00 的 `[自動]` 條件測試通過 |
| 6 | 登入畫面 | 登入與註冊同一張表單（`login.html` 方案 C）、修改密碼頁、個人選單的登出 | 情境 00 手動條件在手機上通過 |
| 7 | 資料存取函式與計數 | 到訪與回憶一律經過強制帶入目前使用者的函式；來訪天數（台灣時間）、亮度分數與等級 | 情境 00 的 A／B 權限測試、情境 01 台灣時間、情境 02 計數與亮度的 `[自動]` 條件通過 |
| 8 | 地圖主畫面 | MapLibre ＋ pmtiles 黑色底圖；起始位置（定位或高雄火車站）；`GET /api/my-stores?bbox=`；篝火元件三級亮度；預覽卡；角落按鈕與個人選單（`map-main.html` 方案 B）；沒有私房店時的提示 | 登入後看到自己的空地圖與「記下你的第一家店」 |
| 9 | 記錄店家與到訪 | 搜尋店家 API 與選店畫面；新增店家兩步驟（`new-store.html` 方案 B）；到訪表單；「是不是這幾家？」（名稱相近、2 公里內、Google 代碼相同）；Google 短網址展開；`POST /api/visits` | 情境 01 全部通過；Playwright 主流程（註冊 → 新增店家 → 到訪 → 地圖出現篝火）通過 |
| 10 | 店家頁、再次到訪、刪除到訪 | `GET /api/stores/:id`、店家頁、新增到訪、`DELETE /api/visits/:id` 與兩種確認訊息 | 情境 03、04 通過；情境 02 預覽卡與店家頁條件通過 |
| 11 | 我的私房店清單 | `GET /api/my-stores?q=`；清單、搜尋、空狀態（`my-stores.html` 方案 A） | 情境 02 剩餘條件通過 |
| 12 | 回憶 | 成為回憶、復活、永久刪除三個 API（回憶中新增或刪除到訪回 409）；回憶清單（同私房店清單版型）；回憶頁（淺灰燼） | 情境 05 通過 |
| 13 | 管理 API | 列出未核對店家、核對（單一 transaction）；已被取代的店家搜尋不到、店家頁導到新店家 | 情境 06 通過 |
| 14 | 招牌時刻 | 開啟畫面（火星上升，寫在 HTML 裡）、一般載入、篝火晃動、送出到訪的點燃動畫、空狀態的柴；`prefers-reduced-motion` | 開啟畫面隨時被打斷都好看，與 PWA 啟動畫面相接不閃 |
| 15 | 上線前 | 每週打 `/api/health` 的外部排程；從 Vercel 實打一次 Google 短網址展開；檢查瀏覽器載入的程式碼與請求中沒有 Supabase 網址或金鑰 | 可以進第 8 階段逐項驗收 |
