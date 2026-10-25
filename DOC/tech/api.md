# API 設計

日期：2026-10-25　階段：6. 最小設計

前端所有資料讀寫都走這裡的 `/api`（瀏覽器端 `fetch`），見 [ADR 0002](../adr/0002-own-backend-api-and-auth.md)。資料表見 [data-model.md](data-model.md)，管理 API 另見 [admin-api.md](../admin-api.md)。

## 共通規則

- **登入**：除了 `auth/register`、`auth/login`、`health`，都要有效 session，否則 401。頁面導向登入頁由 middleware 只看 cookie 是否存在；真正的檢查在 API，前端收到 401 就導向登入頁。
- **CSRF**：非 GET 請求的 `Origin` 不是自己網域時回 403。
- **權限**：別人的到訪、別人的私房店一律 404，不回 403，不透露存在與否。
- **格式**：請求與回應都是 JSON；欄位用 camelCase。座標一律 `lat`、`lng`。
- **選項值**：和資料庫相同（評價、價位、寵物是數字，種類、付款是英文代碼陣列），中文由前端對照。
- **日期**：到訪日期由後端換算成台灣時間，回傳 `YYYY-MM-DD`；其他時間回傳 ISO 8601（UTC）。
- **亮度**：只回傳等級 1～3，不回傳分數。
- **不分頁**：搜尋最多 20 筆，其他清單全部回傳。ponytail：試用規模一個人頂多幾百家；變慢再加分頁。

### 錯誤

回應 `{ "error": "中文訊息" }`，前端直接顯示。

| 狀態碼 | 時機 |
| --- | --- |
| 400 | 欄位不合規則 |
| 401 | 沒登入或 session 失效 |
| 403 | `Origin` 不對 |
| 404 | 不存在，或是別人的資料 |
| 409 | 店家在回憶中（或不在回憶中）；新增店家有相似候選 |
| 429 | 登入嘗試次數過多 |

### 欄位驗證

自己寫驗證函式，不用 zod。前端也做同樣的檢查，但以後端為準。

| 欄位 | 規則 |
| --- | --- |
| `email` | 含 `@`，存小寫並去頭尾空白 |
| `password` | 至少 8 字元 |
| 店名 `name` | 去頭尾空白後 1～50 字 |
| `lat`／`lng` | 數字，`-90～90`／`-180～180` |
| `googleUrl` | 可空；開頭須為 `https://maps.app.goo.gl/`、`https://www.google.com/maps`、`https://maps.google.com`，否則「請貼 Google 地圖的分享連結」 |
| `rating` | 必填，1～3 |
| `note` | 可空，20 字以內（以字元計，`[...note].length`） |
| `kinds` | 可空；`restaurant`、`snack`、`cafe`、`dessert`、`bar`、`other`，不可重複 |
| `price` | 可空，1～5 |
| `pet` | 可空，1～3 |
| `payments` | 可空；`cash`、`card`、`mobile`、`other`，不可重複 |

空陣列存成 null（＝不清楚）。

## 端點

| 用途 | 方法與路徑 |
| --- | --- |
| 註冊 | `POST /api/auth/register` |
| 登入 | `POST /api/auth/login` |
| 登出 | `POST /api/auth/logout` |
| 修改密碼 | `PUT /api/auth/password` |
| 搜尋店家 | `GET /api/stores?q=&lat=&lng=` |
| 店家頁 | `GET /api/stores/:id` |
| 新增到訪（可同時新增店家） | `POST /api/visits` |
| 刪除到訪 | `DELETE /api/visits/:id` |
| 我的私房店（地圖、清單） | `GET /api/my-stores?bbox=&q=` |
| 回憶清單 | `GET /api/memories?q=` |
| 成為回憶 | `POST /api/stores/:id/memory` |
| 復活 | `DELETE /api/stores/:id/memory` |
| 永久刪除 | `DELETE /api/stores/:id/visits` |
| 健康檢查 | `GET /api/health` |

### 登入相關

**`POST /api/auth/register`**：`{ email, password, inviteCode }` → 201，寫入 session cookie。

- 邀請碼不符 400「邀請碼錯誤」；email 已註冊 400「此 email 已註冊」。ponytail：會透露 email 是否註冊過，試用期只有受邀者能走到這步，接受；正式開放時改掉。
- 「確認密碼」只在前端比對。

**`POST /api/auth/login`**：`{ email, password }` → 204，寫入 session cookie。

- 帳號不存在或密碼錯誤：401「email 或密碼錯誤」。
- 鎖定中：429「嘗試次數過多，請 15 分鐘後再試」（不論帳號是否存在）。

**`POST /api/auth/logout`** → 204，刪除這個 session 並清掉 cookie。

**`PUT /api/auth/password`**：`{ oldPassword, newPassword }` → 204，刪除這個使用者其他的 session。舊密碼錯誤 400「舊密碼錯誤」。

