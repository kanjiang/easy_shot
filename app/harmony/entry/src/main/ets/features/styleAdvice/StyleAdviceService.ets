import { StyleAdvice, StyleAdviceRequest } from './StyleAdviceModel';
import { StyleAdviceClient } from './StyleAdviceClient';
import { MockStyleAdviceClient } from './MockStyleAdviceClient';
import { CloudStyleAdviceClient } from './CloudStyleAdviceClient';
import { settingsStore } from '../settings/SettingsStore';

const mockClient: StyleAdviceClient = new MockStyleAdviceClient();
const cloudClient: StyleAdviceClient = new CloudStyleAdviceClient();

export async function getStyleAdvice(request: StyleAdviceRequest): Promise<StyleAdvice> {
  const settings = settingsStore.getSettings();

  if (settings.localOnlyMode || !settings.enableCloudAdvice) {
    return mockClient.fetchAdvice(request);
  }

  try {
    return await cloudClient.fetchAdvice(request);
  } catch (_error) {
    return mockClient.fetchAdvice(request);
  }
}
