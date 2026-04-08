import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { Logger } from '../utils/Logger';

const TAG = 'EntryAbility';
export default class EntryAbility extends UIAbility {
    onCreate(_want: Want, _launchParam: AbilityConstant.LaunchParam): void {
        Logger.debug(TAG, 'onCreate');
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
        Logger.info(TAG, 'EntryAbility onWindowStageCreate');
        windowStage.loadContent('pages/Index', (err) => {
            if (err.code) {
                Logger.error(TAG, 'loadContent failed', err as Object);
                return;
            }
            Logger.info(TAG, 'loadContent success');
        });
    }

    onWindowStageDestroy(): void {
        Logger.info(TAG, 'EntryAbility onWindowStageDestroy');
    }

    onForeground(): void {
        Logger.info(TAG, 'EntryAbility onForeground');
    }

    onBackground(): void {
        Logger.info(TAG, 'EntryAbility onBackground');
    }
}
