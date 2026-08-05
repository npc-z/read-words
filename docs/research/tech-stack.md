# 技术栈调研:跨平台框架与关键能力选型

> 关联 issue:npc-z/read-words#2(调研:跨平台技术栈与关键能力选型)
> 调研日期:2026-08-05。所有结论以官方文档 / pub.dev / GitHub 仓库 / npm 注册表一手来源为准。

## 1. 调研范围

为一套代码覆盖 **Android + Web(未来需支持 iOS)** 的本地优先 App 选型。五项关键能力:

1. 离线 SQLite 存储
2. TTS 发音(区分英音/美音 en-US / en-GB)
3. 文件导入导出(MDX / txt / markdown / excel)
4. 后台队列任务(批量生成任务)
5. 局域网多设备进度同步

候选框架:**Flutter**(Dart)与 **React Native + Expo**(TypeScript)。两者均官方支持 Android / iOS / Web / 未来 iOS,满足"一套代码多端"前提。

## 2. 候选对比总表

| 维度 | Flutter | React Native + Expo |
|---|---|---|
| 离线 SQLite | **强**。drift(Flutter Favorite,2.4k likes)全平台含 Web(稳定,SQLite 编译为 WASM);sqflite(Flutter Favorite,5.5k likes)为 iOS/Android/macOS 原生,Web 走实验性 FFI 方案 | 中。expo-sqlite(官方,Web 支持为 **alpha**);op-sqlite(极活跃但**不支持 Web**);老库 react-native-sqlite-storage 已停更(2024-05 后无提交) |
| TTS 英/美音 | **强**。flutter_tts 4.2.5 支持 Android/iOS/Web,`setLanguage("en-US"/"en-GB")` + `getVoices()` 切换发音,Web 走浏览器 Web Speech API | 中。expo-speech 支持 Android/iOS/Web;react-native-tts(社区主流)已停滞(2024-06 后无提交,且**无 Web**) |
| 文件导入导出 | **强**。file_picker 11.x 全平台(含 Web、saveFile 另存对话框);excel 包纯 Dart 读写 XLSX 全平台 | 中。expo-document-picker 全平台;XLSX 生态核心 SheetJS CE 已冻结(npm 0.18.5,主分发转至其自建 CDN) |
| 后台队列任务 | **强**。workmanager(2.4k likes)Android WorkManager + iOS BGTaskScheduler,Web 有实验性 Service Worker 实现 | 中弱。expo-background-task 仅 Android/iOS,**Web 不支持**(Web 端恒返回 Restricted);备选 react-native-background-fetch |
| 局域网同步 | **强**。dart:io 一等公民提供 WebSocket/TCP **服务端**(Android/iOS/macOS);bonsoir 提供 mDNS 服务发现(移动+桌面) | 弱。需第三方原生模块 react-native-tcp-socket 才能开 TCP 服务端(无 Web);mDNS 无官方方案 |
| MDX 解析 | **弱**。Dart 生态无 MDX 库(MDX 是 markdown+JSX,编译为 JS),需自行预处理剥离 JSX | **强**。@mdx-js/react 等官方生态原生支持(见 mdxjs.com) |
| UI 跨端一致性 | **强**。自绘渲染引擎(Skia/Impeller),各平台同一渲染管线 | 中。原生控件渲染,Web 端用 react-dom,视觉细节需逐端调 |
| 未来 iOS 迁移 | 官方一等支持,成本低 | 官方一等支持,成本低 |
| 综合成熟度 | 生态大、更新活跃、平台插件覆盖全 | 生态大、Expo 迭代快,但关键插件(tts/sqlite-web/background)短板明显 |

## 3. 五项能力逐项结论

### 3.1 离线 SQLite 存储

**Flutter:推荐 drift**(首选)+ sqflite(备选)。

- drift 2.34.3(Flutter Favorite):类型安全 ORM/查询构建、迁移、响应式流,全平台支持,Web 通过自定义 sqlite3 WASM 构建运行,官方文档明确 Web 支持为稳定态(非实验);在 Web 端需随包分发 `sqlite3.wasm` + `drift_worker.js`,如需最佳性能可加 COOP/COEP 头,不加也能工作(降级 IndexedDB);已知坑:Web 端不支持 WAL 日志模式、多标签页并发需要 shared worker(Chrome Android 无 shared worker 时有数据竞争风险)。
  - https://pub.dev/packages/drift
  - https://drift.simonbinder.eu/web
