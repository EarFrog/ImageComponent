import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';
import { Logger } from '../utils/Logger';

const TAG = 'EntryBackupAbility';

export default class EntryBackupAbility extends BackupExtensionAbility {
    async onBackup() {
        Logger.info(TAG, 'EntryBackupAbility onBackup ok');
        await Promise.resolve();
    }

    async onRestore(bundleVersion: BundleVersion) {
        Logger.info(TAG, 'EntryBackupAbility onRestore ok', bundleVersion);
        await Promise.resolve();
    }
}
