import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';
import { Logger } from '../utils/Logger';

export default class EntryBackupAbility extends BackupExtensionAbility {
    async onBackup() {
        Logger.info('EntryBackupAbility onBackup ok', undefined, 'EntryBackupAbility');
        await Promise.resolve();
    }

    async onRestore(bundleVersion: BundleVersion) {
        Logger.info('EntryBackupAbility onRestore ok', bundleVersion, 'EntryBackupAbility');
        await Promise.resolve();
    }
}
