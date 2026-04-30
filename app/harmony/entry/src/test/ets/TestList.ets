import cameraControllerTest from './camera/CameraControllerTest';
import companionSessionServiceTest from './companion/CompanionSessionServiceTest';
import deviceDiscoveryServiceTest from './companion/DeviceDiscoveryServiceTest';
import distributedTransportTest from './companion/DistributedTransportTest';
import previewSyncServiceTest from './companion/PreviewSyncServiceTest';
import remoteShutterTest from './companion/RemoteShutterTest';
import navigationFlowTest from './navigation/NavigationFlowTest';
import keypointMatcherTest from './poseDetection/KeypointMatcherTest';
import poseAlignmentServiceTest from './poseDetection/PoseAlignmentServiceTest';
import poseDetectionTest from './poseDetection/PoseDetectionTest';
import poseTemplateTest from './poseTemplate/PoseTemplateTest';
import settingsTest from './settings/SettingsTest';
import styleAdviceTest from './styleAdvice/StyleAdviceTest';

export default function registerTests(): void {
  poseTemplateTest();
  companionSessionServiceTest();
  remoteShutterTest();
  distributedTransportTest();
  deviceDiscoveryServiceTest();
  previewSyncServiceTest();
  cameraControllerTest();
  navigationFlowTest();
  settingsTest();
  keypointMatcherTest();
  poseDetectionTest();
  poseAlignmentServiceTest();
  styleAdviceTest();
}
