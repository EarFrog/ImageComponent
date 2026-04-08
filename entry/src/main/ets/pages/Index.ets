import common from '@ohos.app.ability.common';
import {
    CacheStrategy,
    ImageKnife,
    ImageKnifeOption,
    ImageKnifeView,
    TransformationType
} from '@ohos/imageknifepro';

@Entry
@Component
struct Index {
    private readonly remoteSources: string[] = [
        'https://www.openharmony.cn/_nuxt/img/logo.dcf95b3.png',
        'https://img0.baidu.com/it/u=3023852317,2734422755&fm=253&fmt=auto&app=138&f=PNG?w=500&h=500'
    ];

    @State private demoReady: boolean = false;
    @State private currentRemoteIndex: number = 0;
    @State private cacheReady: boolean = false;
    @State private networkProgress: number = 0;
    @State private networkStatus: string = 'Waiting for network image';
    @State private networkMeta: string = 'Image size, request state and render info will appear here.';
    @State private cacheSummary: string = 'File cache is not initialized yet.';
    @State private lastCachePath: string = 'No preload has been executed.';

    @State private heroOption: ImageKnifeOption = new ImageKnifeOption();
    @State private localOption: ImageKnifeOption = new ImageKnifeOption();
    @State private effectOption: ImageKnifeOption = new ImageKnifeOption();
    @State private errorOption: ImageKnifeOption = new ImageKnifeOption();

    aboutToAppear(): void {
        if (!this.demoReady) {
            this.setupDemoOptions();
            this.demoReady = true;
        }
        this.prepareImageKnife();
    }

    private setupDemoOptions(): void {
        this.heroOption.loadSrc = this.currentRemoteSource();
        this.heroOption.placeholderSrc = $r('app.media.background');
        this.heroOption.errorSrc = $r('app.media.foreground');
        this.heroOption.objectFit = ImageFit.Contain;
        this.heroOption.placeholderObjectFit = ImageFit.Cover;
        this.heroOption.errorObjectFit = ImageFit.Cover;
        this.heroOption.border = { radius: 28 };
        this.heroOption.writeCacheStrategy = CacheStrategy.DEFAULT;
        this.heroOption.progressListener = (progress: number) => {
            this.networkProgress = progress;
            this.networkStatus = `Downloading network image ${progress}%`;
        };
        this.heroOption.onLoadListener = {
            onLoadStart: () => {
                this.networkProgress = 0;
                this.networkStatus = 'Starting network image request';
            },
            onLoadSuccess: (imageInfo) => {
                this.networkStatus = 'Network image loaded successfully';
                this.networkMeta = `Source ${imageInfo.imageWidth} x ${imageInfo.imageHeight}, HTTP ${imageInfo.httpCode ?? '-'}, request ${imageInfo.requestId}`;
            },
            onLoadFailed: (err, imageInfo) => {
                this.networkStatus = 'Network image failed to load';
                this.networkMeta = `${err}, phase ${imageInfo.errorInfo?.phase ?? 'unknown'}, code ${imageInfo.errorInfo?.code ?? '-'}`;
            }
        };
        this.heroOption.onComplete = (event) => {
            if (event) {
                this.networkMeta =
                    `${this.networkMeta}\nComponent ${event.componentWidth} x ${event.componentHeight}, content ${event.contentWidth} x ${event.contentHeight}`;
            }
        };

        this.localOption.loadSrc = $r('app.media.startIcon');
        this.localOption.placeholderSrc = $r('app.media.foreground');
        this.localOption.errorSrc = $r('app.media.foreground');
        this.localOption.objectFit = ImageFit.Cover;
        this.localOption.border = { radius: 24 };

        this.effectOption.loadSrc = $r('app.media.foreground');
        this.effectOption.placeholderSrc = $r('app.media.background');
        this.effectOption.errorSrc = $r('app.media.startIcon');
        this.effectOption.objectFit = ImageFit.Cover;
        this.effectOption.transformationOption = {
            type: TransformationType.CROP_CIRCLE_WITH_BORDER,
            f32: [8, 255, 255, 255]
        };

        this.errorOption.loadSrc = 'https://example.invalid/not-found.png';
        this.errorOption.placeholderSrc = $r('app.media.background');
        this.errorOption.errorSrc = $r('app.media.foreground');
        this.errorOption.objectFit = ImageFit.Cover;
        this.errorOption.errorObjectFit = ImageFit.Contain;
        this.errorOption.border = { radius: 24 };
    }