- sqflite 2.4.3(Flutter Favorite):iOS/Android/macOS 原生 SQLite,Web 为实验性(`sqflite_common_ffi_web`)。
  - https://pub.dev/packages/sqflite

**React Native:expo-sqlite**(官方)+ op-sqlite(性能备选)。

- expo-sqlite:官方维护,Android/iOS/macOS/tvOS/Web;**Web 支持处于 alpha**,需要 Metro 配置 wasm 支持并加 COOP/COEP 头(SharedArrayBuffer),部署要求较高;亮点:内置 SQLite session API(changeset 生成/应用),对局域网增量同步非常友好;支持 SQLCipher / libSQL 选项。
  - https://docs.expo.dev/versions/latest/sdk/sqlite/
- op-sqlite(@op-engineering/op-sqlite,1028 stars,2026-08 仍在高频提交):移动/桌面端性能极佳,但**不支持 Web**。
  - https://github.com/OP-Engineering/op-sqlite
- react-native-sqlite-storage(2824 stars):已停止维护(最后提交 2024-05),不建议新项目采用。
  - https://github.com/andpor/react-native-sqlite-storage

> 共同坑点:Web 端 SQLite 只能走 WASM,两栈都要处理部署头与文件分发;桌面/移动端无此问题。

### 3.2 TTS 发音(英音/美音)

**Flutter:flutter_tts 4.2.5。**

- 官方支持 Android/iOS/macOS/Web/Windows;`setLanguage("en-US")` / `setLanguage("en-GB")`、`getVoices()` 按 locale 列出声线、`isLanguageAvailable()` 检测、Android/iOS 可 `synthesizeToFile()` 离线合成音频文件(便于批量生成语音文件);Web 端走浏览器 Web Speech API。repo(dlutton/flutter_tts,750 stars)2026-01 仍有提交,属活跃维护;215 个 open issues 是其短板,建议锁版本使用。
  - https://pub.dev/packages/flutter_tts
  - https://github.com/dlutton/flutter_tts

**React Native:expo-speech**(官方);react-native-tts 不建议。

- expo-speech:Android/iOS/Web,`Speech.speak(text, { language: 'en-GB' })` + `getAvailableVoicesAsync()`,Web 走 Web Speech API;已知坑:Android 不支持 pause。
  - https://docs.expo.dev/versions/latest/sdk/speech/
- react-native-tts 4.1.1:697 stars,但最后提交 2024-06(约两年停滞)、137 open issues,且仅 iOS/Android 无 Web。
  - https://github.com/ak1394/react-native-tts

> 双端结论:移动端两栈均依赖系统 TTS 引擎(Android 语音随厂商引擎而异),Web 端两栈最终都落在浏览器 Web Speech API(支持 en-US/en-GB)。**英/美音区分两栈均可实现**;Flutter 额外多出"离线合成音频文件"能力,对批量生成任务有价值。

### 3.3 文件导入导出(MDX/txt/markdown/excel)

**Flutter:**

- 文件拾取/保存:file_picker 11.0.3,全平台(含 Web、Wasm),支持扩展名过滤与 `saveFile()` 另存对话框。
  - https://pub.dev/packages/file_picker
- XLSX:excel 4.0.6,纯 Dart 读写 xlsx,全平台(Web 上 `save()` 直接触发下载)。已知坑:发布节奏慢(当前版本发布于约 2 年前),无公式计算、无图表。
  - https://pub.dev/packages/excel
- txt/markdown:package:markdown / flutter_markdown 成熟。
- **MDX:无 Dart 生态支持。** MDX 本质是 "markdown + JSX",编译为 JavaScript 后在 JSX 框架中运行(官方定位"Markdown for the component era")。Flutter 方案需自行剥离 JSX 标签或写自定义解析器,是 Flutter 侧唯一明显短板。
  - https://mdxjs.com

**React Native:**

- 文件拾取:expo-document-picker,官方支持 Android/iOS/Web(Web 返回 File/base64;坑:仅可在用户手势后调用,浏览器无 cancel 事件)。
  - https://docs.expo.dev/versions/latest/sdk/document-picker/
- XLSX:SheetJS CE 是生态事实标准,但 **CE 已停止新版本**(npm `xlsx` 停留在 0.18.5,官方仓库最后提交 2024-04,分发主渠道转为自建 CDN cdn.sheetjs.com);可选 exceljs(需 polyfill,移动端支持一般)。excel 能力两栈都"能用但需注意维护风险"。
  - https://docs.sheetjs.com/docs/getting-started/installation/
  - https://github.com/SheetJS/sheetjs
