# 技術驗證：自訂台灣地圖（MapLibre + Protomaps）

日期：2026-10-23　階段：4. 技術可行性評估

## 結論

不靠 Google Maps，也能做出完全自訂樣式的台灣地圖，並且可以下 marker。整套不用 API key、不按次計費，成本只有放圖資檔的主機流量。

驗證過的效果（demo 已刪除，style 見下方「地圖樣式」）：

- 只顯示台灣陸地、海、道路，其他圖層一律不畫。
- 黑色陸地、深灰色海、橘色道路，可以對應 ideas.md 的「黑暗地圖」構想。
- 大條馬路的路名、縣市界、鄉鎮市區界（只有線，沒有名稱）。
- 用座標下 marker，或點地圖取得座標再下 marker。

## 用了什麼、來源

| 東西 | 版本 | 來源 | 授權／費用 |
| --- | --- | --- | --- |
| MapLibre GL JS（畫地圖） | 6.13.0 | npm `maplibre-gl` | BSD-3，免費 |
| pmtiles JS（讓瀏覽器讀 .pmtiles） | 4.5.0 | npm `pmtiles` | BSD-3，免費 |
| go-pmtiles CLI（從全球圖資抽出台灣） | 1.31.2 | github.com/protomaps/go-pmtiles/releases（Windows_x86_64.zip） | BSD-3，免費 |
| 圖資：Protomaps OSM 每日 build | 20261023 | `https://build.protomaps.com/20261023.pmtiles`（清單：maps.protomaps.com/builds） | 資料是 OpenStreetMap，ODbL |
| 字型（只用到英文字母） | — | `https://protomaps.github.io/basemaps-assets/fonts/{fontstack}/{range}.pbf` | 免費 |

授權欄是依各專案的一般授權條款整理，沒有核對最新條文。要商用前再看一次 openstreetmap.org/copyright。

## 做法

1. 抽圖資：

   ```
   pmtiles extract https://build.protomaps.com/YYYYMMDD.pmtiles taiwan.pmtiles --bbox=118.1,21.8,122.1,26.4 --maxzoom=14
   ```

   約 30 秒，產出 124 MB。只會下載需要的部分，不會下載整個全球檔。

2. 把 `taiwan.pmtiles` 當成一般靜態檔放上去。MapLibre 透過 `pmtiles://` protocol 用 HTTP Range request 只讀需要的圖磚，不需要圖磚伺服器。
3. 地圖樣式（style）只引用想要的圖層，其他圖層不寫，就不會畫出來。

## 圖資觀察（實際查詢 taiwan.pmtiles 得到）

- **陸地**：`earth` 圖層（polygon）。海沒有圖層，直接用 background 顏色當海。
- **道路**：`roads` 圖層，用 `kind` 分類：`highway`（國道、快速道路）、`major_road`、`minor_road`、`path`、`rail`、`other`、`aeroway`。
  - 有 `name`、`name:en`、`name:zh-Hant`；國道另有 `ref`（編號）。
  - `kind` 跟「是不是大馬路」對不太上。在台北市區取樣：`major_road` 混有「X街」和「XX巷」，`minor_road` 也有松仁路、興德路這類「X路」。
  - 隧道、匝道、交流道是獨立路段，有自己的名稱（象山隧道、XX入口匝道），依路名篩選時這些路段會被濾掉，路線會斷開。
  - 最後採用的規則：`highway` 加上 `major_road`，排除名稱含「巷」或「弄」的路段。路線不會斷，也沒有巷弄。
- **行政界線**：`boundaries` 圖層，`kind_detail` 是 OSM 的 admin_level。
  - `4` = 縣市（z7 左右開始出現）；`7` = 鄉鎮市區（要放大到 z12 左右才有）。
  - `8` 也有，但沒確認是哪一級。
  - 只有線，**沒有名稱也沒有多邊形**。如果要做「依縣市篩選」或「判斷店家在哪一區」，要另外找資料，候選是內政部國土測繪中心在政府資料開放平臺上的「直轄市、縣市界線」「鄉鎮市區界線」。
- bbox 是矩形，所以會包含福建沿岸的陸地和道路。如果只想要台灣，要加遮罩，或抽圖資時改用 `--region` 給台灣的多邊形範圍。

## 要注意的地方

