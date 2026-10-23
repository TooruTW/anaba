# 技術選型

日期：2026-10-23　階段：4. 技術可行性評估／6. 最小設計

| 項目 | 選擇 | 理由／備註 |
| --- | --- | --- |
| 平台 | 手機優先的 PWA（只加 manifest，不做 service worker 與離線） | 記錄多在店裡用手機；免上架。未來拍照用 `<input type="file" accept="image/*" capture="environment">` 即可，不受影響 |
| 前端 | Next.js（App Router）＋ TypeScript ＋ Tailwind，不加 UI 元件庫 | 技術驗證已用 Next.js；API route 可處理 Google 短網址展開 |
| 地圖 | MapLibre GL JS ＋ pmtiles，自抽 Protomaps 台灣圖資 | 見 [custom-map-prototype.md](custom-map-prototype.md)；只在 client 端執行 |
| 後端／資料庫／登入 | Supabase 免費方案：Postgres、Auth（email＋密碼）、RLS、PostGIS、pg_trgm | 見 [ADR 0001](../adr/0001-supabase-rls-as-permission-boundary.md) |
| 網站部署 | Vercel Hobby | 推 git 自動部署；Hobby 不可商用，收費前要換方案 |
| 圖資放置 | Cloudflare R2 | 流量免費；要設定 CORS 允許 `Range` header，並開放 `Content-Range`、`ETag` |
| 測試 | Vitest（計數、亮度、RLS 權限）＋ 一條 Playwright 主流程（註冊 → 新增店家 → 到訪 → 地圖出現篝火） | 只測錯了會出事、又不易發現的規則 |

## 規則

- **Auth**：關閉 email 驗證信，系統完全不寄信。忘記密碼由系統方在 Supabase 後台手動重設。
- **資料庫結構**：一律用 Supabase CLI 的 migration 檔管理並放進 git，不在後台手動改。
- **Design system 先行**：任何畫面開發前，先定好顏色、字級、間距與基本元件，寫成 Tailwind theme，並做一頁元件總覽。畫面只能使用 design system 定義的值。
- **網域**：先用 Vercel 免費網址。

## 已知限制

- Supabase 免費方案連續 7 天無使用會暫停專案，需手動恢復；造成困擾時升級 Pro（約每月 25 美元）。
- ponytail: 圖資以矩形範圍抽出，包含福建沿岸。有人反映再改用 `--region` 給台灣、澎湖、金門、馬祖的多邊形。
- 換資料庫時，資料（標準 Postgres）好搬；Auth 與 RLS 權限規則需要重寫。

## 開發前要實測

- R2 的 Range／CORS 設定是否能讓 pmtiles 正常讀取。
- Google 短網址（`maps.app.goo.gl`）能否在伺服器端展開並取出 `0x…:0x…` 識別碼。