- MDX:@mdx-js/react + remark 官方支持,React 栈(含 React Native Web)可直接编译渲染 MDX。
  - https://mdxjs.com

### 3.4 后台队列任务(批量生成任务)

**Flutter:workmanager 0.10.7**(fluttercommunity 维护,2.4k likes,2026-08 活跃)。

- Android:封装 WorkManager;iOS:封装 BGTaskScheduler;Web:实验性 `workmanager_web`(Service Worker 实现,仅 Chromium + 已安装 PWA,无精确调度)。
  - https://pub.dev/packages/workmanager

**React Native:expo-background-task**(官方)。

- Android WorkManager + iOS BGTaskScheduler;已知坑:**Web 不支持**(`getStatusAsync()` 在 Web 恒返回 Restricted);单 worker 承载全部任务;iOS 模拟器不可用。
  - https://docs.expo.dev/versions/latest/sdk/background-task/
- 备选:react-native-background-fetch(transistorsoft,1610 stars,活跃)。
  - https://github.com/transistorsoft/react-native-background-fetch

> 平台本质限制(与框架无关):Android/iOS 后台任务均由系统调度、**延迟执行、时长受限、不可精确到秒**。若"批量生成"是用户主动触发的大任务,应设计为"前台/短后台队列 + 任务持久化(存 SQLite,App 前台或系统窗口内续跑)"模式;两栈在移动端后台能力对等,差异只在 **Web 端:workmanager 有实验性方案,expo-background-task 完全没有**。

### 3.5 局域网多设备进度同步

推荐架构:一台移动设备作 host(本地 WebSocket/TCP 服务端)+ 其余设备(含 Web)作 client 连接;设备发现用 mDNS。

**Flutter:**

- 服务端:dart:io 一等公民提供 `HttpServer`/`WebSocketTransformer`,可在 Android/iOS 原生跑 WebSocket 服务端,无需任何第三方原生代码;Web(浏览器)无法开 TCP 服务端,dart:io 在 Web 不可用 → Web 端只能作 client。
  - https://api.dart.dev/stable/dart-io/WebSocketTransformer-class.html
- 设备发现:bonsoir 7.1.4(mDNS/NSD 广播+发现),支持 Android/iOS/桌面,活跃维护;**不支持 Web** → Web 端回退为手动输入 IP/扫码。
  - https://pub.dev/packages/bonsoir

**React Native:**

- 服务端:无官方方案,需第三方原生模块 react-native-tcp-socket 6.4.2(TCP/TLS client+server,支持 Android/iOS/macOS,**不支持 Web**;392 stars,活跃,但为单人维护、25 open issues)。
  - https://github.com/Rapsssito/react-native-tcp-socket
- 设备发现:无 mDNS 官方方案(社区包长期未维护)。

> 双端结论:两栈都必须"移动端作 host、Web 作 client"。Flutter 的 server 能力是语言/平台内建(零依赖、跨 iOS 无缝),RN 依赖第三方原生模块(增加维护面)。同步协议本身(版本号/变更日志/WebSocket 推送)需自研,或参考 expo-sqlite 的 session API(changeset)思路——该 API 在 Flutter 侧无等价物,这是 RN 在"同步增量"上的一个加分项。

## 4. 跨端一致性 / 离线能力 / iOS 迁移成本

| 维度 | Flutter | RN + Expo |
|---|---|---|
| UI 双端一致 | 自绘引擎(Skia/Impeller),Android/Web 同一渲染管线,像素级一致 | 原生控件渲染 + Web 端 react-dom,平台差异(字体、阴影、滚动手感)需逐端适配 |
| 离线能力 | 强:drift/sqflite 本地库 + dart:io 本地网络服务,天然本地优先 | 强:expo-sqlite + JS 生态丰富;Web 端 SQLite 为 alpha 是隐患 |
| iOS 迁移 | 官方一等支持;迁移成本主要是 iOS 音频会话等平台设置 | 官方一等支持;expo 生态对 iOS 支持同样完善 |

## 5. 推荐与理由

### 首选:Flutter

五项关键能力中 4.5/5 项占优或持平,且占优项正是本 App 的核心:

