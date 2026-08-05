# 调研纪要:同类阅读学单词项目与最佳实践

> Issue #3(wayfinder:research)。调研目标:为"通过阅读例句学习英语单词(App:每词 9 句 3 层难度 + AI 生成例句/释义 + 本地缓存,Android + Web)"寻找相近开源项目,评估生态位置,沉淀最佳实践。
> 调研日期:2026-08-05。所有 star 数 / 活跃时间 / 技术栈均取自 GitHub API 与项目 README(一手来源)。

## 一、候选项目清单

### 高相关度(AI 生成学习素材)

| 项目 | star | 活跃度 | 技术栈 | 做法概述 |
|---|---|---|---|---|
| [Ceelog/DictionaryByGPT4](https://github.com/Ceelog/DictionaryByGPT4) | 6333 | 2026-02(活跃) | HTML 静态站 + JSON 数据,CC-BY-SA-4.0 | 用 GPT-4 为 8000+ 单词生成"单词书":词义分析、多场景例句(带中文翻译)、词根词缀、文化背景、变形、记忆技巧、百词小故事。**生成 prompt 完整公开在 README**。数据形态:`gptwords.json` 为 `{word, content}` 平铺结构,content 是带章节的 Markdown;同时派生出 EPUB / PDF / **MDX 词典**三种分发格式。 |
| [Sunnychh/english-learning](https://github.com/Sunnychh/english-learning) | 1 | 2026-06(活跃) | Next.js 16 + Prisma + PostgreSQL | 移动端 H5:词表导入 + **AI 例句** + 三轮听写 + 间隔复习。与目标思路最接近,但 repo 近乎空壳(仅 README),无实现可抄,属于"想法已被提出、无人做成"的证据。 |
| [jianingdai/dict-server](https://github.com/jianingdai/dict-server) | 0 | 2025-09 | Go + Gin + MySQL | 单词查询服务:TSV 批量导入词库、REST API、**通过 DeepSeek API 用 SSE 流式生成例句**、生成结果入库。是"AI 生成例句 + 服务端存储"的最小可参考实现。 |
| [naimelhajj/polyglot-vocab-app](https://github.com/naimelhajj/polyglot-vocab-app) | 0 | 2026-02 | 未标明 | "AI 辅助 + 词典锚定(Dictionary-Grounded)"的词汇学习工具。概念上提示:**用权威词典数据锚定 AI 输出以降低幻觉**。 |

### 句子 / 阅读驱动的词汇学习(产品形态)

| 项目 | star | 活跃度 | 技术栈 | 做法概述 |
|---|---|---|---|---|
| [kaiyiwing/qwerty-learner](https://github.com/kaiyiwing/qwerty-learner) | 22713 | 2026-03(活跃) | TypeScript / React | 打字背单词,词库打包为前端 JSON/TS(词义、词性,部分含例句),离线可用,支持 GitHub Pages / Vercel / 桌面端多端部署。证明"轻量 Web 单词学习 + 静态数据"形态成熟且受欢迎。 |
| [Uahh/ToastFish](https://github.com/Uahh/ToastFish) | 6532 | 2023-07(停滞) | C# / .NET WPF | 用 Windows 通知栏推送单词(词义+音标+发音)实现碎片化学习;内置 SM2plus 间隔重复算法与 SQLite 记录;支持自定义词表导入。是被验证的"被动微学习"形态。 |
| [melpomenex/Incrementum](https://github.com/melpomenex/Incrementum) | 64 | 2026-08(活跃) | Tauri 2 + React 19 + Rust | 增量阅读 + 间隔重复(FSRS-6 / SM-18/20/2)+ **AI 生成闪卡** + 导入 PDF/EPUB/Markdown/HTML/TXT/音视频 + 本地 Whisper 转写。是"阅读材料 → 词汇学习"管线的完整工程化参考。 |
| [Benature/WordReview](https://github.com/Benature/WordReview) | 667 | 2024-02(停滞) | Django + MySQL + Pug + JS | 把"Excel 背单词"方法 App 化:词表导入、释义展示、间隔复习。句子驱动较弱,但词表/复习数据模型可参考。 |
| [veritasian/lingo-studio-for-obsidian](https://github.com/veritasian/lingo-studio-for-obsidian) | 0 | 2026-08(活跃) | Obsidian 插件 / TypeScript | 本地优先(Local-first)阅读伴学:划词查词典 + AI 讲解(OpenAI/DeepSeek)+ 一键生词卡 + **SMOG/FRE 可读性打分**。无后端、密钥留本地——"AI + 本地优先"架构的干净范例。 |

### 数据与词表生态(基础设施)

| 项目 | star | 活跃度 | 技术栈 | 做法概述 |
|---|---|---|---|---|
| [skywind3000/ECDICT](https://github.com/skywind3000/ECDICT) | 8064 | 2025-03 | SQLite 数据 | 开源英汉词典数据库:数十万词条,标注考试大纲(CET4/6、雅思、GRE、牛津 3000)、**BNC 与传统语料库双词频排序**、动词变形。是"本地离线词典 + 词频/难度信号"的现成基础设施。 |
| [busiyiworld/maimemo-export](https://github.com/busiyiworld/maimemo-export) | 936 | 2025-10(活跃) | TypeScript | 导出墨墨背单词上千种词库,翻译数据来自 ECDICT-ultimate,可生成 List 背单词/不背单词/欧陆词典等各家自定义格式。展示了词表格式生态与"翻译数据复用 ECDICT"的通行做法。 |

## 二、值得借鉴的模式

1. **"AI 生成 → 静态数据 → 多格式分发"管线(DictionaryByGPT4)**:一个含完整角色/任务描述的系统 prompt 批量生成 8000 词,输出结构化条目(词义/例句/词根/故事),再派生成 JSON / EPUB / PDF / MDX 词典。AI 生成学习素材已验证可规模化(6.3k★、数据可商用 CC-BY-SA)。
2. **词典锚定生成(polyglot-vocab-app / maimemo-export)**:用 ECDICT 的现成释义、词频做"地面真值",AI 只补例句等生成物,降低幻觉、省 token。
3. **惰性生成 + 持久缓存(dict-server / ToastFish)**:首次请求词条时用 DeepSeek 流式生成例句并入库,之后命中缓存;客户端用 SQLite 存本地记录(ToastFish)。天然契合"AI 生成 + 本地缓存"。
4. **间隔重复与学习流打通(ToastFish SM2plus / Incrementum FSRS)**:例句学习不是孤立功能,应挂到 SM-2/FSRS 复习队列上,9 句分层可充当复习阶梯。
5. **本地优先 + 密钥留端(lingo-studio-for-obsidian)**:无后端架构,LLM 密钥不落服务器;Android 端同样可做成"词典本地、生成仅按需联网"。
6. **阅读场景嵌入(Incrementum / lingo-studio)**:增量阅读/划词即学,把"句子即学习素材"从词卡模式升级为阅读模式——本项目的"读例句"形态与增量阅读最接近。

## 三、生态位置判断

- **已占位**:① 传统背单词 App 生态高度饱和(中文社区 qwerty-learner 22.7k★、ToastFish 6.5k★,及大量 Flutter/小程序应用);② "AI 生成单词学习素材"已被 DictionaryByGPT4 验证并可规模复制;③ 例句驱动学习有 WordReview、词表生态支撑,DeepSeek 流式生成例句也有 dict-server 先例。
- **半空白**:每词多句例句(3~5 句)常见于词典式 App,但**"每词固定句数 + 按难度分层(如 9 句 3 层)、层间难度递进"的显式设计**在开源生态中未检索到成型项目(多轮搜索 "graded sentences"、"sentence difficulty"、"AI 例句分层" 均无有效结果)。个别项目(H5 的 Sunnychh/english-learning)有"AI 例句"之名而无分层、无实现。
- **结论**:整体思路不新、素材生成不新、缓存模式不新,但**"难度分层的 AI 例句 + 本地缓存 + 双端"这一组合仍是空白,差异化点在分层设计与例句质量,而非 AI 生成本身**。同时注意:该空白也可能是"需求未被验证"的信号,而非机会。

## 四、最佳实践建议

1. **把生成管线做成可复现的批处理,而非运行时黑盒**:参照 DictionaryByGPT4,系统 prompt(角色 + 任务清单 + 输出格式)作为仓库一等公民公开;生成结果落为结构化 JSON(建议每条:word、音标、释义、`sentences[]`(含 `level` 字段)、词根/故事可选),用 diff 管理增量更新。9 句 3 层的难度可通过 prompt 显式约束(如"第 1 层用 3000 高频词、第 3 层用 CEFR B2+ 词汇")。
2. **用 ECDICT 做本地真值层**:离线释义/音标/词频直接打包进 App(ECDICT SQLite 可裁剪),AI 只负责"按难度生成例句";每句附带词频或 SMOG/FRE 打分(参考 lingo-studio)校验分层是否真的递进。
3. **惰性生成 + 按词永久缓存**:首查即生成(DeepSeek SSE 流式,参考 dict-server),服务端按词缓存;客户端 SQLite 做本地缓存与学习记录,离线可复习已缓存词条。成本控制 = 每词只生成一次 + 释义不走 AI。
4. **数据模型与服务端解耦,先定格式再定端**:参考 gptwords.json 的"单一数据源 + 多格式派生",Android 与 Web 共享同一份词条 JSON/SQLite,避免两端各维护一套词库。
5. **例句学习挂上间隔重复**:接 SM-2/FSRS(ToastFish、Incrementum 已有实现可参考),把 9 句 3 层用作"认识→熟悉→掌握"的复习阶梯。
6. **起步阶段不做联网依赖假设**:静态词表 + 本地 SQLite 优先(参考 qwerty-learner 纯静态也能 22k★),AI 生成作为增强层按需开启,顺便规避纯 API 模式的高成本与不可用风险。

## 五、引用来源

- 各项目 README / 仓库结构与数据文件:GitHub API 拉取(2026-08-05),如 DictionaryByGPT4 README 全文、gptwords.json 前若干字节、ToastFish 目录树(含 SM2plus/、SqliteControl/)、ECDICT README、dict-server README。
- star/活跃数据:`gh repo view` / GitHub API `pushedAt`(2026-08-05)。
