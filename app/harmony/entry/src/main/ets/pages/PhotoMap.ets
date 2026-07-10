import { router } from '@ohos.router';
import { promptAction } from '@kit.ArkUI';

import { photoMapService, PhotoMapPin, POIRecommendation } from '../features/map/PhotoMapService';
import { resolvePhotoMapRecommendations } from '../features/map/PhotoMapViewActions';

@Entry
@Component
struct PhotoMap {
  @State private pins: PhotoMapPin[] = [];
  @State private recommendations: POIRecommendation[] = [];

  aboutToAppear(): void {
    const initialized = photoMapService.initialize(getContext(this));
    if (!initialized) {
      promptAction.showToast({ message: $r('app.string.photo_map_load_failed') });
    }
    this.pins = photoMapService.getPins();
    this.refreshRecommendations();
  }

  private refreshRecommendations(): void {
    const result = resolvePhotoMapRecommendations(
      this.pins,
      (lat: number, lon: number) => photoMapService.getRecommendedPOIs(lat, lon)
    );
    this.recommendations = result.recommendations;
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text($r('app.string.photo_map_title'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        Text($r('app.string.photo_map_description'))
          .fontSize(14)
          .opacity(0.7)

        // Stats
        Row({ space: 16 }) {
          Column({ space: 4 }) {
            Text(String(this.pins.length))
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
            Text($r('app.string.photo_pins_count'))
              .fontSize(12)
              .opacity(0.6)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          Column({ space: 4 }) {
            Text(String(this.recommendations.length))
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
            Text($r('app.string.poi_count'))
              .fontSize(12)
              .opacity(0.6)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding(16)
        .borderRadius(12)
        .backgroundColor('#0D000000')

        // Recent pins list
        if (this.pins.length > 0) {
          Text($r('app.string.recent_photos'))
            .fontSize(18)
            .fontWeight(FontWeight.Medium)

          ForEach(this.pins.slice(-20).reverse(), (pin: PhotoMapPin) => {
            Row({ space: 12 }) {
              Text(pin.mediaType === 'video' ? '🎬' : '📍')
                .fontSize(16)
              Column({ space: 2 }) {
                if (pin.mediaType === 'video') {
                  Text($r('app.string.media_type_video'))
                    .fontSize(11)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius(10)
                    .backgroundColor('#12007DFF')
                    .fontColor($r('app.color.easy_shot_primary'))
                }
                Text(`${pin.latitude.toFixed(4)}, ${pin.longitude.toFixed(4)}`)
                  .fontSize(14)
                Text(new Date(pin.timestamp).toLocaleDateString())
                  .fontSize(12)
                  .opacity(0.6)
              }
              .layoutWeight(1)
            }
            .width('100%')
            .padding(8)
          }, (pin: PhotoMapPin) => pin.id)
        } else {
          Column({ space: 8 }) {
            Text('🗺️')
              .fontSize(48)
            Text($r('app.string.no_photo_pins'))
              .fontSize(14)
              .opacity(0.6)
          }
          .width('100%')
          .padding(32)
          .alignItems(HorizontalAlign.Center)
        }

        // POI recommendations
        if (this.recommendations.length > 0) {
          Text($r('app.string.poi_recommendations'))
            .fontSize(18)
            .fontWeight(FontWeight.Medium)

          ForEach(this.recommendations, (poi: POIRecommendation) => {
            Row({ space: 12 }) {
              Text('⭐')
                .fontSize(16)
              Column({ space: 2 }) {
                Text(poi.name)
                  .fontSize(14)
                Text(`${poi.distanceMeters}m`)
                  .fontSize(12)
                  .opacity(0.6)
              }
              .layoutWeight(1)
            }
            .width('100%')
            .padding(8)
          }, (poi: POIRecommendation) => `${poi.latitude}_${poi.longitude}`)
        }

        Button($r('app.string.back'))
          .onClick(() => { router.back(); })
          .width('100%')
      }
      .padding(24)
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
  }

  pageTransition() {
    PageTransitionEnter({ type: RouteType.Push, duration: 300 })
      .slide(SlideEffect.Right)
    PageTransitionExit({ type: RouteType.Pop, duration: 300 })
      .slide(SlideEffect.Right)
  }
}
