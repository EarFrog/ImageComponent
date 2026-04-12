import common from '@ohos.app.ability.common';
import { ImageKnife } from '@ohos/imageknifepro';
import { SmartImage, SmartImageEvent } from '../components/SmartImage';
import { ImageCacheManager } from '../utils/ImageCacheManager';

@Entry
@Component
struct Index {
    private readonly remoteSources: string[] = [
        'https://www.openharmony.cn/_nuxt/img/logo.dcf95b3.png',
        'https://img0.baidu.com/it/u=3023852317,2734422755&fm=253&fmt=auto&app=138&f=PNG?w=500&h=500'
    ];

    @State private currentRemoteIndex: number = 0;
    @State private networkProgress: number = 0;
    @State private networkStatus: string = 'Waiting for SmartImage request';
    @State private networkMeta: string = 'Image size, HTTP state and render details will appear here.';
    @State private cacheSummary: string = 'Preparing file cache...';
    @State private lastCachePath: string = 'No preload has been executed yet.';

    aboutToAppear(): void {
        this.networkMeta = `Current URL: ${this.currentRemoteSource()}`;
        this.prepareCache();
    }

    private async prepareCache(): Promise<void> {
        const ready = await ImageCacheManager.ensureReady(getContext(this) as common.UIAbilityContext);
        this.cacheSummary = ready
            ? ImageCacheManager.summary()
            : 'File cache init failed. SmartImage will continue with memory cache.';
    }

    private currentRemoteSource(): string {
        return this.remoteSources[this.currentRemoteIndex];
    }

    private handleHeroStateChange(event: SmartImageEvent): void {
        this.networkProgress = event.progress;
        this.networkStatus = event.message;

        const imageSize = event.imageWidth > 0
            ? `${event.imageWidth} x ${event.imageHeight}`
            : 'unknown';
        const httpCode = event.httpCode >= 0 ? `${event.httpCode}` : '-';
        const requestId = event.requestId.length > 0 ? event.requestId : '-';
        const renderInfo = event.componentWidth > 0
            ? `Component ${event.componentWidth} x ${event.componentHeight}, content ${event.contentWidth} x ${event.contentHeight}`
            : 'Waiting for first render callback';

        this.networkMeta =
            `URL: ${this.currentRemoteSource()}\nImage ${imageSize}, HTTP ${httpCode}, request ${requestId}\n${renderInfo}`;
    }

    private switchRemoteImage(): void {
        this.currentRemoteIndex = (this.currentRemoteIndex + 1) % this.remoteSources.length;
        this.networkProgress = 0;
        this.networkStatus = 'Image source switched. Waiting for the next load.';
        this.networkMeta = `Current URL: ${this.currentRemoteSource()}`;
    }

    private async preloadCurrentImage(): Promise<void> {
        this.networkStatus = 'Preloading current image into file cache';
        try {
            await this.prepareCache();
            this.lastCachePath = await ImageKnife.getInstance().preloadCache(this.currentRemoteSource());
            this.networkStatus = this.lastCachePath.length > 0
                ? 'Preload completed and file cache was written'
                : 'Preload completed but returned no cache path';
            this.cacheSummary = ImageCacheManager.summary();
        } catch (error) {
            this.networkStatus = `Preload failed: ${error}`;
        }
    }

    private async clearCache(): Promise<void> {
        try {
            await ImageCacheManager.clearAll();
            this.lastCachePath = 'Cache has been cleared.';
            this.cacheSummary = ImageCacheManager.summary();
        } catch (error) {
            this.lastCachePath = `Cache clear failed: ${error}`;
        }
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

    build() {
        Scroll() {
            Column({ space: 18 }) {
                this.sectionTitle(
                    'SmartImage Component',
                    'A reusable image component built on top of ImageKnifePro with placeholders, error fallback, progress callbacks and shared cache setup.'
                )

                Column({ space: 14 }) {
                    SmartImage({
                        src: this.currentRemoteSource(),
                        placeholder: $r('app.media.background'),
                        errorHolder: $r('app.media.foreground'),
                        imageFit: ImageFit.Contain,
                        cornerRadius: 32,
                        showProgressTag: true,
                        onStateChange: (event: SmartImageEvent) => this.handleHeroStateChange(event)
                    })
                        .width('100%')
                        .height(240)

                    Text('Remote SmartImage')
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

                this.sectionTitle(
                    'Reusable Variants',
                    'The same component can render bundled resources, avatar-style circle crops and standard rounded cards without repeating ImageKnifeOption wiring.'
                )

                Row({ space: 14 }) {
                    Column({ space: 12 }) {
                        SmartImage({
                            src: $r('app.media.startIcon'),
                            placeholder: $r('app.media.foreground'),
                            errorHolder: $r('app.media.foreground'),
                            imageFit: ImageFit.Cover,
                            cornerRadius: 24,
                            enableFileCache: false
                        })
                            .width('100%')
                            .height(170)

                        Text('Bundled Asset')
                            .fontSize(17)
                            .fontWeight(FontWeight.Medium)
                            .fontColor('#1F2937')

                        Text('Uses the same API as the network image, but loads a local resource and keeps the layout clean with rounded corners.')
                            .fontSize(12)
                            .lineHeight(18)
                            .fontColor('#5B6576')
                    }
                    .padding(16)
                    .backgroundColor('#FFFFFF')
                    .borderRadius(28)
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)

                    Column({ space: 12 }) {
                        SmartImage({
                            src: $r('app.media.foreground'),
                            placeholder: $r('app.media.background'),
                            errorHolder: $r('app.media.startIcon'),
                            imageFit: ImageFit.Cover,
                            circleCrop: true,
                            circleBorderWidth: 8,
                            enableFileCache: false
                        })
                            .width('100%')
                            .height(170)

                        Text('Circle Avatar')
                            .fontSize(17)
                            .fontWeight(FontWeight.Medium)
                            .fontColor('#1F2937')

                        Text('Circle crop and border are now just component props, so you do not need to build transformationOption by hand.')
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
                .width('100%')

                this.sectionTitle(
                    'Failure Fallback',
                    'The component also exposes placeholder and error fallback for failed network requests, so broken URLs do not leave empty blocks in the UI.'
                )

                Column({ space: 12 }) {
                    SmartImage({
                        src: 'https://example.invalid/not-found.png',
                        placeholder: $r('app.media.background'),
                        errorHolder: $r('app.media.foreground'),
                        imageFit: ImageFit.Cover,
                        errorFit: ImageFit.Contain,
                        cornerRadius: 24
                    })
                        .width('100%')
                        .height(180)

                    Text('Error State')
                        .fontSize(17)
                        .fontWeight(FontWeight.Medium)
                        .fontColor('#1F2937')

                    Text('When loading fails, SmartImage automatically falls back to the local error asset and still keeps the card layout stable.')
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
