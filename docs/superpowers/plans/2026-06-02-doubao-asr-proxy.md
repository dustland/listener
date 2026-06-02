# Doubao ASR Direct SDK Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Apple Speech as the primary listening ASR path with direct Doubao/Volcengine iOS streaming ASR SDK access.

**Architecture:** The iOS app uses the Volcengine/Doubao Speech SDK as the primary streaming ASR engine for listening mode. Build-time GitHub Secrets inject the Doubao AppID, Access Token, and Resource ID into the app for TestFlight validation. Apple Speech remains an explicit fallback only; a proxy can be added later if public distribution requires quota control or provider switching.

**Tech Stack:** Swift/SwiftUI, AVAudioEngine, CocoaPods, `SpeechEngineAsrToB` or `SpeechEngineToB`, Volcengine Doubao BigModel Streaming ASR.

---

### Task 1: Add Build-Time Doubao ASR Secrets

**Files:**
- Modify: `.github/workflows/testflight.yml`
- Modify: `DialectListener/Info.plist`
- Modify: `DEPLOYMENT.md`

- [x] Add `DOUBAO_ASR_APP_ID`, `DOUBAO_ASR_ACCESS_TOKEN`, and `DOUBAO_ASR_RESOURCE_ID` build settings.
- [x] Inject those build settings into `Info.plist`.
- [x] Validate the required secrets in GitHub Actions.
- [x] Document where each secret comes from and whether the token needs a `Bearer;` prefix.

### Task 2: Add ASR Provider Settings

**Files:**
- Modify: `DialectListener/Models/AppSettings.swift`
- Modify: `DialectListener/Views/SettingsView.swift`

- [ ] Add `ASRProvider` enum with `doubao`, `aliyun`, and `appleFallback`.
- [ ] Add persisted `asrProvider` and `asrProxyURL` settings.
- [ ] Add a Settings section named `ASR` with provider picker and proxy URL text field.
- [ ] Default provider to `doubao`.
- [ ] Keep Apple fallback available for no-network or SDK failures, but label it clearly as fallback.

### Task 3: Define Streaming ASR Event Model

**Files:**
- Create: `DialectListener/Services/StreamingASRService.swift`
- Modify: `DialectListener/Services/AppleASRService.swift`

- [ ] Define `ASRLanguage` values: `cantonese`, `mandarin`, `english`, `unknown`.
- [ ] Define `StreamingASREvent` with `id`, `start`, `end`, `text`, `language`, `confidence`, and `isFinal`.
- [ ] Define `StreamingASRServiceProtocol` with `requestAuthorization()`, `start(onEvent:onError:)`, `appendAudioBuffer(_:)`, and `stop()`.
- [ ] Wrap `AppleASRService` in an `AppleFallbackStreamingASRService` adapter so fallback has the same event interface.

### Task 4: Add Doubao SDK Dependency

**Files:**
- Create: `Podfile`
- Modify: `.github/workflows/testflight.yml`

- [ ] Add CocoaPods sources `https://github.com/CocoaPods/Specs.git` and `https://github.com/volcengine/volcengine-specs.git`.
- [ ] Add the Volcengine ASR SDK pod. Prefer `SpeechEngineAsrToB`; use `SpeechEngineToB` only if the BigModel ASR SDK sample requires it.
- [ ] Add required network dependency if the selected SDK version requires `SocketRocket`.
- [ ] Run `pod install --repo-update` in GitHub Actions before archive.
- [ ] Change archive/export commands to build the generated workspace if CocoaPods creates one.

### Task 5: Add Doubao Direct ASR Client In iOS

**Files:**
- Create: `DialectListener/Services/DoubaoSDKASRService.swift`
- Modify: `DialectListener/App/DialectListenerApp.swift`
- Modify: `DialectListener/Managers/SessionManager.swift`

- [ ] Call `SpeechEngine.prepareEnvironment()` once during app startup.
- [ ] Read `DoubaoASRAppID`, `DoubaoASRAccessToken`, and `DoubaoASRResourceID` from `Info.plist`.
- [ ] Configure SDK endpoint `wss://openspeech.bytedance.com` and URI `/api/v3/sauc/bigmodel`.
- [ ] Configure protocol type as Seed.
- [ ] Configure `SE_PARAMS_KEY_ASR_REQ_PARAMS_STRING` with natural sentence cutting, punctuation, and language/mixed Chinese dialect hints where supported.
- [ ] Emit partial events as `recognizing` and final sentence events as `recognized`.
- [ ] If SDK configuration is missing or init fails, surface the error and optionally offer Apple fallback.

### Task 6: Update Session Message Pipeline

**Files:**
- Modify: `DialectListener/Managers/SessionManager.swift`
- Modify: `DialectListener/Models/Models.swift`
- Modify: `DialectListener/Views/MainTabView.swift`

- [ ] Add per-line state: `recognizing`, `recognized`, `converting`, `done`, `uncertain`.
- [ ] Store language and confidence on each transcript line.
- [ ] Show a subtle per-message status label such as `识别中`, `粤语`, `普通话`, or `不确定`.
- [ ] Only run dialect conversion after ASR finalizes a sentence.
- [ ] If ASR language is Cantonese, convert to Mandarin.
- [ ] If ASR language is Mandarin, convert to Cantonese.
- [ ] If ASR language is unknown, display original text without forced translation.

### Task 7: Optional Proxy Later

**Files:**
- Create: `services/asr-proxy/package.json`
- Create: `services/asr-proxy/src/index.ts`
- Create: `services/asr-proxy/README.md`

- [ ] Defer until the direct SDK path proves ASR quality.
- [ ] Use this only for public distribution, quota control, or provider switching.
- [ ] Keep the app/provider protocol compatible with the direct SDK event model.

### Task 8: Verification

**Files:**
- Modify as needed from previous tasks.

- [ ] Run `git diff --check`.
- [ ] Run `plutil -lint DialectListener/Info.plist ExportOptions.plist`.
- [ ] Run GitHub Actions TestFlight workflow.
- [ ] Test on iPhone with three scenarios: nearby self speech, table-distance Cantonese, table-distance Mandarin.
- [ ] Confirm Apple Speech is not used when ASR provider is `doubao`.
- [ ] Confirm missing Doubao credentials fail visibly instead of silently using local ASR.

---

## Required External Inputs

- Volcengine/Doubao Speech AppID.
- Volcengine/Doubao Speech Access Token.
- Volcengine/Doubao BigModel ASR Resource ID, usually `volc.bigasr.sauc.duration`.