    private async prepareImageKnife(): Promise<void> {
        const imageKnife = ImageKnife.getInstance();
        imageKnife.setMaxRequests(4);

        try {
            if (!imageKnife.isFileCacheInit()) {
                const context = getContext(this) as common.UIAbilityContext;
                await imageKnife.initFileCache(context, 48, 64 * 1024 * 1024, 'image-demo-cache');
            }
            this.cacheReady = imageKnife.isFileCacheInit();
            this.refreshCacheSummary();
        } catch (error) {
            this.cacheReady = false;
            this.cacheSummary = `File cache init failed: ${this.errorText(error)}`;
        }
    }

    private currentRemoteSource(): string {
        return this.remoteSources[this.currentRemoteIndex];
    }

    private switchRemoteImage(): void {
        this.currentRemoteIndex = (this.currentRemoteIndex + 1) % this.remoteSources.length;
        this.heroOption.loadSrc = this.currentRemoteSource();
        this.networkProgress = 0;
        this.networkStatus = 'Image source switched. Waiting for reload.';
        this.networkMeta = `Current URL: ${this.currentRemoteSource()}`;
    }

    private async preloadCurrentImage(): Promise<void> {
        this.networkStatus = 'Preloading current image into file cache';
        try {
            this.lastCachePath = await ImageKnife.getInstance().preloadCache(this.currentRemoteSource());
            this.networkStatus = this.lastCachePath.length > 0 ? 'Preload completed and file cache was written' : 'Preload completed but returned no cache path';
            this.refreshCacheSummary();
        } catch (error) {
            this.networkStatus = `Preload failed: ${this.errorText(error)}`;
        }
    }

    private async clearCache(): Promise<void> {
        const imageKnife = ImageKnife.getInstance();
        imageKnife.removeAllMemoryCache();
        if (imageKnife.isFileCacheInit()) {
            try {
                await imageKnife.removeAllFileCache();
                this.lastCachePath = 'Cache has been cleared.';
            } catch (error) {
                this.lastCachePath = `File cache clear failed: ${this.errorText(error)}`;
            }
        }
        this.refreshCacheSummary();
    }

    private refreshCacheSummary(): void {
        const imageKnife = ImageKnife.getInstance();
        if (!imageKnife.isFileCacheInit()) {
            this.cacheSummary = 'Only memory cache is available because file cache is not ready.';
            return;
        }

        const fileCount = imageKnife.getCurrentCacheNum(CacheStrategy.FILE) ?? 0;
        const fileSize = imageKnife.getCurrentCacheSize(CacheStrategy.FILE) ?? 0;
        const fileLimit = imageKnife.getCacheLimitSize(CacheStrategy.FILE) ?? 0;
        const memoryCount = imageKnife.getCurrentCacheNum(CacheStrategy.MEMORY) ?? 0;
        this.cacheSummary =
            `File cache ${fileCount} items / ${this.formatBytes(fileSize)}, limit ${this.formatBytes(fileLimit)}; memory cache ${memoryCount} items`;
    }

    private formatBytes(size: number): string {
        if (size < 1024) {
            return `${size} B`;
        }
        if (size < 1024 * 1024) {
            return `${(size / 1024).toFixed(1)} KB`;
        }
        return `${(size / (1024 * 1024)).toFixed(1)} MB`;
    }

    private errorText(error: Object): string {
        return `${error}`;
    }

    @Builder
    private sectionTitle(title: string, desc: string) {
        Column({ space: 6 }) {
            Text(title)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1D2736')
            Text(desc)
                .fontSize(13)
                .lineHeight(20)
                .fontColor('#5B6576')
        }
        .alignItems(HorizontalAlign.Start)
    }

