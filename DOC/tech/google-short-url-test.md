# 技術驗證：伺服器端展開 Google Maps 短網址

日期：2026-10-24　階段：4. 技術可行性評估

## 結論

**可行，但有前提。** 用 Node 內建 `fetch`，不用瀏覽器、不用 API key，就能把 `maps.app.goo.gl` 展開，並從網址取出 `0x…:0x…` 店家代碼。

- 實際上**只要打一次短網址**（`redirect: 'manual'`），第一跳 302 的 `Location` 就已經有代碼，不必再去抓 google.com 的頁面。
- 只有「分享某個地點」的連結有代碼。分享「已儲存的清單」或「自己放的圖釘（只有座標）」時沒有代碼，照規則存展開後的網址即可。
- 測試是在台灣家用網路上跑的。正式環境在 Vercel（預設美國區）會不會遇到 Google 的同意頁面或擋爬，**還沒測**，見「沒驗證到的風險」。

## 測了什麼

- 連結來源：網路搜尋與 GitHub 程式碼搜尋找到的公開連結，共 38 條。沒有自己編造連結。
- 其中 11 條是台灣的地點（台北的雞排、餐廳、夜市攤、桃園機場、台中等），其他是日本、西班牙、義大利、印度等地的地點，以及清單、圖釘。
- 每條都用三種方式打：`redirect: 'manual'` 手動跟轉址並記錄每一跳、`redirect: 'follow'` 自動跟、加上瀏覽器的 User-Agent。另外對同一條短網址連續打 50 次，看會不會被限流。
- 環境：Node 24.16，Windows，台灣家用網路 IP。

## 結果

| 連結種類 | 數量 | 轉址 | 取到代碼 | 代碼在哪 |
| --- | --- | --- | --- | --- |
| 沒有後綴的地點分享（推測是電腦版或較新的 App） | 11（台灣 10） | 302 → 200 | 11／11 | `/maps/place/…/data=…!1s0x…:0x…` |
| 沒有後綴、舊格式 | 1 | 302 → 302 → 302 → 200 | 1／1 | `?q=…&ftid=0x…:0x…` |
| `?g_st=ic`（推測是 iOS App）地點 | 10（台灣 1） | 302 → 302 → 302 → 200 | 10／10 | `?q=…&ftid=0x…:0x…` |
| `?g_st=aw`（推測是 Android App）地點 | 1 | 302 → 200 | 1／1 | `/maps/place/…!1s0x…:0x…` |
| `?g_st=com` 地點 | 2 | 302 → 302 → 302 → 200 | 2／2 | `?q=…&ftid=0x…:0x…` |
| 自己放的圖釘（`ic`、`com` 各 1） | 2 | 同上 | 0／2 | 只有 `?q=緯度,經度` |
| 已儲存的清單 | 10 | 302 → 200 | 0／10 | `/maps/@/data=…!11m2!2s<清單 id>` |
| 不存在的短網址 | 1 | 404 | — | — |

- `redirect: 'follow'` 和手動跟轉址的最終網址 38 條全部相同。
- 加瀏覽器 User-Agent：轉址過程與代碼完全一樣，只有最後那頁 HTML 內容不同。
- 沒有遇到 `consent.google.com`、沒有回 200 再用 meta／JS 轉址的情況（只看到頁面裡給舊瀏覽器用的 `location.replace`，跟轉址無關）。
- 連續 50 次全部 302，約 18 秒，沒有被限流。
- `g_st` 拿掉後第一跳完全一樣，只是 `Location` 少了 `&g_st=…`。

## 轉址過程範例

台灣地點、沒有後綴：

```
302 https://maps.app.goo.gl/1r6HU113gRLyJZwn8
    Location: https://www.google.com/maps/place/180度C蜜酥雞排/@25.0398468,121.5014851,17z/data=!3m1!4b1!4m6!3m5!1s0x3442a9a7ed66f8bf:0xc7d12a1700086b2a!8m2!3d25.039842!4d121.50406!16s%2Fg%2F11xj4rmgy?entry=tts&g_ep=…&skid=…
200 （約 220 KB 的 HTML，不需要抓）
```

