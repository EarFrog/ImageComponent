import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { bundleManager, BundleFlag } from '@kit.AbilityKit';
import { Logger } from '../utils/Logger';

const TAG = 'EntryAbility';

async function initLogger(): Promise<void> {
    try {
        const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
        const isDebug = bundleInfo.appInfo?.debug ?? false;
        Logger.setDebugEnabled(isDebug);
    } catch {
        // Default to enabled if cannot determine
        Logger.setDebugEnabled(true);
    }
}

export default class EntryAbility extends UIAbility {
    async onCreate(_want: Want, _launchParam: AbilityConstant.LaunchParam): Promise<void> {
        await initLogger();
        Logger.info(TAG, 'onCreate');
        try {
            this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
        } catch (err) {
            Logger.error(TAG, 'EntryAbility setColorMode failed', err as Object);
        }
    }

    onDestroy(): void {
        Logger.info(TAG, 'onDestroy');
    }

    onWindowStageCreate(windowStage: window.WindowStage): void {
        Logger.info(TAG, 'onWindowStageCreate');
        windowStage.loadContent('pages/Index', (err) => {
            if (err.code) {
                Logger.error(TAG, 'loadContent failed', err as Object);
                return;
            }
            Logger.info(TAG, 'loadContent success');
        });
    }

    onWindowStageDestroy(): void {
        Logger.info(TAG, 'onWindowStageDestroy');
    }

    onForeground(): void {
        Logger.info(TAG, 'onForeground');
    }

    onBackground(): void {
        Logger.info(TAG, 'onBackground');
    }
}