1. **SQLite 全平台最稳**:drift Web 支持为稳定态,expo-sqlite Web 仅为 alpha(Web 是必选平台,这一条权重最高);
2. **TTS 全平台 + 离线合成**:flutter_tts 同时覆盖 Android/iOS/Web 且支持 en-US/en-GB 切换,还能离线合成音频文件支撑批量任务;
3. **后台任务 Web 有路**:workmanager_web 实验性方案 > RN 的完全缺失;
4. **LAN 同步服务端零依赖**:dart:io 内建 WebSocket server,未来上 iOS 无需引入原生模块;
5. **UI 双端一致性最好**:自绘渲染消除 Android/Web 视觉分裂,降低双端 QA 成本。

**已知短板(MDX)与对策**:Flutter 生态无 MDX 解析器。若 MDX 导入为硬需求,需在导入管道中自行预处理(剥离 JSX、保留 markdown 子集);若确认 MDX 是核心格式且占比高,则此条可成为转向 RN 的决策点。

### 备选:React Native + Expo(纯 JS/TS 优先或 MDX 硬需求时启用)

- **MDX 原生生态**(@mdx-js/react)是 RN 相对 Flutter 的最大优势;
- expo-sqlite 的 session/changeset API 对增量同步是现成素材;
- 但需接受:expo-sqlite Web alpha、expo-background-task 无 Web、react-native-tts 停滞(只能靠 expo-speech)、SheetJS CE 冻结、TCP server 依赖第三方模块、双端 UI 一致性弱于 Flutter。

### 决策建议

| 条件 | 选择 |
|---|---|
| 默认 | **Flutter**(drift + flutter_tts + file_picker/excel + workmanager + dart:io/bonsoir) |
| MDX 为不可降级核心格式,且团队 TS 经验占优 | RN + Expo(@mdx-js/react + expo-sqlite + expo-speech + expo-background-task + react-native-tcp-socket) |

## 附录:来源数据快照(2026-08-05)

| 包/仓库 | 版本 | 活跃度 | 平台 | 来源 |
|---|---|---|---|---|
| sqflite | 2.4.3 | 活跃 | Android/iOS/macOS(+Web 实验) | https://pub.dev/packages/sqflite |
| drift | 2.34.3 | 活跃 | 全平台含 Web(稳定) | https://pub.dev/packages/drift |
| flutter_tts | 4.2.5 | 活跃(2026-01 提交) | Android/iOS/macOS/Web/Windows | https://pub.dev/packages/flutter_tts |
| workmanager | 0.10.7 | 活跃(2026-08) | Android/iOS(+Web 实验) | https://pub.dev/packages/workmanager |
| file_picker | 11.0.3 | 活跃(2026-08) | 全平台含 Web | https://pub.dev/packages/file_picker |
| excel | 4.0.6 | 慢(约 2 年未发版) | 全平台含 Web | https://pub.dev/packages/excel |
| bonsoir | 7.1.4 | 活跃(2026-07) | Android/iOS/桌面(无 Web) | https://pub.dev/packages/bonsoir |
| expo-sqlite | SDK 57 | 官方活跃 | Android/iOS/macOS/tvOS/Web(alpha) | https://docs.expo.dev/versions/latest/sdk/sqlite/ |
| expo-speech | SDK 57 | 官方活跃 | Android/iOS/Web | https://docs.expo.dev/versions/latest/sdk/speech/ |
| expo-background-task | SDK 57 | 官方活跃 | Android/iOS(无 Web) | https://docs.expo.dev/versions/latest/sdk/background-task/ |
| expo-document-picker | SDK 57 | 官方活跃 | Android/iOS/Web | https://docs.expo.dev/versions/latest/sdk/document-picker/ |
| op-sqlite | 17.1.5 | 极活跃(2026-08) | 移动/桌面(无 Web) | https://github.com/OP-Engineering/op-sqlite |
| react-native-tts | 4.1.1 | 停滞(2024-06) | iOS/Android(无 Web) | https://github.com/ak1394/react-native-tts |
| react-native-sqlite-storage | — | 停滞(2024-05) | iOS/Android | https://github.com/andpor/react-native-sqlite-storage |
| react-native-tcp-socket | 6.4.2 | 活跃(2026-07) | Android/iOS/macOS(无 Web) | https://github.com/Rapsssito/react-native-tcp-socket |
| react-native-background-fetch | 4.4.2 | 活跃(2026-04) | iOS/Android | https://github.com/transistorsoft/react-native-background-fetch |
| SheetJS CE (xlsx) | 0.18.5 | 冻结(2024-04) | JS 全平台 | https://docs.sheetjs.com/docs/getting-started/installation/ |
| MDX | 3.x | 活跃 | JSX 框架(React/Preact/Vue) | https://mdxjs.com |
