# Easy Shot HarmonyOS Skeleton

This directory contains the checked-in source skeleton for the HarmonyOS NEXT app.

Source skeleton across 11 routed pages, multiple feature modules, 1 reusable component, 30 test suites, and dark mode theme.

## Completed Modules

- **DevEco shell**: root and entry `build-profile.json5` (with signing config placeholder), `hvigorfile.ts`, `module.json5` (icon + label + CAMERA/DISTRIBUTED_DATASYNC/INTERNET permissions), `oh-package.json5`, and `app.json5` (icon + label)
- **Pose template system**: template model with JSON parser, repository interface, rawfile-backed repository, store state management, manifest, and 5 seeded JSON templates
- **Template UI**: template list with featured card on `Index.ets`, dedicated `TemplateDetail.ets` with shooting settings / verbal steps / annotations / skeleton data
- **Camera Kit integration**: full `CameraController` with Camera Kit preview session, `PhotoOutput` capture with 10s timeout, JPEG buffer extraction via `photoAvailable`, and app sandbox file saving
- **Photo capture and review**: `PhotoReview.ets` with captured photo display, `SaveButton` security component for media library saving, **pose alignment gauge with per-keypoint heatmap** (`KeypointHeatmap` component), and **AI style advice** (scores, composition/pose review, improvement suggestions)
- **Realtime guide**: `GuideOverlayRenderer` shared overlay with composition/subject boxes and prompt layer, `GuidePromptSelector`, `PoseAlignmentService` with `detectAndAlign()` pipeline
- **AI Pose Detection**: `PoseDetector` interface, `KeypointMatcher` algorithm (Euclidean distance + per-keypoint quality), `MockPoseDetector` (jitter-based simulation), `MindSporePoseDetector` (Mind Spore Lite placeholder shell)
- **Cloud Style Advice API**: `StyleAdviceClient` interface, `MockStyleAdviceClient` (offline advice generation by score/style), `CloudStyleAdviceClient` (HTTP POST with 15s timeout), `StyleAdviceService` (auto-selects Mock/Cloud based on privacy settings with cloud→mock fallback), and rawfile-backed endpoint config (`rawfile/style_advice/manifest.json`)
- **Companion system**: full session state machine, message envelope for pairing, guide sync, preview frames, review sync, and remote commands, device discovery (**real `DeviceManager` + mock fallback**), command handler, `DistributedTransport` (KV Store auto-sync), `PreviewSyncService` (**adaptive frame sync**: LIVE at 2 FPS / THUMBNAIL at 0.5 FPS / STATE_ONLY), remote shutter E2E with capture callback, remote preview display on CompanionSession page
- **Navigation wiring**: full `router` routing across the current 11 registered pages, including camera/review/history/map, pairing/session, template editing, style guide, and settings flows
- **Settings and privacy**: `SettingsModel` + `SettingsStore` with `@kit.ArkData` Preferences persistence, local-only mode / cloud AI toggle / photo upload consent / default camera facing
- **Review helpers**: `PhotoReviewSideEffects` coordinates review-page metadata persistence and capture notification fallback, while `PhotoReviewViewActions` encapsulates review-page save feedback, button visibility, and route params used by `PhotoReview.ets`
- **Resource system**: localized zh-CN / en-US strings, 25 theme colors (light + dark), 14 dimension tokens, 4 app icon PNGs
- **Dark mode**: complete `resources/dark/element/color.json` with 25 color overrides for system dark theme
- **i18n wiring**: current page-layer UI labels, placeholders, accessibility copy, and readiness/failure states are wired through `app.string` resources, with `LocaleHelper` used where runtime string lookup is needed
- **Test skeleton**: `@ohos/hypium` dependency, 30 test suites, shared `TestList.ets` registration
- **Code review**: two comprehensive audits — capture reentrancy guard, API response validation, flush error logging, StyleTags i18n via LocaleHelper

## Source Tree

