import { hilog } from '@kit.PerformanceAnalysisKit';
import { SafeJsonUtils } from './SafeJsonUtils';

type LogData = Object | string | number | boolean | null | undefined;

export class Logger {
    private static readonly DOMAIN: number = 0x0000;
    private static readonly DEFAULT_TAG: string = 'ImageComponent';

    static debug(TAG: string = '', message: string, data?: LogData): void {
        hilog.debug(Logger.DOMAIN, Logger.DEFAULT_TAG, `[${TAG}]: %{public}s`, Logger.buildMessage(message, data));
    }

    static info(TAG: string = '', message: string, data?: LogData): void {
        hilog.info(Logger.DOMAIN, Logger.DEFAULT_TAG, `[${TAG}]: %{public}s`, Logger.buildMessage(message, data));
    }

    static warn(TAG: string = '', message: string, data?: LogData): void {
        hilog.warn(Logger.DOMAIN, Logger.DEFAULT_TAG, `[${TAG}]: %{public}s`, Logger.buildMessage(message, data));
    }

    static error(TAG: string = '', message: string, data?: LogData): void {
        hilog.error(Logger.DOMAIN, Logger.DEFAULT_TAG, `[${TAG}]: %{public}s`, Logger.buildMessage(message, data));
    }

    private static buildMessage(message: string, data?: LogData): string {
        if (data === null || data === undefined) {
            return message;
        }
        return `${message} | ${Logger.toText(data)}`;
    }

    private static toText(data: LogData): string {
        if (typeof data === 'string') {
            return data;
        }
        if (typeof data === 'number' || typeof data === 'boolean') {
            return `${data}`;
        }
        return SafeJsonUtils.stringify(data, '[unserializable]');
    }
}
