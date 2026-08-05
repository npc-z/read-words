# 调研:英/美音 TTS 发音方案

> 对应 issue: #5(part of #1)
> 查证日期: 2026-08-05
> 状态: 完成(推荐组合见文末)

## 背景与需求

为单词发音功能选型 TTS 方案。硬性要求:

- **区分英音(en-GB)和美音(en-US)两种 voice**
- **发音结果本地缓存**
- **离线可用性评估**
- **成本可控**
- **Android + Web 双端可用**

技术栈未定(Flutter vs React Native 二选一,见 #2),结论需对两者都成立。

## 候选方案对比表

| 类别 | 方案 | 英/美音支持 | 离线 | 成本 | Android/Web 双端可用性 | 来源(查证日期 2026-08-05) |
|---|---|---|---|---|---|---|
| 云端 | **edge-tts**(Edge 在线 TTS 非官方接口) | 优。`--list-voices` 返回 400+ locale 前缀 Neural voice,含 en-GB-SoniaNeural、en-US-AriaNeural 等,与 Azure Neural 同源 | 否(需联网) | **免费**,无需 key/账号 | 无官方移动/JS SDK,需自建服务端代理,或仅用于**离线批量预生成音频文件** | https://github.com/rany2/edge-tts |
| 云端 | **Azure Speech TTS** | 优。官方 en-GB/en-US Neural voice 目录,各端官方 SDK | 否(需联网) | F0 免费层 0.5M 字符/月;付费按字符计费(标准神经约 $15/1M 字符量级;页面动态报价) | 优。REST + 全平台 SDK | https://azure.microsoft.com/en-us/pricing/details/cognitive-services/speech-services/ |
| 云端 | **OpenAI TTS** | **差**。13 个内置 voice 均无 en-GB/en-US 之分,只能靠 instructions 提示口音,不可靠 | 否 | tts-1 $15/1M 字符、tts-1-hd $30/1M 字符、gpt-4o-mini-tts $12/1M 音频输出 token(≈$0.018/min) | 优(REST) | https://developers.openai.com/api/docs/pricing 、 https://platform.openai.com/docs/guides/text-to-speech |
| 云端 | **Google Cloud TTS** | 优。Neural2/WaveNet 等含 en-GB/en-US voice | 否 | WaveNet/Standard $4/1M 字符(免费 4M/月)、Neural2 $16/1M(免费 1M/月)、Chirp3 HD $30/1M、Studio $160/1M | 优(REST+SDK) | https://cloud.google.com/text-to-speech/pricing |
| 设备端 | **Android 系统 TTS API**(TextToSpeech) | 中。`setLanguage(Locale.UK/US)` 选 voice;可用 voice 集取决于设备厂商与 engine | 取决于 engine;部分 voice/engine 需联网(Google 语音服务区分离线/网络 voice) | 免费 | 仅 Android(Web 不可用) | https://developer.android.com/reference/android/speech/tts/TextToSpeech |
| 设备端 | **Web Speech API**(speechSynthesis) | 中。`getVoices()` 按设备/浏览器提供 en-GB/en-US voice,可用性不可控 | **不可保证**(Chrome 部分 voice 依赖网络;Firefox/桌面通常离线可用) | 免费 | 仅 Web;无"合成到文件"API,音频无法缓存 | https://developer.mozilla.org/en-US/docs/Web/API/Web_Speech_API/Using_the_Web_Speech_API |
| 设备端 | **flutter_tts 4.2.5**(Flutter 封装) | 中。`setLanguage("en-US")`/`getVoices()`/`setVoice()`;Android voice 元数据含 `network_required` 可判断离线;`synthesizeToFile` 仅 Android/iOS(Web 不支持) | 同底层系统 TTS | 免费(MIT) | **Android + Web 一套插件**(另支持 iOS/macOS/Windows) | https://pub.dev/packages/flutter_tts |
| 设备端 | react-native-tts(RN 封装) | 中(同系统 TTS) | 同底层系统 TTS | 免费 | **仅 Android+iOS,不支持 Web**;Web 需另写 speechSynthesis | https://registry.npmjs.org/react-native-tts/latest |
| 设备端 | **piper**(本地神经 TTS) | 优。en_GB/en_US voice 齐全 | **完全离线** | 免费(MIT,原仓库已归档 2025-10,迁移至 OHF-Voice/piper1-gpl) | 难。Android 需 JNI/AAR 集成,Web 需 WASM/ONNX,模型数十 MB;质量逊于云端神经 | https://github.com/rhasspy/piper |
| 设备端 | **espeak-ng**(formant 合成) | 良。en-GB/en-US 口音齐全 | **完全离线**(仅几 MB) | 免费(GPL-3.0) | 有 Android 目录与 emscripten(WASM)构建;但**机器人音,只宜兜底** | https://github.com/espeak-ng/espeak-ng |
| 词典音频包 | **MDD 音频包**(MDict 词典资源) | 优(朗文/剑桥/韦氏等词典真人发音,英美音都有) | **完全离线** | 免费(社区分享,版权/再分发合法性不明) | 易集成(双端都是播放本地文件) | 社区来源(freemdict/欧路等),无官方渠道;本票仅作补充评估 |

## 各方案要点与风险

### 云端 TTS

- **edge-tts**:免费、无需 key,背后是 Microsoft Edge 浏览器的在线 TTS 服务(与 Azure Neural 同批 voice,质量很好)。**非官方接口,微软可随时变更/封禁,无 SLA**,官方不支持 SSML 扩展。适合:一次性/低频批量合成,或自建代理服务。移动/Web 端不能直接调用,需要服务端中转。仓库 11.7k stars,社区活跃,但风险不可消除。
- **Azure Speech**:正规方案,voice 目录、SDK、SLA 齐全;F0 免费层 0.5M 字符/月足够起步。单词按 ~10 字符计,1 万个词约 10 万字符,付费成本仅约 $1.5 量级——**成本极低**,适合做正式批量合成兜底。
- **OpenAI TTS**:**不推荐**。voice 不以 locale 区分,无法稳定区分英/美音(靠提示词诱导口音,不可控),且按 token/字符计费并不便宜。
- **Google Cloud TTS**:功能与 Azure 同级,免费层更慷慨(Neural2 免 1M 字符/月),但无免费接口(edge-tts)那样的零成本路径;与 Azure 二选一即可。

### 设备端/内置 TTS

- **Android 系统 TTS**:`TextToSpeech` 通过 Locale 选语音,引擎可插拔(Google 语音服务、Samsung 等)。**英/美音一般都有,但具体 voice 与质量因设备而异**;部分引擎 voice 标 `network_required`(需要联网),可用 `synthesizeToFile` 把合成结果写入文件做缓存。免费、零网络依赖(引擎离线时)。
- **Web Speech API**:`speechSynthesis` 的 voice 由浏览器/OS 提供,**英/美音可用性、音质、离线行为跨浏览器差异大,不可保证**(Chrome 部分 voice 走网络)。**没有合成到文件的能力**,因此"发音结果本地缓存"在纯 Web 端只能缓存 voice 选择,无法缓存音频本身。这是 Web 端硬伤。
- **flutter_tts**:双端一套 API 封装以上两者;`getVoices()` 返回含 locale 与 `network_required` 的 voice 列表,可在运行时筛选 en-GB/en-US 并判断离线。注意 `synthesizeToFile` 在 Web 不支持。**若选 Flutter 栈,这是设备端首选封装**。
- **react-native-tts**:仅 Android+iOS,Web 需自己包 speechSynthesis,双实现。**若选 RN 栈,设备端方案要写两套代码**。
- **piper**:本地神经 TTS,离线质量可用,但集成成本高(移动端 JNI/WASM、模型体积),且原仓库 2025-10 已归档(维护迁移到 OHF-Voice/piper1-gpl,注意分支许可证)。短期不建议,可作为未来"纯离线神经音"升级路径。
- **espeak-ng**:极小、全离线,但音质机器人化,不适合词典发音主路径;可作极端兜底。

### 词典音频包(MDD,补充评估)

- MDD 是 MDict 词典的音频资源,社区有大量分享(朗文、剑桥、韦氏等,英/美音都有),质量是真人录音,双端集成容易(就是播放文件)。
- 问题:**覆盖度=词典收词**,生词/用户自定义词没有音频;来源合法性不明,不适合作为产品分发依赖。
- 定位:只能做"常用词离线音频"的增强,不能作为完整 TTS 方案。

## 推荐组合

### 主方案:服务端批量预生成 + 本地打包/缓存(播放本地文件)

单词发音场景的本质是**词表有限、重复播放**:音色固定(固定英音 + 固定美音 voice)、内容不变,天然适合把音频一次性/按需在服务端合成好,打进 App 资源或首次联网时下载缓存,之后**纯本地播放**。

- 合成:edge-tts 免费批量生成(en-GB-SoniaNeural / en-US-AriaNeural 等固定 voice);量大或需要稳定时用 Azure(1 万词约 $1.5)兜底
- 存储:按 `word + 音标(英/美)` 生成 mp3,内置 asset 或 SQLite/文件缓存(首次联网下载,后续离线可播)
- 双端:**Flutter / RN 都只需播放本地文件**,行为 100% 一致,完全离线、零运行时成本
- 英/美音:**区分度最好**(固定专业 Neural voice),质量一致可控
- 缓存:天然满足"发音结果本地缓存"

### 备方案:设备端 TTS(flutter_tts 封装)+ 播放时缓存

针对**用户自定义生词**等主方案未覆盖的词:设备端实时合成。

- Android:系统 TTS 选 en-GB/en-US voice(用 `network_required` 判断离线,可 `synthesizeToFile` 写缓存)
- Web:speechSynthesis 选 voice,离线尽力而为(无法缓存音频,只能缓存 voice 选择)
- 优点:零后端、任意词即时发音、成本为零;缺点:voice/音质随设备与浏览器漂移,双端声音不一致

### 组合逻辑

- 主方案负责"确定性的词典音"(绝大多数场景,离线、一致、零成本)
- 备方案兜底"新词/生词"(即时合成,可接受质量浮动)
- 缓存目录统一:主方案缓存音频文件,备方案缓存 voice 选择与(Android)合成文件

### 对 #2 技术栈选型的影响

- 主方案对 Flutter/RN **无差别**(纯文件播放)
- 备方案:Flutter 用 flutter_tts 一套插件覆盖双端;**RN 需 react-native-tts + Web 原生 speechSynthesis 两套实现** → 本维度 Flutter 更省力

### 成本最低且英/美音区分度最好的方案

**edge-tts(免费)**——区分度与 Azure Neural 相同(同源 voice),成本为零;代价是非官方接口、无 SLA,故将其限定在"一次性批量预生成"用途,避免运行时依赖。

### 结论速览

| 需求 | 主方案满足度 | 备方案满足度 |
|---|---|---|
| 英/美音区分 | 固定 voice,优 | 运行时选 voice,中 |
| 本地缓存 | 音频文件缓存,优 | Web 端只能缓存 voice 选择,中 |
| 离线 | 缓存后完全离线,优 | Android 可离线,Web 不可保证,中 |
| 成本 | 近乎为零 | 零 |
| Android+Web 双端 | 优(纯文件) | Flutter 优 / RN 需双实现 |