- **放圖資的地方要支援 Range request**。放在不同網域（例如 R2）時，還要設定 CORS，允許 `Range` header 並開放 `Content-Range`、`ETag`。以上都還沒在 Next 或 R2 上實測。
- **在 Next.js 裡只能在 client 端執行**：MapLibre 需要 `window` 和 WebGL，要放在 `"use client"` 元件裡，在 `useEffect` 中建立地圖，並引入 `maplibre-gl/dist/maplibre-gl.css`。MapLibre 6.x 只提供 ES module，沒有 default export，要寫成 `import * as maplibregl from "maplibre-gl"`。
- **中文路名不需要中文字型檔**：style 的 `glyphs` 只提供英文字母，中文由 MapLibre 用電腦本機字型畫（`localIdeographFontFamily`），所以不同電腦上字體會不同。
- **不要把 build.protomaps.com 當正式環境的圖源**。那裡是給人下載用的；正式環境要把抽出來的檔案放在自己的主機或物件儲存（例如 Cloudflare R2、GitHub Pages）。
- **OSM 授權**：一定要顯示「© OpenStreetMap contributors」。修改 OSM 資料本身後再對外散布時，那份資料也要用 ODbL 開放；單純拿來畫地圖顯示不需要開放程式碼。
- **圖資更新**：每日 build 是一份快照，要更新只能重抽一次。路名、道路會跟著 OSM 的編輯變動。
- **marker**：`new maplibregl.Marker({ element })` 可以放任何 HTML、圖片或 SVG，`anchor: "bottom"` 讓圖釘尖端對準座標。點地圖取得座標用 `map.on("click", e => e.lngLat)`。marker 是 DOM 元素，數量到上千個會變慢，到時候要改用 symbol 圖層（`map.addImage` 加上 symbol layer）。

## 地圖樣式

驗證完成時的設定。`url` 要換成實際放圖資的位置。

```js
import * as maplibregl from "maplibre-gl";
import { Protocol } from "pmtiles";
maplibregl.addProtocol("pmtiles", new Protocol().tile);

// Only highway + major_road, minus 巷/弄 segments that OSM tags as major_road.
const name = ["coalesce", ["get", "name"], ""];
const bigRoad = ["all", ["!", ["in", "巷", name]], ["!", ["in", "弄", name]]];
const road = (kind, color, minzoom, widths) => ({
  id: kind, type: "line", source: "tw", "source-layer": "roads", minzoom,
  filter: ["all", ["==", ["get", "kind"], kind], bigRoad],
  layout: { "line-cap": "round", "line-join": "round" },
  paint: { "line-color": color, "line-width": ["interpolate", ["exponential", 1.6], ["zoom"], ...widths] },
});

const map = new maplibregl.Map({
  container: "map", center: [120.9, 23.7], zoom: 7,
  style: {
    version: 8,
    glyphs: "https://protomaps.github.io/basemaps-assets/fonts/{fontstack}/{range}.pbf",
    sources: {
      tw: {
        type: "vector",
        url: "pmtiles://https://<圖資位置>/taiwan.pmtiles",
        attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      },
    },
    layers: [
      { id: "sea", type: "background", paint: { "background-color": "#2b2b2b" } },
      { id: "earth", type: "fill", source: "tw", "source-layer": "earth", paint: { "fill-color": "#000000" } },
      road("major_road", "#e07b24", 8, [8, 0.4, 18, 12]),
      road("highway", "#ff8c1a", 5, [5, 0.6, 18, 16]),
      { id: "district_border", type: "line", source: "tw", "source-layer": "boundaries", filter: ["==", ["get", "kind_detail"], 7],
        paint: { "line-color": "#c0c0c0", "line-width": 1.2, "line-dasharray": [3, 2] } },
      { id: "county_border", type: "line", source: "tw", "source-layer": "boundaries", filter: ["==", ["get", "kind_detail"], 4],
        paint: { "line-color": "#ffffff", "line-width": ["interpolate", ["linear"], ["zoom"], 7, 1, 14, 2.5] } },
      { id: "road_names", type: "symbol", source: "tw", "source-layer": "roads", minzoom: 13,
        filter: ["all", ["in", ["get", "kind"], ["literal", ["highway", "major_road"]]], bigRoad],
        layout: { "symbol-placement": "line", "text-field": ["get", "name"], "text-font": ["Noto Sans Regular"], "text-size": 13 },
        paint: { "text-color": "#ffd8a8", "text-halo-color": "#000000", "text-halo-width": 1.5 } },
    ],
  },
});
```

## 還沒驗證／待決定

- 正式環境要把 124 MB 的圖資放在哪裡，以及流量成本是多少。
- 要不要排除福建沿岸。
- 縣市或區的名稱、多邊形要用政府開放資料補，還沒有實際下載確認格式和授權。
- **已決定（2026-10-23）**：Google Maps Platform 條款禁止把 Geocoding 結果用在非 Google 地圖上，因此不用 Google Geocoding。後續再改為不填地址：店家位置由使用者在地圖上點大概位置（`map.on("click")` 取座標），不用任何地址轉座標服務；精確位置與導航由使用者貼的 Google Maps 連結處理。


## 地圖氛圍與配色實驗（2026-10-25）

以高雄車站周邊的黑底、橘色道路、白色路名示意圖，試作五種濾鏡。這是靜態圖片上的視覺實驗，尚未整合進 MapLibre；底圖為 AI 示意圖，不能作導航資料。

