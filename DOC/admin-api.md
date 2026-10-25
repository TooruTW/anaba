# 管理 API 使用說明

日期：2026-10-25

給系統方（或代為操作的 AI）核對店家用。規則來源見 [情境 06](user_stories/mvp-user-scenarios-detail.md#06系統方核對店家)，資料上的動作見 [data-model.md](tech/data-model.md#核對情境-06在資料上的動作)。

## 驗證

- 每個請求帶 `Authorization: Bearer <ADMIN_TOKEN>`，token 放在環境變數 `ADMIN_TOKEN`。沒帶或不符回 401。
- 不檢查 `Origin`，也不需要登入 session。
- ponytail：單一共用 token，外流就得換；與邀請碼同等級。

以下範例的 `$BASE` 為網站網址（如 `https://<專案>.vercel.app`）。

## `GET /api/admin/stores/unverified`

列出未核對、未被取代的店家，依建立時間排序（舊的在前）。不含任何使用者資料。

```sh
curl -H "Authorization: Bearer $ADMIN_TOKEN" "$BASE/api/admin/stores/unverified"
```

```json
[
  { "id": "…", "name": "阿明麵館", "lat": 22.63, "lng": 120.30,
    "googleUrl": "https://www.google.com/maps/place/…", "googleCode": "0x…:0x…",
    "createdAt": "2026-10-25T04:12:00Z" }
]
```

## `POST /api/admin/verify`

把一或多家舊店家核對成一筆新的已核對店家。單家修正與多家合併都用這支。

```sh
curl -X POST -H "Authorization: Bearer $ADMIN_TOKEN" -H "Content-Type: application/json" \
  -d '{"oldStoreIds":["…","…"],"store":{"name":"阿明麵館","lat":22.63,"lng":120.30,"googleUrl":"https://maps.app.goo.gl/…"}}' \
  "$BASE/api/admin/verify"
```

- `oldStoreIds`：至少 1 個，不可重複。
- `store`：新店家資料，欄位規則同 [api.md](tech/api.md#欄位驗證)；`googleUrl` 一樣會展開並取出代碼。

回應 201 `{ "storeId": "<新店家 id>" }`。

整個在同一個交易內完成，中途失敗資料完全不變：

1. 建立新店家，標為已核對。
2. 舊店家，以及原本指向舊店家的已被取代店家，都改為指向新店家。
3. 舊店家的到訪全部改記到新店家，筆數不變。
4. 回憶：同一人在舊店家中只要有一家不是回憶，就不保留回憶；全部都是回憶時保留一筆，時間取最晚的。

| 錯誤 | 時機 |
| --- | --- |
| 400 | 欄位不合規則 |
| 401 | token 沒帶或不符 |
| 404 | 某個舊店家 ID 不存在 |
| 409 | 某個舊店家已被取代（應改用取代它的店家 ID） |

## 核對步驟建議

1. 列出未核對店家。
2. 依店名、座標、Google 連結判斷哪些是同一間實際店家；不確定就打開 Google 連結確認。
3. 每組呼叫一次 `verify`，店名與位置以 Google 地圖上的為準。
4. 已核對的店家之後發現有誤，也可以再放進 `oldStoreIds` 核對一次。
