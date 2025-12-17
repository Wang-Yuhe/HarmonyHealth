/**
 * @file StatusPage.ets
 * @description 健康状态展示页面
 * @created 2025-12-03 09:12:10
 */

// 将弃用
// 2025-12-10 15:11

import { HealthVM } from '../viewmodel/HealthVM';
import { HealthData } from '../../../common/model/HealthData';
import { BackButton } from '../../../common/components/BackButton';
import { Router } from '@kit.ArkUI';

@Component
struct DataCard {
  @Prop title: string = '';
  @Prop value: string = '';
  @Prop unit: string = '';
  @Prop icon: ResourceStr = $r('app.media.startIcon');
  @Prop themeColor: string = '#5C7CFF';

  build() {
    Column() {
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          Circle({ width: 36, height: 36 })
            .fill(this.themeColor)
            .opacity(0.1)
          
          Image(this.icon)
            .width(20)
            .height(20)
            .fillColor(this.themeColor)
            .objectFit(ImageFit.Contain)
        }
        .margin({ right: 10 })

        Text(this.title)
          .fontSize(14)
          .fontColor('#666')
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .margin({ bottom: 16 })
      
      Row() {
        Text(this.value)
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
        Text(this.unit)
          .fontSize(12)
          .fontColor('#999')
          .margin({ left: 6, bottom: 6 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .height(120)
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .shadow({ radius: 20, color: 'rgba(0,0,0,0.04)', offsetY: 6 })
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
  }
}

@Entry
@Component
struct StatusPage {
  @State currentData: HealthData = new HealthData(0, 0, 0, 0);
  @State updateInterval: number = 3;
  @State isMonitoring: boolean = false;
  
  private healthVM: HealthVM = new HealthVM();
  @Provide router: Router | null = null;

  aboutToAppear() {
    this.router = this.getUIContext().getRouter();
    this.toggleMonitoring(true);
  }

  aboutToDisappear() {
    this.healthVM.stopMonitoring();
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [['#F0F4FF', 0.0], ['#F8F9FB', 0.6], ['#FFFFFF', 1.0]]
        })

      Column() {
        Column() {
          Text('实时健康状态')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
          
          Row() {
            Circle({ width: 8, height: 8 })
              .fill(this.isMonitoring ? '#00C853' : '#CCC')
              .margin({ right: 8 })
            Text(this.isMonitoring ? '监测中...' : '监测已暂停')
              .fontSize(14)
              .fontColor(this.isMonitoring ? '#00C853' : '#999')
            
            Blank().width(12)
            
            Text(`更新: ${new Date(this.currentData.timestamp).toLocaleTimeString()}`)
              .fontSize(12)
              .fontColor('#AAA')
          }
          .margin({ top: 8 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ top: 24, bottom: 24 })

        Grid() {
          GridItem() {
            DataCard({
              title: '实时心率',
              value: `${this.currentData.heartRate}`,
              unit: 'bpm',
              themeColor: '#FF5252',
              icon: $r('app.media.heart')
            })
          }
          GridItem() {
            DataCard({
              title: '血氧饱和度',
              value: `${this.currentData.bloodOxygen}`,
              unit: '%',
              themeColor: '#448AFF',
              icon: $r('app.media.water')
            })
          }
          GridItem() {
            DataCard({
              title: '今日步数',
              value: `${this.currentData.steps}`,
              unit: '步',
              themeColor: '#00C853',
              icon: $r('app.media.steps')
            })
          }
          GridItem() {
            DataCard({
              title: '能量消耗',
              value: `${this.currentData.calories}`,
              unit: 'kcal',
              themeColor: '#FFA000',
              icon: $r('app.media.flame')
            })
          }
        }
        .columnsTemplate('1fr 1fr')
        .rowsGap(14)
        .columnsGap(14)
        .padding({ left: 20, right: 20 })
        .height(270)

        Column() {
          Row() {
            Column() {
              Text('监测设置')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333')
              Text('调整数据刷新频率')
                .fontSize(12)
                .fontColor('#999')
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)

            Blank()

            Toggle({ type: ToggleType.Switch, isOn: this.isMonitoring })
              .selectedColor('#5C7CFF')
              .onChange((isOn) => { this.toggleMonitoring(isOn); })
          }
          .width('100%')
          .margin({ bottom: 24 })

          Column() {
            Row() {
              Text('更新间隔')
                .fontSize(14)
                .fontColor('#666')
              Blank()
              Text(`${this.updateInterval} 秒`)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#5C7CFF')
            }
            .width('100%')
            .margin({ bottom: 12 })

            Slider({
              value: this.updateInterval,
              min: 1,
              max: 10,
              step: 1,
              style: SliderStyle.OutSet
            })
              .trackColor('#F0F0F0')
              .selectedColor('#5C7CFF')
              .showSteps(true)
              .onChange((value: number) => {
                this.updateInterval = value;
                if (this.isMonitoring) this.toggleMonitoring(true);
              })
          }
        }
        .padding(24)
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
        .margin({ top: 24, left: 20, right: 20 })
        .shadow({ radius: 25, color: 'rgba(0,0,0,0.05)', offsetY: 8 })

      }
      .width('100%')
      .height('100%')

      BackButton().margin({ top: 10, left: 10 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FB')
  }

  toggleMonitoring(enable: boolean) {
    this.isMonitoring = enable;
    if (enable) {
      const context = this.getUIContext().getHostContext() as Context;
      this.healthVM.startMonitoring(context, this.updateInterval * 1000, (data: HealthData) => {
        this.currentData = data;
      });
    } else {
      this.healthVM.stopMonitoring();
    }
  }
}