### 五種氛圍

色碼中的末兩位是 alpha；「識別色」是選項旁的小色點，不是整張地圖的底色。

| 氛圍 | 視覺方向 | 識別色 | 底圖 filter | 染色層（screen 混色） |
| --- | --- | --- | --- | --- |
| 01 靜夜 | 低飽和、沉靜灰綠 | `#a0b89e` | `saturate(.38) brightness(.70)` | `#244c48` |
| 02 晨霧 | 柔和留白、漂浮霧層 | `#c8d9d3` | `saturate(.25) brightness(.65)` | `#405457` |
| 03 月光 | 冷藍微光、夜間漫遊 | `#9daedb` | `saturate(.15) brightness(.68) hue-rotate(155deg)` | `linear-gradient(135deg,#263b78aa,#192c3b33)` |
| 04 暖暮 | 琥珀薄霧、溫柔餘暉 | `#d6b388` | `saturate(.55) brightness(.78) sepia(.2)` | `linear-gradient(145deg,#9b67415c,#4a343088)` |
| 05 探路 | 中央清晰、外圍青灰深霧 | `#8ebfba` | `saturate(.55) brightness(.85)` | `#24434188` |

其他四種氛圍的霧層背景：

```css
/* 靜夜 */
background: radial-gradient(ellipse at 30% 30%,#7cae9825,transparent 60%);
/* 晨霧 */
background: radial-gradient(ellipse at 22% 40%,#d4e5ddd9,transparent 48%),
            radial-gradient(ellipse at 85% 70%,#a5bdc5c7,transparent 55%),
            linear-gradient(125deg,#a3bdc15c,transparent 60%);
/* 月光 */
background: radial-gradient(ellipse at 75% 15%,#adbfe399,transparent 50%),
            radial-gradient(ellipse at 0% 95%,#435e8f88,transparent 50%);
/* 暖暮 */
background: radial-gradient(ellipse at 10% 20%,#dec39a88,transparent 55%),
            radial-gradient(ellipse at 100% 90%,#8b667c66,transparent 60%);
```

這四種霧層 `inset:-20%`、`filter:blur(25px)`，以 26 秒 `ease-in-out infinite alternate` 在 `translate(-3%,-2%) rotate(-3deg)` 與 `translate(5%,4%) rotate(5deg)` 間流動。一般暗角是 `radial-gradient(ellipse at 50% 46%,transparent 20%,#020c16dc 100%)`；暖暮改為 `radial-gradient(ellipse at 30% 30%,transparent,#1d1119c9)`。

### 探路：固定在正中央揭霧

最後確認的調整：揭霧中心固定在地圖容器的 `50% 50%`。移除滑鼠跟隨、手指拖曳追蹤與 pointer capture，不攔截原生觸控捲動。探路霧層本身沒有漂移動畫。

疊放順序為底圖、染色、霧、暗角；所有覆蓋層使用 `pointer-events:none`。以下是可重建此效果的核心樣式：

```css
.map {
  position: relative;
  isolation: isolate;
  overflow: hidden;
  background: #000 url('map.png') center / contain no-repeat;
  --power: .7;
}
.map img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: contain;
  filter: saturate(.55) brightness(.85);
  opacity: var(--power);
}
.layer {
  position: absolute;
  inset: 0;
  pointer-events: none;
  opacity: var(--power);
}
.tint {
  mix-blend-mode: screen;
  background: #24434188;
}
.fog {
  filter: none;
  animation: none;
  background: radial-gradient(circle at 50% 50%,
    transparent 5%, #899f9d44 19%, #263c40eb 42%, #13242af5 72%);
}
.shade {
  background: radial-gradient(circle at 50% 50%,
    transparent 8%, #030b1344 40%, #020a13bb);
}
```

底圖同時作為容器背景與上層圖片；強度調整的是上層濾鏡圖片及覆蓋層的 opacity（0–1，預設 0.7），所以強度為 0 時仍看得到原圖。比較原圖時隱藏覆蓋層，並把圖片改為 `filter:none;opacity:1`。其他模式可暫停霧層動畫；減少動態效果偏好下停用動畫與轉場。

### 介面配色

| 用途 | 色碼 |
| --- | --- |
| 頁面背景／主文字 | `#111816`／`#e5e8df` |
| 選項文字／次要文字 | `#c5d0c5`／`#8f9f92` |
| 選項邊框／hover 背景 | `#2c3b32`／`#1e2b23` |
| 選中背景／選中邊框 | `#25362b`／`#9eae8c` |
| 地圖邊框／鍵盤焦點外框 | `#35443b`／`#e7c88d` |
| 強度滑桿 | `#b3bf9f` |

本節保留效果參數與最後互動決定；實驗頁隨 worktree 清理，不納入正式產品。
