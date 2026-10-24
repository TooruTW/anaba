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
| 圖資放置 | Cloudflare R2 | 流量免費；要設定 CORS 允許 `Range` header，並開放 `Content-Range`、`ETag` |
| 測試 | Vitest（計數、亮度、後端權限）＋ 一條 Playwright 主流程（註冊 → 新增店家 → 到訪 → 地圖出現篝火） | 只測錯了會出事、又不易發現的規則 |

## 規則

- **權限**：足跡、到訪、筆記一律經過強制帶入目前使用者的資料存取函式，route 裡不直接查這些資料表；存取別人的資料一律回 404。資料表開 RLS 但不寫政策，只有後端的 service 連線能存取。
- **密碼**：`crypto.scrypt` 加每人隨機 salt，比對用 `crypto.timingSafeEqual`。
- **Session**：32 bytes 隨機 token，放在 httpOnly、Secure、SameSite=Lax 的 cookie；資料庫只存 token 的 SHA-256。一個月有效，每次使用往後延；登出、重設密碼時刪除，修改密碼時刪除其他裝置的 session。
- **防暴力破解**：同一 email 連續登入失敗 10 次鎖 15 分鐘；錯誤訊息一律「email 或密碼錯誤」。ponytail：只依 email 計數，換 email 試不會被擋；正式開放時加 IP 限制。
- **CSRF**：非 GET 請求檢查 `Origin` 必須是自己的網域，不符回 403。
- **寄信**：系統完全不寄信。忘記密碼用本機腳本 `npm run reset-password -- <email>` 產生臨時密碼並刪掉該使用者所有 session，系統方手動回信。有自有網域後改接 Resend。
- **時間**：資料庫一律存 UTC（`timestamptz`），後端讀出時換算成 `Asia/Taipei`；到訪時間由後端寫入，不收前端日期。
- **Google 連結**：後端只展開 `maps.app.goo.gl`，存展開後的完整網址並取出店家代碼；展開失敗就存原短網址。
- **資料庫結構**：一律用 Supabase CLI 的 migration 檔管理並放進 git，不在後台手動改。
- **Design system 先行**：任何畫面開發前，先定好顏色、字級、間距與基本元件，寫成 Tailwind theme，並做一頁元件總覽。畫面只能使用 design system 定義的值。
- **網域**：先用 Vercel 免費網址。

## 已知限制

- Supabase 免費方案連續 7 天無使用會暫停專案，需手動恢復；造成困擾時升級 Pro（約每月 25 美元）。
- ponytail: 圖資以矩形範圍抽出，包含福建沿岸。有人反映再改用 `--region` 給台灣、澎湖、金門、馬祖的多邊形。
- 換資料庫時，資料與帳號（標準 Postgres）直接搬，後端只換連線字串。

## 開發前要實測

- R2 的 Range／CORS 設定是否能讓 pmtiles 正常讀取。
- Google 短網址（`maps.app.goo.gl`）能否在伺服器端展開並取出 `0x…:0x…` 識別碼。
