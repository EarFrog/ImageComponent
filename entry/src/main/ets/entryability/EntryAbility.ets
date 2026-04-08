import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { Logger } from '../utils/Logger';

export default class EntryAbility extends UIAbility {
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        Logger.info('EntryAbility onCreate', { want: want, launchParam: launchParam }, 'EntryAbility');
    }

    onDestroy(): void {
        Logger.info('EntryAbility onDestroy', undefined, 'EntryAbility');
    }

    onWindowStageCreate(_windowStage: window.WindowStage): void {
        Logger.info('EntryAbility onWindowStageCreate', undefined, 'EntryAbility');
    }

    onWindowStageDestroy(): void {
        Logger.info('EntryAbility onWindowStageDestroy', undefined, 'EntryAbility');
    }

    onForeground(): void {
        Logger.info('EntryAbility onForeground', undefined, 'EntryAbility');
    }

    onBackground(): void {
        Logger.info('EntryAbility onBackground', undefined, 'EntryAbility');
    }
}
