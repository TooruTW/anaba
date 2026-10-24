# Supabase＋RLS 作為權限邊界

狀態：已被 [ADR 0002](0002-own-backend-api-and-auth.md) 取代（2026-10-24）。

足跡、到訪、筆記只有本人看得到，這條規則用 Postgres 的 Row Level Security 在資料庫層級強制，前端直接以使用者身分查 Supabase，不另寫一層後端 API 檢查權限。這樣前端寫錯也不會外洩資料，並省掉自建 API 與登入系統；代價是綁定 Supabase Auth 與 RLS 寫法，日後換資料庫時資料可直接搬，但登入與權限規則要重寫。

## Considered Options

- Firebase：非 SQL，相似店名比對與距離排序不好做。
- 自架資料庫＋自寫登入與 API 權限檢查：程式碼多，權限散在各個 API，容易漏。
