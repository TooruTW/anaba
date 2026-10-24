# 所有資料存取經由自建後端 API，登入自己做

取代 [ADR 0001](0001-supabase-rls-as-permission-boundary.md)。前端只呼叫 Next.js Route Handlers，後端以 `postgres` 套件直接寫 SQL 連資料庫；前端不碰 Supabase、不放任何金鑰。權限（只能動自己的足跡、到訪、筆記）與登入（密碼雜湊、session、防暴力破解）都在後端自己實作，Supabase 只當託管的 Postgres。

這麼做有兩個理由：練後端是這個 side project 的目標之一；權限和帳號不綁 Supabase，搬資料庫只要換連線字串。代價是安全全靠自己：漏寫一個權限檢查就會外洩資料，登入的資安細節也要自己顧。對策是讓足跡、到訪、筆記一律經過強制帶入目前使用者的資料存取函式，並用 Vitest 權限測試把關。資料表開 RLS 但不寫政策，擋掉 anon key 的存取。

## Considered Options

- 前端直連 Supabase，用 RLS 當權限邊界（ADR 0001）：程式碼最少，但練不到後端，權限和登入綁 Supabase。
- 寫入走後端、讀取直連：資料流分兩條，Supabase 的綁定仍然存在。
- 後端以使用者身分連線，保留 RLS 當安全網：多一層保險，但權限規則要寫兩份，搬資料庫時也要重寫。
- 後端轉呼叫 Supabase Auth：資安風險較低，但帳號綁 Supabase；也少練一塊。
- Server Actions：HTTP 被框架藏起來，練不到 API 設計。
- 獨立後端服務：學得最完整，但多一套部署，還要處理 CORS 和跨網域 cookie。