台灣地點、iOS 分享：

```
302 https://maps.app.goo.gl/BuqyC2jbTV2CVGCz8?g_st=ic
    Location: https://maps.google.com?q=100台北市中正區武昌街一段18號青平台「下一步」空間5樓&ftid=0x3442a9e2bdb767d1:0x54ac3f8da4fa8eb&hl=zh-Hant-TW&gl=tw&entry=gps&…&g_st=ic
302 https://maps.google.com/maps?q=…（同上）
302 https://www.google.com/maps?q=…（同上）
200
```

（網址裡的中文原本是百分比編碼，這裡為了好讀解碼過。）

## 取代碼的 regex

```js
/(0x[0-9a-f]+):(0x[0-9a-f]+)/i
```

兩種格式（`!1s0x…:0x…` 和 `ftid=0x…:0x…`）都抓得到，`:` 在網址裡沒有被編碼，不用先解碼。

## 要注意的地方

- **只打第一跳就好**：用 `redirect: 'manual'`，讀第一個回應的 `Location` 取代碼。跟到最後會多抓一頁 200 KB 以上的 HTML，沒有必要。第一跳沒有代碼（清單、圖釘）時也不用再跟，直接存 `Location`。
- **代碼長度不固定**：後半段可能比 16 位短（例如 `0x86161fd1fdd6a63`，前面的 0 被省略），當字串存，不要補零或轉數字比對。
- **網址帶分享者的語系**：`hl=en-RU&gl=ru` 這類參數是分享者手機的設定，跟我們的伺服器無關，存起來沒關係。
- **安全**：只接受 host 完全等於 `maps.app.goo.gl` 的 `https` 網址，`Location` 的 host 也要是 `google.com`／`www.google.com`／`maps.google.com` 才採用，避免後端被拿去打任意網址（SSRF）。fetch 要設逾時（例如 `AbortSignal.timeout(5000)`）。
- **失敗情況**：短網址不存在回 404；網路錯誤、逾時、非 3xx 都照規則存原短網址。

## 沒驗證到的風險

- **Vercel 的 IP**：測試是在台灣家用網路跑的，Vercel 預設在美國區。從雲端機房 IP 打 Google，有可能被導到 `consent.google.com`（歐洲較常見）、要求驗證或被限流，這次都沒遇到但也沒測。部署後要用正式環境實打一次。如果真的被導去同意頁面，原本的網址通常會編碼在 `continue` 參數裡（未驗證），可以先 `decodeURIComponent` 再找代碼；還是找不到就照規則存原短網址，不影響使用者。
- **格式會變**：這是 Google 沒有公開承諾的行為，轉址格式隨時可能改。代碼取不到時不要報錯，存網址就好。

## 測試用的腳本

測完已刪除。用法：`node expand.mjs [--ua] <短網址…>`。

```js
// node expand.mjs [--ua] <short links...>
const args = process.argv.slice(2);
const ua = args[0] === '--ua' && args.shift();
const headers = ua ? { 'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36' } : {};
const ID = /(0x[0-9a-f]+):(0x[0-9a-f]+)/i;

async function expand(url) {
  const hops = [];
  for (let i = 0; i < 10; i++) {
    const res = await fetch(url, { redirect: 'manual', headers });
    hops.push(`${res.status} ${url}`);
    const loc = res.headers.get('location');
    if (res.status >= 300 && res.status < 400 && loc) { url = new URL(loc, url).href; continue; }
    const body = res.status === 200 ? await res.text() : '';
    return { url, hops, status: res.status, consent: /consent\.google/.test(url), metaRedirect: /http-equiv="refresh"|location\.replace/i.test(body), bodyId: body.match(ID)?.[0] };
  }
  return { url, hops, status: 'too many hops' };
}

for (const link of args) {
  const m = await expand(link);
  const f = await fetch(link, { headers });
  const id = decodeURIComponent(m.url).match(ID)?.[0];
  console.log(JSON.stringify({ link, id: id ?? null, followSame: f.url === m.url, ...m }, null, 1));
}
```
