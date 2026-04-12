import common from '@ohos.app.ability.common';
import { CacheStrategy, ImageKnife } from '@ohos/imageknifepro';
import { Logger } from './Logger';

export interface ImageCacheConfig {
    maxCount?: number;
    maxDiskUsage?: number;
    directory?: string;
    maxRequests?: number;
}

export class ImageCacheManager {
    private static readonly TAG: string = 'ImageCacheManager';
    private static readonly DEFAULT_MAX_COUNT: number = 48;
    private static readonly DEFAULT_MAX_DISK_USAGE: number = 64 * 1024 * 1024;
    private static readonly DEFAULT_DIRECTORY: string = 'smart-image-cache';
    private static readonly DEFAULT_MAX_REQUESTS: number = 6;

    private static initTask?: Promise<boolean>;

    static async ensureReady(context: common.UIAbilityContext, config?: ImageCacheConfig): Promise<boolean> {
        const imageKnife = ImageKnife.getInstance();
        imageKnife.setMaxRequests(config?.maxRequests ?? ImageCacheManager.DEFAULT_MAX_REQUESTS);

        if (imageKnife.isFileCacheInit()) {
            return true;
        }

        if (!ImageCacheManager.initTask) {
            ImageCacheManager.initTask = ImageCacheManager.initInternal(imageKnife, context, config);
        }

        return await ImageCacheManager.initTask;
    }

    private static async initInternal(
        imageKnife: ImageKnife,
        context: common.UIAbilityContext,
        config?: ImageCacheConfig
    ): Promise<boolean> {
        try {
            await imageKnife.initFileCache(
                context,
                config?.maxCount ?? ImageCacheManager.DEFAULT_MAX_COUNT,
                config?.maxDiskUsage ?? ImageCacheManager.DEFAULT_MAX_DISK_USAGE,
                config?.directory ?? ImageCacheManager.DEFAULT_DIRECTORY
            );
            const ready = imageKnife.isFileCacheInit();
            Logger.info(ImageCacheManager.TAG, 'File cache initialized');
            return ready;
        } catch (error) {
            Logger.warn(ImageCacheManager.TAG, 'File cache init failed', `${error}`);
            return false;
        } finally {
            ImageCacheManager.initTask = undefined;
        }
    }

    static isReady(): boolean {
        return ImageKnife.getInstance().isFileCacheInit();
    }

    static summary(): string {
        const imageKnife = ImageKnife.getInstance();
        if (!imageKnife.isFileCacheInit()) {
            return 'File cache unavailable. SmartImage will still use memory cache and local resources.';
        }

        const fileCount = imageKnife.getCurrentCacheNum(CacheStrategy.FILE) ?? 0;
        const fileSize = imageKnife.getCurrentCacheSize(CacheStrategy.FILE) ?? 0;
        const fileLimit = imageKnife.getCacheLimitSize(CacheStrategy.FILE) ?? 0;
        const memoryCount = imageKnife.getCurrentCacheNum(CacheStrategy.MEMORY) ?? 0;
        return `File cache ${fileCount} items / ${ImageCacheManager.formatBytes(fileSize)}, limit ${ImageCacheManager.formatBytes(fileLimit)}; memory cache ${memoryCount} items`;
    }

    static async clearAll(): Promise<void> {
        const imageKnife = ImageKnife.getInstance();
        imageKnife.removeAllMemoryCache();
        if (imageKnife.isFileCacheInit()) {
            await imageKnife.removeAllFileCache();
        }
    }

    static formatBytes(size: number): string {
        if (size < 1024) {
            return `${size} B`;
        }
        if (size < 1024 * 1024) {
            return `${(size / 1024).toFixed(1)} KB`;
        }
        return `${(size / (1024 * 1024)).toFixed(1)} MB`;
    }
}
