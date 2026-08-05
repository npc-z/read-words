# 调研:MDX 解析与多格式词表导入生态

> 对应 issue #4(wayfinder:research)。纯事实查证,选型决策由技术栈票(#2)与导入管线讨论负责。
> 调研日期:2026-08-05。星标/最后提交时间以当日 GitHub/npm/pub.dev/PyPI 查询为准。

## 1. MDX 格式背景

- **MDX 与 MDD 同构**:MDX 存词典释义(键=词头,值=定义,通常为 HTML),MDD 存引用资源(图片/音频/CSS,键=文件名如 `\audio\aask.spx`,值=原始字节)。两者共享同一文件结构(头部 + 加密 key 块 + 记录块 + 索引)。
  - 来源:https://github.com/csarron/mdict-analysis(README)、https://github.com/terasum/js-mdict(README 含 v1.2-v2.0 与 v3.0 布局图)
- **引擎版本与压缩**:
  - v < 2.0(engine 1.2):记录块用 **LZO** 压缩(需 python-lzo 才能读)
  - v >= 2.0:**zlib** 压缩
  - v >= 3.0:较新 MdxBuilder 产物,checksum 用 **xxhash**,密钥由 **UUID** 派生(实现:pyglossary 内置 readmdict.py)
  - 来源:https://github.com/ilius/pyglossary/blob/master/pyglossary/plugin_lib/readmdict.py(源码注释与逻辑,当前最活跃的 readmdict 维护版)
- **加密变体**(记录块头 `encryption_method` 字段):0=无加密;1=fast-decrypt(XOR 前 N 字节);2=Salsa20(早期实现/文档称 RC4)。密钥来源:注册码+用户 ID(RSA 类)、v3.0 的 UUID、或 Adler-32/RIPEMD128 派生。**实际流通的公开词库绝大多数不加密**;加密词库多为付费词典,主流开源解析器要么不支持、要么未充分测试。
  - 来源:同上 readmdict.py;https://github.com/zhansliu/writemdict(格式完全披露源,357 stars,2017 年停更)
- **词条内容形态**:MDX 词条定义为 HTML(含 `sound://`、`entry://`、`@@@LINK=`、`<img src="\pic\...">` 等专有引用),需解析后才能得到纯文本音标/释义/例句。
  - 来源:https://github.com/terasum/js-mdict(README 的 lookup 输出示例)
- 事实标准参考实现:**GoldenDict-NG**(C++,GPL,活跃):https://github.com/xiaoyifang/goldendict-ng

## 2. MDX/MDD 解析库对比

### Python

| 库 | 维护状态 | 功能 | 来源 |
| --- | --- | --- | --- |
| **pyglossary**(ilius) | **活跃**(2.7k stars、4,457 commits、持续发版,要求 Python 3.12+);MDX 只读 | 支持 1.2/2.0/3.0、zlib/LZO、加密、MDD 音频(`audio=True` 选项);依赖 xxhash,部分词库需 python-lzo;可 CLI/库两用,输出 JSON/CSV/txt 等 50+ 格式 | https://github.com/ilius/pyglossary |
| **readmdict**(zhansliu 原作) | 原 repo 已 404;经典实现,经 pyglossary 内置(plugin_lib/readmdict.py)持续维护;PyPI 重打包 ffreemt/readmdict 0.1.1(2021-12 后未再上传) | `from readmdict import MDX, MDD`,命令行可提取 mdx/mdd(音频图片一并导出) | https://pypi.org/project/readmdict/、https://github.com/ffreemt/readmdict |
| **SilverDict**(Crissium) | 活跃(239 stars,2025-10 有提交) | Flask 后端 + Vue 前端的 Web 版 MDX 阅读器;是"Python 服务端解析 + Web 前端展示"的现成参考 | https://github.com/Crissium/SilverDict |
| mdict-analysis(xwang / csarron fork) | 停更(csarron fork 265 stars,2021 后无提交) | 格式逆向分析原始文档 + readmdict 样例,仍有文档价值 | https://github.com/csarron/mdict-analysis |