```
entry/src/main/ets/
  components/            KeypointHeatmap (pose analysis ring gauge + per-keypoint bars)
  core/session/          SessionState, SessionMessage, SessionSerializer,
                         SessionFallbackPolicy
  core/locale/           LocaleHelper (dynamic runtime i18n via resourceManager)
  core/style/            StyleTags (i18n-aware via LocaleHelper)
  entryability/          EntryAbility
  features/camera/       CameraController (Camera Kit preview + PhotoOutput capture),
                         CameraGuideActions (review sync + video recording control helper)
  features/bluetooth/    BluetoothPairingActions (page connection/error helper),
                         BluetoothPairingService (BLE scan/connect wrapper)
  features/companion/    CompanionSessionService, DeviceDiscovery (DeviceManager + mock),
                         CompanionSessionPreviewActions, CommandHandler,
                         PreviewSyncService (adaptive frame sync), DistributedTransport
                         (KV Store cross-device messaging)
  features/poseDetection/ PoseDetector interface, KeypointMatcher, MockPoseDetector,
                          MindSporePoseDetector (Mind Spore Lite shell)
  features/poseTemplate/ PoseTemplate model, Repository, RawfileRepository,
                         PoseTemplateStore, IndexViewActions, StyleGuideViewActions
  features/realtimeGuide/ GuideOverlayRenderer, GuidePromptSelector, PoseAlignmentService
  features/review/       PhotoReviewSideEffects (metadata persistence + capture notification helper),
                         PhotoReviewViewActions (save feedback + route params helper)
  features/settings/     SettingsModel, SettingsStore, SettingsViewActions
                         (Preferences persistence + page UI helper)
  features/styleAdvice/  StyleAdviceModel, StyleAdviceClient, MockStyleAdviceClient,
                         CloudStyleAdviceClient, StyleAdviceService
  pages/                 Index, CameraGuide, PhotoReview, PhotoHistory, DevicePairing,
                         BluetoothPairing, TemplateEditor, CompanionSession, Settings,
                         StyleGuide, PhotoMap (11 registered pages in main_pages.json)

entry/src/main/resources/
  base/element/          string.json (zh-CN localized strings), color.json (25), float.json (14)
  base/media/            startIcon.png, foreground.png, background.png
  base/profile/          main_pages.json (11 pages)
  dark/element/          color.json (25 dark theme overrides)
  en_US/element/         string.json (en-US localized strings)
  rawfile/models/        manifest.json (MindSpore model config)
  rawfile/style_advice/  manifest.json (cloud style advice endpoint config)
  rawfile/templates/     manifest.json, 5 template JSONs

entry/src/test/ets/
  audio/                 AudioCueServiceTest (2 tests)
  bluetooth/             BluetoothPairingActionsTest (4 tests), BluetoothPairingServiceTest (3 tests)
  camera/                CameraControllerTest (4 tests), CameraGuideActionsTest (14 tests)
  companion/             CompanionSessionActionsTest (5), CompanionSessionPreviewActionsTest (5),
                         DevicePairingActionsTest (4),
                         CompanionSessionServiceTest (6), RemoteShutterTest (4),
                         DistributedTransportTest (4), DeviceDiscoveryServiceTest (5),
                         PreviewSyncServiceTest (10)
  history/               PhotoHistoryServiceTest (2 tests)
  map/                   PhotoMapServiceTest (2 tests)
                         PhotoMapViewActionsTest (4 tests)
  navigation/            IndexViewActionsTest (5 tests), NavigationFlowTest (3 tests)
  review/                PhotoReviewSideEffectsTest (4 tests), PhotoReviewViewActionsTest (9 tests)
  notification/          NotificationServiceTest (3 tests)
  poseDetection/         KeypointMatcherTest (6 tests), PoseDetectionTest (12 tests),
                         PoseAlignmentServiceTest (10)
  poseTemplate/          PoseTemplateTest (6 tests)
  share/                 PhotoShareServiceTest (2 tests)
  settings/              SettingsTest (5 tests), SettingsViewActionsTest (6 tests)
  styleAdvice/           StyleAdviceTest (10 tests), StyleGuideViewActionsTest (6 tests)
  TestList.ets           Registration entry (30 suites)
```

## Not Yet Done

The remaining items are primarily external asset/backend deliveries and on-device validation rather than obvious code-side UI flow gaps.

- Camera integration polish: frame pipeline tuning and verified on-device preview/capture flow
- Real AI model: add actual Mind Spore Lite `.ms` model file for on-device pose estimation at `rawfile/models/pose_estimation.ms` or `${filesDir}/models/pose_estimation.ms`
- Audio cues: add real `rawfile/audio/shutter.ogg`, `countdown_tick.ogg`, and `countdown_end.ogg` assets
- Cloud backend: deploy actual style advice API server and set `rawfile/style_advice/manifest.json` to a non-placeholder API base
- Asset pipeline: replace placeholder avatar PNGs under `rawfile/avatars/**` with production assets and continue template/media curation
- Test layer: on-device test execution verification

## Getting Started

1. Open `app/harmony` in DevEco Studio and let the IDE sync the project shell.
2. Add local signing configuration and SDK-specific generated artifacts on the target machine.
3. Complete the remaining external deliveries and on-device verification items listed above on top of the checked-in source and config skeleton.

> **详细指南**：Windows 环境下请参考 [Windows 调试编译指南](../../docs/dev/WINDOWS_DEBUG_GUIDE.md)；macOS 环境下请参考 [macOS 调试编译指南](../../docs/macos-harmonyos-dev-setup.md)。两份文档都覆盖 DevEco Studio 安装、SDK 配置、签名、编译、设备连接、调试和测试。
