# Easy Shot HarmonyOS Skeleton

This directory contains the checked-in source skeleton for the HarmonyOS NEXT app.

**63 source files** across 7 pages, 8 feature modules, 1 reusable component, 9 test suites, 35 test cases, 4 app icon assets, and dark mode theme.

## Completed Modules

- **DevEco shell**: root and entry `build-profile.json5` (with signing config placeholder), `hvigorfile.ts`, `module.json5` (icon + label + CAMERA/DISTRIBUTED_DATASYNC/INTERNET permissions), `oh-package.json5`, and `app.json5` (icon + label)
- **Pose template system**: template model with JSON parser, repository interface, rawfile-backed repository, store state management, manifest, and 2 seeded JSON templates
- **Template UI**: template list with featured card on `Index.ets`, dedicated `TemplateDetail.ets` with shooting settings / verbal steps / annotations / skeleton data
- **Camera Kit integration**: full `CameraController` with Camera Kit preview session, `PhotoOutput` capture with 10s timeout, JPEG buffer extraction via `photoAvailable`, and app sandbox file saving
- **Photo capture and review**: `PhotoReview.ets` with captured photo display, `SaveButton` security component for media library saving, **pose alignment gauge with per-keypoint heatmap** (`KeypointHeatmap` component), and **AI style advice** (scores, composition/pose review, improvement suggestions)
- **Realtime guide**: `GuideOverlayRenderer` shared overlay with composition/subject boxes and prompt layer, `GuidePromptSelector`, `PoseAlignmentService` with `detectAndAlign()` pipeline
- **AI Pose Detection**: `PoseDetector` interface, `KeypointMatcher` algorithm (Euclidean distance + per-keypoint quality), `MockPoseDetector` (jitter-based simulation), `MindSporePoseDetector` (Mind Spore Lite placeholder shell)
- **Cloud Style Advice API**: `StyleAdviceClient` interface, `MockStyleAdviceClient` (offline advice generation by score/style), `CloudStyleAdviceClient` (HTTP POST with 15s timeout), `StyleAdviceService` (auto-selects Mock/Cloud based on privacy settings with cloud→mock fallback)
- **Companion system**: full session state machine, message envelope (11 types including `PREVIEW_FRAME`), device discovery (**real `DeviceManager` + mock fallback**), command handler, `DistributedTransport` (KV Store auto-sync), `PreviewSyncService` (**adaptive frame sync**: LIVE at 2 FPS / THUMBNAIL at 0.5 FPS / STATE_ONLY), remote shutter E2E with capture callback, remote preview display on CompanionSession page
- **Navigation wiring**: full `router` routing across all 7 pages (Index → CameraGuide → PhotoReview, Index → DevicePairing → CompanionSession, Index → Settings), template ID / photo / alignment / keypoint data params passing
- **Settings and privacy**: `SettingsModel` + `SettingsStore` with `@kit.ArkData` Preferences persistence, local-only mode / cloud AI toggle / photo upload consent / default camera facing
- **Resource system**: 76 i18n string entries (zh-CN base + en-US), 18 theme colors (light + dark), 14 dimension tokens, 4 app icon PNGs
- **Dark mode**: complete `resources/dark/element/color.json` with 18 color overrides for system dark theme
- **i18n wiring**: all standalone UI labels replaced with `$r('app.string.xxx')` resource references across 7 pages
- **Test skeleton**: `@ohos/hypium` dependency, 9 test suites, 35 test cases, shared `TestList.ets` registration
- **Code review**: full codebase audit completed — 3 issues fixed (TemplateDetail page registration, capture timeout, toast i18n)

## Source Tree

```
entry/src/main/ets/
  components/            KeypointHeatmap (pose analysis ring gauge + per-keypoint bars)
  core/session/          SessionState, SessionMessage (11 types), SessionSerializer,
                         SessionFallbackPolicy
  core/style/            StyleTags
  entryability/          EntryAbility
  features/camera/       CameraController (Camera Kit preview + PhotoOutput capture)
  features/companion/    CompanionSessionService, DeviceDiscovery (DeviceManager + mock),
                         CommandHandler, PreviewSyncService (adaptive frame sync),
                         DistributedTransport (KV Store cross-device messaging)
  features/poseDetection/ PoseDetector interface, KeypointMatcher, MockPoseDetector,
                          MindSporePoseDetector (Mind Spore Lite shell)
  features/poseTemplate/ PoseTemplate model, Repository, RawfileRepository, PoseTemplateStore
  features/realtimeGuide/ GuideOverlayRenderer, GuidePromptSelector, PoseAlignmentService
  features/settings/     SettingsModel, SettingsStore (Preferences persistence)
  features/styleAdvice/  StyleAdviceModel, StyleAdviceClient, MockStyleAdviceClient,
                         CloudStyleAdviceClient, StyleAdviceService
  pages/                 Index, TemplateDetail, CameraGuide, PhotoReview, DevicePairing,
                         CompanionSession, Settings (7 pages, 6 registered in main_pages.json)

entry/src/main/resources/
  base/element/          string.json (76 zh-CN), color.json (18), float.json (14)
  base/media/            startIcon.png, foreground.png, background.png
  base/profile/          main_pages.json (6 pages)
  dark/element/          color.json (18 dark theme overrides)
  en_US/element/         string.json (76 en-US translations)
  rawfile/templates/     manifest.json, 2 template JSONs

entry/src/test/ets/
  camera/                CameraControllerTest (4 tests)
  companion/             CompanionSessionServiceTest (4), RemoteShutterTest (4),
                         DistributedTransportTest (4)
  navigation/            NavigationFlowTest (3 tests)
  poseDetection/         KeypointMatcherTest (6 tests)
  poseTemplate/          PoseTemplateTest (3 tests)
  settings/              SettingsTest (3 tests)
  styleAdvice/           StyleAdviceTest (4 tests)
  TestList.ets           Registration entry (9 suites, 35 total cases)
```

## Not Yet Done

- Camera integration polish: frame pipeline tuning and verified on-device preview/capture flow
- Real AI model: integrate actual Mind Spore Lite `.ms` model file for on-device pose estimation
- Cloud backend: deploy actual style advice API server (currently uses mock or placeholder endpoint)
- Preview frame provider: wire CameraController frame capture into PreviewSyncService's `frameProvider` callback for real thumbnail generation
- Asset pipeline: avatar images, media resources, and production-ready template content curation
- Test layer: on-device test execution verification

## Getting Started

1. Open `app/harmony` in DevEco Studio and let the IDE sync the project shell.
2. Add local signing configuration and SDK-specific generated artifacts on the target machine.
3. Continue implementing the unfinished modules listed above on top of the checked-in source and config skeleton.