    @Builder
    private infoCard(title: string, desc: string, option: ImageKnifeOption) {
        Column({ space: 12 }) {
            ImageKnifeView({ imageKnifeOption: option })
                .width('100%')
                .height(170)

            Text(title)
                .fontSize(17)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1F2937')

            Text(desc)
                .fontSize(12)
                .lineHeight(18)
                .fontColor('#5B6576')
        }
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(28)
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
    }

    build() {
        Scroll() {
            Column({ space: 18 }) {
                this.sectionTitle('ImageKnife Demo Page', 'This page demonstrates local assets, network loading, placeholders, failure state, transformations and cache controls.')

                Column({ space: 14 }) {
                    ImageKnifeView({ imageKnifeOption: this.heroOption })
                        .width('100%')
                        .height(240)
                        .backgroundColor('#EAF2FF')
                        .borderRadius(32)

                    Text('Primary Network Sample')
                        .fontSize(18)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#152033')

                    Text(this.networkStatus)
                        .fontSize(13)
                        .fontColor('#3563E9')

                    Text(`Download progress: ${this.networkProgress}%`)
                        .fontSize(12)
                        .fontColor('#5B6576')

                    Text(this.networkMeta)
                        .fontSize(12)
                        .lineHeight(18)
                        .fontColor('#5B6576')

                    Text(this.cacheSummary)
                        .fontSize(12)
                        .lineHeight(18)
                        .fontColor('#5B6576')

                    Text(`Last preload path: ${this.lastCachePath}`)
                        .fontSize(12)
                        .lineHeight(18)
                        .fontColor('#5B6576')

                    Row({ space: 10 }) {
                        Button('Switch Image')
                            .type(ButtonType.Capsule)
                            .backgroundColor('#3563E9')
                            .fontColor('#FFFFFF')
                            .onClick(() => this.switchRemoteImage())

                        Button('Preload Cache')
                            .type(ButtonType.Capsule)
                            .backgroundColor('#0EA5A4')
                            .fontColor('#FFFFFF')
                            .onClick(() => this.preloadCurrentImage())

                        Button('Clear Cache')
                            .type(ButtonType.Capsule)
                            .backgroundColor('#F97316')
                            .fontColor('#FFFFFF')
                            .onClick(() => this.clearCache())
                    }
                }
                .padding(20)
                .backgroundColor('#FFFFFF')
                .borderRadius(32)
                .alignItems(HorizontalAlign.Start)

                this.sectionTitle('Static Assets And Effects', 'The next two cards show a bundled asset and a transformed image with circular crop and border.')

                Row({ space: 14 }) {
                    this.infoCard(
                        'Bundled Asset',
                        'Loads an in-app resource directly and keeps rounded corners with Cover behavior.',
                        this.localOption
                    )

                    this.infoCard(
                        'Transformed Asset',
                        'Uses ImageKnife transformationOption to apply a circular crop and white border.',
                        this.effectOption
                    )
                }
                .width('100%')

                this.sectionTitle('Failure State', 'This card intentionally requests an invalid URL so the placeholder and errorSrc fallback are visible.')

                Column({ space: 12 }) {
                    ImageKnifeView({ imageKnifeOption: this.errorOption })
                        .width('100%')
                        .height(180)

                    Text('Error Fallback')
                        .fontSize(17)
                        .fontWeight(FontWeight.Medium)
                        .fontColor('#1F2937')

                    Text('When loading fails, the view falls back to a local errorSrc. This is useful for empty states, fallback art or default covers.')
                        .fontSize(12)
                        .lineHeight(18)
                        .fontColor('#5B6576')

                    Text(this.cacheReady ? 'File cache is enabled, so network images also participate in disk caching.' : 'When file cache is unavailable, bundled assets and memory cache still work.')
                        .fontSize(12)
                        .lineHeight(18)
                        .fontColor('#5B6576')
                }
                .padding(16)
                .backgroundColor('#FFFFFF')
                .borderRadius(28)
                .alignItems(HorizontalAlign.Start)
            }
            .padding({ left: 18, right: 18, top: 22, bottom: 30 })
            .width('100%')
            .alignItems(HorizontalAlign.Start)
        }
        .scrollBar(BarState.Auto)
        .backgroundColor('#F4F7FB')
        .width('100%')
        .height('100%')
    }
}
