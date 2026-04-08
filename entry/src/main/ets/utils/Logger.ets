import { hilog } from '@kit.PerformanceAnalysisKit';
import { SafeJsonUtils } from './SafeJsonUtils';

type LogData = Object | string | number | boolean | null | undefined;

export class Logger {
    private static readonly DOMAIN: number = 0x0000;
    private static readonly DEFAULT_TAG: string = 'ImageComponent';

    static debug(message: string, data?: LogData, tag: string = Logger.DEFAULT_TAG): void {
        hilog.debug(Logger.DOMAIN, tag, '%{public}s', Logger.buildMessage(message, data));
    }

    static info(message: string, data?: LogData, tag: string = Logger.DEFAULT_TAG): void {
        hilog.info(Logger.DOMAIN, tag, '%{public}s', Logger.buildMessage(message, data));
    }

    static warn(message: string, data?: LogData, tag: string = Logger.DEFAULT_TAG): void {
        hilog.warn(Logger.DOMAIN, tag, '%{public}s', Logger.buildMessage(message, data));
    }

    static error(message: string, data?: LogData, tag: string = Logger.DEFAULT_TAG): void {
        hilog.error(Logger.DOMAIN, tag, '%{public}s', Logger.buildMessage(message, data));
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
