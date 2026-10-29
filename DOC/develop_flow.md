# 一人 Side Project 開發流程

採用精簡瀑布式：先釐清概念與範圍，再寫需求、做設計、開發、驗收與試用。每個階段留下足以支持下一步的紀錄即可。

個人目標：練習後端（API 設計、權限、登入）。「直接用平台功能」與「自己實作」的取捨，學習價值也列入考量，例如 [ADR 0002](adr/0002-own-backend-api-and-auth.md)。

## 流程與完成條件

| 階段 | 要做的事 | 完成條件 |
| --- | --- | --- |
| 1. 主要概念 | 說明為誰解決什麼問題、現在怎麼解決、為什麼值得做 | 能用幾句話說清楚核心價值，並提出試用時要驗證的假設 |
| 2. Brainstorm 功能 | 從實際使用情境發想功能與可能方案；用 grill-me 類型的追問釐清假設 | 有候選功能與用途，尚不承諾全部實作 |
| 3. 找出主要功能 | 選出能走完一次核心任務的最小功能組合，列出第一版不做的項目 | MVP 範圍明確；訂出可投入的時間與費用上限 |
| 4. 技術可行性評估 | 確認外部 API、資料來源、平台限制、成本與自身能力能否支援核心功能；關鍵未知必要時做小型驗證 | 關鍵依賴可用，主要技術風險有結論；不可行就回頭調整範圍 |
| 5. 詳細需求 | 寫清楚每項必要功能的操作流程、輸入輸出、失敗情境及驗收條件；按需要記錄隱私、權限、效能等限制 | 每項需求都有可以實際判定通過或失敗的標準 |
| 6. 最小設計與開發清單 | 按需求決定技術選型、畫必要的畫面草圖、資料結構與系統連接；拆出有先後順序的工作 | 能依清單開始開發，主要資料流與使用流程清楚 |
| 7. 開發 MVP | 按已確認的需求與清單實作，邊做邊檢查功能與整合 | 核心流程可在預定試用環境完整執行 |
| 8. 測試與驗收 | 對照第 5 階段逐項檢查，包含失敗情境；修正阻擋核心任務的問題 | MVP 必要驗收條件通過，可提供試用 |
| 9. 實際試用與結論 | 自己及適合的目標使用者完成真實任務，記錄卡點、價值和回饋 | 回答原本的假設是否成立，決定修正、進入下一版或停止 |

## 執行原則

- 第一版只承諾完成 MVP；其他候選功能留待下一版評估。
- 技術評估先回答「做不做得到」，詳細設計再回答「具體怎麼做」。
- 需求確認後，開發中冒出的新點子先記錄；若確實阻礙核心價值，回到受影響階段修正需求、設計與預估，再繼續開發。
- 測試與驗收確認「是否符合需求」；試用確認「是否解決了使用者的問題」。
- 涉及程式邏輯的 code review 盡量執行單元測試、CRAP 與變異測試；範圍與未執行原因必須記錄，見 [測試與 Code Review 建議](tech/stack.md#測試與-code-review-建議)。
- 不需要每日站會、Sprint 或額外角色分工。完成條件由自己檢查確認。
- 瀑布式在這裡代表階段依序推進；發現前提錯誤仍應回頭修正。

## 開發進度

最後更新：2026-10-29

| 階段 | 狀態 | 備註 |
| --- | --- | --- |
| 1. 主要概念 | 完成 | 核心價值與試用假設 H1～H5 見 ideas.md 開頭 |
| 2. Brainstorm 功能 | 完成 | 候選功能記於 ideas.md |
| 3. 找出主要功能 | 完成 | MVP 情境 0～5；時間不限，費用以免費方案為原則（目前全部免費：Supabase、Vercel Hobby、R2；網域與寄信等正式開放再說） |
| 4. 技術可行性評估 | 完成 | 自訂地圖（MapLibre＋Protomaps/OSM）已驗證可行，見 custom-map-prototype.md；店家位置由使用者在地圖上點大概位置，不用任何地址轉座標服務；精確位置與導航透過使用者貼的 Google Maps 連結；技術選型已定，見 tech/stack.md；R2 經網路調查可行（建帳號時再確認）；Google 短網址展開已實測可行，見 google-short-url-test.md |
| 5. 詳細需求 | 完成 | 情境 0～6、亮度計分公式與驗收條件（mvp-acceptance.md）已定案；架構改為自建後端 API 與登入（ADR 0002）；系統方核對只做管理 API，不做介面 |
| 6. 最小設計與開發清單 | 完成 | 資料模型完成，見 tech/data-model.md；API 設計完成，見 tech/api.md 與 admin-api.md；design system 初版完成，見 tech/design-system.md；招牌時刻方向已定；畫面草圖完成，見 tech/stack.md「畫面風格」；開發清單見 tech/dev-checklist.md |
| 7. 開發 MVP | 未開始 | 照 tech/dev-checklist.md 順序做 |
| 8～9 | 未開始 | |

下一步：第 7 階段，從開發清單第 1 項（帳號與環境）開始。畫面風格必須是自己的，不可照搬 AI 提案或預設樣式，規則見 tech/stack.md「畫面風格」。

## 文件安排

目前文件安排：

- [brainstorm/ideas.md](brainstorm/ideas.md)：概念、功能發想、MVP 範圍與決策紀錄。
- `develop_flow.md`：本開發流程。
- [GLOSSARY.md](../GLOSSARY.md)：領域名詞定義（店家、私房店、到訪、評價等）。
- [user_stories/mvp-user-scenarios.md](user_stories/mvp-user-scenarios.md)：以 Mermaid 記錄 MVP 主要使用流程。
- [user_stories/mvp-user-scenarios-detail.md](user_stories/mvp-user-scenarios-detail.md)：逐步討論 MVP 操作、輸入、結果與例外情境。
- [user_stories/mvp-acceptance.md](user_stories/mvp-acceptance.md)：MVP 驗收條件，第 8 階段逐項勾選。
- [tech/custom-map-prototype.md](tech/custom-map-prototype.md)：自訂台灣地圖技術驗證（用了什麼、來源、注意事項、地圖樣式）。
- [tech/stack.md](tech/stack.md)：技術選型與開發規則。
- [tech/data-model.md](tech/data-model.md)：資料表、欄位規則與推算方式。
- [tech/api.md](tech/api.md)：前端用的 API 端點、欄位驗證與錯誤格式。
- [admin-api.md](admin-api.md)：系統方核對店家的管理 API 使用說明。
- [tech/design-system.md](tech/design-system.md)：顏色、字體、間距與元件規則；試做頁在 `output/prototypes/`。
- [tech/dev-checklist.md](tech/dev-checklist.md)：第 7 階段的開發順序與每項完成條件。
- [adr/](adr/)：難以反悔的架構決策紀錄。

進入詳細需求階段，再按需要新增需求、設計及驗收紀錄，不先建立空文件。

## 參考

常見瀑布式流程包含需求、設計、實作、驗證、維護。本文件是在這個順序前增加構思與可行性評估，並將試用獨立列出，作為一人 side project 的實用改編，不是正式標準的完整合規流程。

- [Atlassian：Waterfall methodology](https://www.atlassian.com/agile/project-management/waterfall-methodology/)
- [IBM：Agile vs. Waterfall](https://www.ibm.com/think/topics/agile-vs-waterfall)