### JavaScript / TypeScript

| 库 | 维护状态 | 功能 | 来源 |
| --- | --- | --- | --- |
| **js-mdict**(terasum)**★ 推荐** | **活跃**(204 stars,npm v7.0.0 发布于 2026-03;repo 2026-04 有提交) | TypeScript,继承 jeka-kiselyov/mdict 与 fengdh/mdict-js;支持 v1.2/2.0 并通过 20+ 真实词库测试(含中文双解词典),v3.0 布局有文档;lookup/prefix/fuzzy/contains、MDD 定位资源、`@@@LINK` 处理 | https://github.com/terasum/js-mdict、https://www.npmjs.com/package/js-mdict |
| fengdh/mdict-js | 停更(258 stars,2019 停) | 纯 JS **浏览器可用**(FileReader 拖放,在线 demo:https://fengdh.github.io/mdict-js/),GZip/LZO、RIPEMD128 key index、MDD 音频(wav/spx);不支持 >4G 偏移与 regcode 加密头 | https://github.com/fengdh/mdict-js |
| mdict(jeka-kiselyov) | 停更(60 stars,2020 停) | Node-only 读取器,已被 js-mdict 取代 | https://github.com/jeka-kiselyov/mdict |
| @cyia/mdict-reader | 较活跃(npm 2026-05)但小众 | TS 读取器 | https://www.npmjs.com/package/@cyia/mdict-reader |
| react-native-mdict(NiuGuohui) | 新(2026-01,C++ N-API,1 star) | RN 原生模块解析 mdx/mdd,若选 RN 可评估,但生态极早期 | https://github.com/NiuGuohui/react-native-mdict |

> ⚠️ 许可注意:js-mdict **v7.0.0(2026-03)起由 MIT 转为 AGPL-3.0**(作者声明用于网络服务需开源或购买商业许可);v6.x 及以下仍为 MIT。商用选型需纳入考量。

### Dart / Flutter

| 库 | 维护状态 | 功能 | 来源 |
| --- | --- | --- | --- |
| **dict_reader**(mumu-lhl)**★ 推荐** | **活跃**(pub.dev 1.6.0 发布于 2026-02;repo 2026-07 有提交;18 stars,MIT,verified publisher) | 纯 Dart 读 MDX/MDD;作者自列局限:checksum 校验 ❌、LZO 压缩 ❌、v3.0 格式 ❌、record block 加密 ❌(影响面:公开无加密、v1.2/2.0、zlib 词库) | https://pub.dev/packages/dict_reader、https://github.com/mumu-lhl/dict_reader |
| **Ciyue**(mumu-lhl) | **活跃**(597 stars,2026-07 有提交) | Flutter MDict 词典 App(Android/Windows/Linux,含 MDD 音频、多词典、AI 翻译),底层用 dict_reader——**Flutter 生态能做 MDX/MDD 的产品级实证** | https://github.com/mumu-lhl/Ciyue |
| mdict_reader(qingshan) | 停更(25 stars,2023-02) | Dart MDX/MDD 读取 | https://github.com/qingshan/mdict_reader |
| mdict_dart(caojianfeng) | 停更(0 stars,2020) | Dart MDX/MDD 读取 | https://github.com/caojianfeng/mdict_dart |

### 其他语言(备选)

- Rust:`eatgrass/mdict-parser`(20 stars,2024-04)、`unico-serein/rs-mdict`(2026-02 提交)、`whistooy/mdict-reader`(2025-12 提交)— 可通过 FFI 供移动端调用,但生态皆早期。

## 3. 各语言结论(事实性)

- **Python 最优解**:`pyglossary`(活跃、覆盖最全、自带 MDD 音频提取),或直接复用其内置的 `readmdict.py` 逻辑。
- **JS/TS 最优解**:`js-mdict`(唯一活跃的 TS 实现,浏览器不可直接读本地文件但可在 Node/打包后端用;**注意 AGPL v7+**);纯浏览器端只有已停更的 `fengdh/mdict-js` 可参考。
- **Flutter 最优解**:`dict_reader`(唯一活跃的纯 Dart 实现,并有 Ciyue 生产 App 背书;局限集中在 LZO/3.0/加密,见上表)。

## 4. 词表格式解析库推荐(txt / markdown / excel / csv)

### Flutter/Dart

| 格式 | 方案 | 说明 |
| --- | --- | --- |
| txt(纯单词 / 单词-释义) | 手写解析(逐行 split) | 无成熟通用库;注意 UTF-8/GBK 编码探测(可用 charset 包) |
| csv | **pub.dev `csv`**(v8.0.0,2026-03 发布,活跃) | 流式解析、自动探测、Excel 兼容;https://pub.dev/packages/csv |
| excel | **pub.dev `excel`**(v4.0.6,2024-08;GitHub 483 stars,2025-07 仍有提交) | 读写 xlsx,客户端/服务端通用;https://pub.dev/packages/excel |
| markdown | **pub.dev `markdown`**(v7.3.1,2026-03;dart-lang 官方维护) | 解析为 HTML,配套可渲染;https://pub.dev/packages/markdown |

文件选择:`file_picker`(https://pub.dev/packages/file_picker)。

### JS / React Native

| 格式 | 方案 | 说明 |
| --- | --- | --- |
| txt | 手写解析 | 同上 |
| csv | **PapaParse**(npm 5.5.4,2026-06 仍发布,社区事实标准) | https://www.npmjs.com/package/papaparse |
| excel | **SheetJS / xlsx**(GitHub 36.3k stars,仓库活跃,Apache-2.0) | ⚠️ **npm 包停在 0.18.5(2022-03)**,官方改走自托管分发:https://cdn.sheetjs.com(文档 https://docs.sheetjs.com),需引入官方 CDN 产物或自托管 |
| markdown | **marked**(npm 18.0.9,2026-08 发布,活跃)或 remark/unified(需 AST 时) | https://www.npmjs.com/package/marked |

文件选择:RN 用 `react-native-document-picker`。

## 5. 与 AI 生成内容的衔接建议(数据结构层面)

1. **统一词条模型**(管线出口,所有来源收敛到同一结构):
   `{ word, phonetic?, senses: [{pos?, meaning, examples: [{text, translation?}]}], audio?: [{path/url, format}], source: {type: "mdx"|"txt"|"csv"|"excel"|"markdown", name, entryId?}, rawHtml? }`
   - MDX 解析后是 HTML → 需做 HTML→纯文本/Markdown 提取再喂给 AI(Flutter 侧可用 html 类包,JS 侧 DOMParser);**rawHtml 建议保留**,AI 结构化提取时原文更不易丢信息。
2. **专有引用处理**:MDX 词条中的 `sound://`、`entry://`、`@@@LINK=`、`<img src="\...">` 需在解析层转换/丢弃;音频若从 MDD 提取,按文件名映射存为独立 asset 表,词条只存引用 id。
3. **中间格式**:建议导出为 **JSONL(每行一词条)+ 可选 SQLite 索引**,作为 AI 生成内容(释义增强、例句、记忆卡)的输入与增量回写位;保留 `source` 溯源字段,便于 AI 提示词拼接上下文与后续去重。
4. **双栈落点**:
   - 若选 **Flutter**:`dict_reader`(MDX/MDD)+ `csv` + `excel` + `markdown` + 手写 txt,全链路 Dart 原生可行。
   - 若选 **RN/JS**:`js-mdict`(注意 AGPL,或评估 react-native-mdict)+ PapaParse + SheetJS(官方 CDN)+ marked;浏览器纯前端方案(MDX)目前只有停更的 fengdh/mdict-js,工程化建议放 Node 侧解析或服务端(如 Python pyglossary/SilverDict 方案)再做。