### `GET /api/stores?q=&lat=&lng=`

搜尋共用店家庫，排除已被取代的店家。`q` 必填（去空白後至少 1 字），用 pg_trgm 比對店名。帶 `lat`、`lng` 依距離排序，否則依店名排序；定位不寫入資料庫。

```json
[
  { "id": "…", "name": "阿明麵館", "lat": 22.63, "lng": 120.30, "mine": "recorded" }
]
```

`mine`：`null`（沒到訪）、`"recorded"`（已記錄）、`"memory"`（在回憶中）。不回傳建立者或記錄人數。

### `GET /api/stores/:id`

```json
{
  "store": {
    "id": "…", "name": "阿明麵館", "lat": 22.63, "lng": 120.30,
    "googleUrl": "https://www.google.com/maps/place/…", "verified": false
  },
  "mine": {
    "memory": false,
    "days": 3,
    "latestRating": 3,
    "extras": { "kinds": ["snack"], "price": 1, "pet": null, "payments": ["cash"] },
    "visits": [
      { "id": "…", "date": "2026-10-25", "rating": 3, "note": "乾麵必點",
        "kinds": ["snack"], "price": 1, "pet": null, "payments": ["cash"] }
    ]
  }
}
```

- 店家已被取代：回 `{ "replacedBy": "<新店家 id>" }`，前端改開新店家頁。
- 沒到訪過：`mine` 為 `null`，前端進填寫到訪（情境 01 步驟 3a）。
- `extras` 每項取最近一次有填的值，從沒填過為 `null`（顯示「不清楚」）。
- `visits` 新的在上；永久刪除的 N 筆即 `visits.length`。

### `POST /api/visits`

到訪欄位：`{ rating, note?, kinds?, price?, pet?, payments? }`，再加下列其一：

- 既有店家：`storeId`。店家已被取代時改記到取代它的店家。
- 新店家：`store: { name, lat, lng, googleUrl? }`，可加 `confirmed: true`。

新店家流程，都在同一個交易內：

1. 有 `googleUrl` 且是短網址就展開，取出店家代碼（規則見 [stack.md](stack.md)「Google 連結」）。
2. 沒帶 `confirmed` 時查重：2 公里內 pg_trgm 相似度 ≥ 0.3，或店家代碼相同，排除已被取代的店家，最多 5 家。有候選就回 409，不寫入：

   ```json
   { "error": "是不是這幾家？", "candidates": [ { "id": "…", "name": "阿明麵店", "lat": 22.63, "lng": 120.30, "mine": null } ] }
   ```

   使用者選了某家：改用該 `storeId` 送出；選「都不是」：帶 `confirmed: true` 再送一次。
3. 建立店家與到訪。

回應 201 `{ "storeId": "…", "visitId": "…" }`。`created_at` 由後端寫入，前端傳來的日期一律忽略。店家在回憶中：409「此店在回憶中，請先復活」。

### `DELETE /api/visits/:id`

→ 204。店家在回憶中 409「此店在回憶中，請先復活」。確認訊息（是否最後一筆）由前端依店家頁的到訪數決定。

### `GET /api/my-stores?bbox=&q=`

自己非回憶的私房店，依最近一次到訪排序（新的在上）。

- 地圖：帶 `bbox=minLng,minLat,maxLng,maxLat`。前端把畫面範圍往四邊各加大 50% 再送；地圖 `moveend` 後，畫面超出上次撈過的範圍才重撈。
- 清單：不帶 `bbox`，回傳全部；可帶 `q` 篩店名。

```json
{
  "total": 12,
  "stores": [
    { "id": "…", "name": "阿明麵館", "lat": 22.63, "lng": 120.30,
      "level": 2, "price": 1, "lastVisitAt": "2026-10-25T04:12:00Z" }
  ]
}
```

- `total`：全部非回憶私房店數，不受 `bbox`、`q` 影響。為 0 時地圖提示「記下你的第一家店」。
- `price`：自己最近一次有填的價位，沒填過為 `null`（預覽卡不顯示這行）。

### `GET /api/memories?q=`

依成為回憶的時間排序（新的在上），可帶 `q` 篩店名。

```json
[ { "id": "…", "name": "阿明麵館", "days": 3, "memorizedAt": "2026-10-25T04:12:00Z" } ]
```

### 回憶

不是自己的私房店一律 404。

- **`POST /api/stores/:id/memory`**：成為回憶 → 204；已是回憶也回 204。
- **`DELETE /api/stores/:id/memory`**：復活 → 204；不是回憶也回 204。
- **`DELETE /api/stores/:id/visits`**：永久刪除，刪掉自己在此店的全部到訪與回憶 → 204。不是回憶時 409「請先成為回憶」。

### `GET /api/health`

不需登入，實際查資料庫（`select 1`）→ 200 `{ "ok": true }`。給外部排程每週打一次，避免 Supabase 暫停。
