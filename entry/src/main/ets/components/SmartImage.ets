import common from '@ohos.app.ability.common';
import {
    CacheStrategy,
    ImageInfo,
    ImageKnifeOption,
    ImageKnifeView,
    TransformationOption,
    TransformationType
} from '@ohos/imageknifepro';
import { ImageCacheManager } from '../utils/ImageCacheManager';
import { Logger } from '../utils/Logger';

export interface SmartImageEvent {
    phase: string;
    progress: number;
    message: string;
    requestId: string;
    imageWidth: number;
    imageHeight: number;
    httpCode: number;
    componentWidth: number;
    componentHeight: number;
    contentWidth: number;
    contentHeight: number;
}

@Component
export struct SmartImage {
    @Watch('handleSourceChange') @Prop src: string | PixelMap | Resource = '';
    @Watch('syncOption') @Prop placeholder: string | PixelMap | Resource = $r('app.media.background');
    @Watch('syncOption') @Prop errorHolder: string | PixelMap | Resource = $r('app.media.foreground');
    @Watch('syncOption') @Prop imageFit: ImageFit = ImageFit.Cover;
    @Watch('syncOption') @Prop placeholderFit: ImageFit = ImageFit.Cover;
    @Watch('syncOption') @Prop errorFit: ImageFit = ImageFit.Cover;
    @Watch('syncOption') @Prop cornerRadius: number = 0;
    @Watch('syncOption') @Prop circleCrop: boolean = false;
    @Watch('syncOption') @Prop circleBorderWidth: number = 0;
    @Watch('syncOption') @Prop cacheStrategy: CacheStrategy = CacheStrategy.DEFAULT;
    @Watch('syncOption') @Prop enableFileCache: boolean = true;
    @Watch('syncOption') @Prop fallbackUrls: Array<string> = [];
    @Watch('syncOption') @Prop transformationType: TransformationType = TransformationType.UNKNOWN;
    @Watch('syncOption') @Prop transformationValues: Array<number> = [];
    @Prop showProgressTag: boolean = false;
    @Prop containerColor: string = '#EEF3F8';

    onStateChange: ((event: SmartImageEvent) => void) | undefined = undefined;

    @State private imageOption: ImageKnifeOption = new ImageKnifeOption();
    @State private phase: string = 'idle';
    @State private progress: number = 0;
    @State private message: string = 'Waiting for image request';
    @State private requestId: string = '';
    @State private imageWidth: number = 0;
    @State private imageHeight: number = 0;
    @State private httpCode: number = -1;
    @State private componentWidth: number = 0;
    @State private componentHeight: number = 0;
    @State private contentWidth: number = 0;
    @State private contentHeight: number = 0;

    aboutToAppear(): void {
        this.syncOption();
        this.prepareCache();
    }

    private handleSourceChange(): void {
        this.resetStatus();
        this.syncOption();
        this.prepareCache();
    }

    private resetStatus(): void {
        this.phase = 'idle';
        this.progress = 0;
        this.message = 'Waiting for image request';
        this.requestId = '';
        this.imageWidth = 0;
        this.imageHeight = 0;
        this.httpCode = -1;
        this.componentWidth = 0;
        this.componentHeight = 0;
        this.contentWidth = 0;
        this.contentHeight = 0;
        this.emitState();
    }

    private syncOption(): void {
        this.imageOption.loadSrc = this.src;
        this.imageOption.placeholderSrc = this.placeholder;
        this.imageOption.errorSrc = this.errorHolder;
        this.imageOption.objectFit = this.imageFit;
        this.imageOption.placeholderObjectFit = this.placeholderFit;
        this.imageOption.errorObjectFit = this.errorFit;
        this.imageOption.border = this.circleCrop ? undefined : { radius: this.cornerRadius };
        this.imageOption.writeCacheStrategy = this.cacheStrategy;
        this.imageOption.context = getContext(this) as common.UIAbilityContext;
        this.imageOption.fallbackUrls = this.buildFallbackUrls();
        this.imageOption.transformationOption = this.buildTransformationOption();
        this.imageOption.progressListener = (progress: number) => {
            this.phase = 'loading';
            this.progress = progress;
            this.message = `Downloading image ${progress}%`;
            this.emitState();
        };
        this.imageOption.onLoadListener = {
            onLoadStart: (imageInfo: ImageInfo) => {
                this.phase = 'loading';
                this.progress = 0;
                this.requestId = imageInfo.requestId;
                this.message = 'Starting image request';
                this.applyImageInfo(imageInfo);
                this.emitState();
            },
            onLoadSuccess: (imageInfo: ImageInfo) => {
                this.phase = 'success';
                this.progress = 100;
                this.requestId = imageInfo.requestId;
                this.message = 'Image loaded successfully';
                this.applyImageInfo(imageInfo);
                this.emitState();
            },
            onLoadFailed: (err: string, imageInfo: ImageInfo) => {
                this.phase = 'error';
                this.message = `Image load failed: ${err}`;
                this.requestId = imageInfo.requestId;
                this.applyImageInfo(imageInfo);
                this.emitState();
            },
            onLoadCancel: (reason: string, imageInfo: ImageInfo) => {
                this.phase = 'cancelled';
                this.message = `Image request cancelled: ${reason}`;
                this.requestId = imageInfo.requestId;
                this.applyImageInfo(imageInfo);
                this.emitState();
            }
        };
        this.imageOption.onComplete = (event) => {
            if (!event) {
                return;
            }
            this.componentWidth = event.componentWidth;
            this.componentHeight = event.componentHeight;
            this.contentWidth = event.contentWidth;
            this.contentHeight = event.contentHeight;
            this.emitState();
        };
    }

    private buildFallbackUrls(): Array<string> | undefined {
        if (!this.isStringSource(this.src) || this.fallbackUrls.length === 0) {
            return undefined;
        }
        return this.fallbackUrls.filter((item: string) => item.length > 0);
    }

    private buildTransformationOption(): TransformationOption | undefined {
        if (this.circleCrop) {
            const option = new TransformationOption();
            if (this.circleBorderWidth > 0) {
                option.type = TransformationType.CROP_CIRCLE_WITH_BORDER;
                option.f32 = [this.circleBorderWidth, 255, 255, 255];
                return option;
            }
            option.type = TransformationType.CROP_CIRCLE;
            return option;
        }

        if (this.transformationType === TransformationType.UNKNOWN) {
            return undefined;
        }

        const option = new TransformationOption();
        option.type = this.transformationType;
        if (this.transformationValues.length > 0) {
            option.f32 = this.transformationValues;
        }
        return option;
    }

    private async prepareCache(): Promise<void> {
        if (!this.enableFileCache || !this.usesNetworkSource()) {
            return;
        }

        try {
            await ImageCacheManager.ensureReady(getContext(this) as common.UIAbilityContext);
        } catch (error) {
            Logger.warn('SmartImage', 'Cache prepare failed', `${error}`);
        }
    }

    private usesNetworkSource(): boolean {
        return this.isStringSource(this.src) &&
            ((this.src as string).startsWith('http://') || (this.src as string).startsWith('https://'));
    }

    private isStringSource(src: string | PixelMap | Resource): boolean {
        return typeof src === 'string';
    }

    private applyImageInfo(imageInfo: ImageInfo): void {
        this.imageWidth = imageInfo.imageWidth;
        this.imageHeight = imageInfo.imageHeight;
        this.httpCode = imageInfo.httpCode ?? -1;
    }

    private emitState(): void {
        if (this.onStateChange === undefined) {
            return;
        }

        this.onStateChange({
            phase: this.phase,
            progress: this.progress,
            message: this.message,
            requestId: this.requestId,
            imageWidth: this.imageWidth,
            imageHeight: this.imageHeight,
            httpCode: this.httpCode,
            componentWidth: this.componentWidth,
            componentHeight: this.componentHeight,
            contentWidth: this.contentWidth,
            contentHeight: this.contentHeight
        });
    }

    build() {
        Stack({ alignContent: Alignment.TopEnd }) {
            ImageKnifeView({ imageKnifeOption: this.imageOption })
                .width('100%')
                .height('100%')

            if (this.showProgressTag && this.phase === 'loading') {
                Text(`${this.progress}%`)
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#FFFFFF')
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .backgroundColor('#AA152033')
                    .borderRadius(18)
                    .margin(12)
            }
        }
        .width('100%')
        .height('100%')
        .clip(true)
        .borderRadius(this.circleCrop ? 999 : this.cornerRadius)
        .backgroundColor(this.containerColor)
    }
}
