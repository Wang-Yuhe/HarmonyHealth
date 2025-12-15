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
  @Prop icon: ResourceStr = $r('app.media.startIcon'); // 需替换为实际图标
  @Prop themeColor: string = '#5C7CFF';

  build() {
    Column() {
      // 图标与标题
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          Circle({ width: 32, height: 32 })
            .fill(this.themeColor)
            .opacity(0.15)
          
          Image(this.icon)
            .width(18)
            .height(18)
            .fillColor(this.themeColor)
            .objectFit(ImageFit.Contain)
        }
        .margin({ right: 8 })

        Text(this.title)
          .fontSize(14)
          .fontColor('#666')
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .margin({ bottom: 12 })
      
      // 数值展示
      Row() {
        Text(this.value)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
        Text(this.unit)
          .fontSize(12)
          .fontColor('#999')
          .margin({ left: 4, bottom: 4 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .height(110)
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .shadow({ radius: 15, color: 'rgba(0,0,0,0.05)', offsetY: 5 })
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
  }
}

@Entry
@Component
struct StatusPage {
  @State currentData: HealthData = new HealthData(0, 0, 0, 0);
  @State updateInterval: number = 3; // 默认 3秒
  @State isMonitoring: boolean = false;
  
  private healthVM: HealthVM = new HealthVM();
  @Provide router: Router | null = null;

  aboutToAppear() {
    this.router = this.getUIContext().getRouter();
    // 页面加载时自动开始监测
    this.toggleMonitoring(true);
  }

  aboutToDisappear() {
    // 页面销毁时停止监测，防止内存泄漏
    this.healthVM.stopMonitoring();
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 1. 背景层
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [['#E0E8FF', 0.0], ['#F5F7FA', 0.6], ['#FFFFFF', 1.0]]
        })

      Column() {
        // 标题栏
        Column() {
          Text('实时健康状态')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
          
          Row() {
            Circle({ width: 6, height: 6 })
              .fill(this.isMonitoring ? '#00C853' : '#CCC')
              .margin({ right: 6 })
            Text(this.isMonitoring ? '监测中...' : '监测已暂停')
              .fontSize(12)
              .fontColor(this.isMonitoring ? '#00C853' : '#999')
            
            Blank().width(10)
            
            Text(`更新: ${new Date(this.currentData.timestamp).toLocaleTimeString()}`)
              .fontSize(12)
              .fontColor('#999')
          }
          .margin({ top: 8 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ top: 20, bottom: 20 })

        // 数据展示区域 (Grid布局)
        Grid() {
          GridItem() {
            DataCard({
              title: '实时心率',
              value: `${this.currentData.heartRate}`,
              unit: 'bpm',
              themeColor: '#FF6B81', // 红色系
              icon: $r('app.media.heart') // 建议替换为心形图标
            })
          }
          GridItem() {
            DataCard({
              title: '血氧饱和度',
              value: `${this.currentData.bloodOxygen}`,
              unit: '%',
              themeColor: '#448AFF', // 蓝色系
              icon: $r('app.media.water') // 建议替换为水滴图标
            })
          }
          GridItem() {
            DataCard({
              title: '今日步数',
              value: `${this.currentData.steps}`,
              unit: '步',
              themeColor: '#00C853', // 绿色系
              icon: $r('app.media.steps')
            })
          }
          GridItem() {
            DataCard({
              title: '能量消耗',
              value: `${this.currentData.calories}`,
              unit: 'kcal',
              themeColor: '#FFB300', // 橙色系
              icon: $r('app.media.flame') // 建议替换为火焰图标
            })
          }
        }
        .columnsTemplate('1fr 1fr')
        .rowsGap(12)
        .columnsGap(12)
        .padding({ left: 16, right: 16 })
        .height(260)

        // 控制区域
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
              .onChange((isOn) => {
                this.toggleMonitoring(isOn);
              })
          }
          .width('100%')
          .margin({ bottom: 20 })

          // 滑动条控制 CD
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
            .margin({ bottom: 10 })

            Slider({
              value: this.updateInterval,
              min: 1,
              max: 10,
              step: 1,
              style: SliderStyle.OutSet
            })
              .trackColor('#E0E0E0')
              .selectedColor('#5C7CFF')
              .showSteps(true)
              .onChange((value: number) => {
                this.updateInterval = value;
                // 如果正在监测，需要重启定时器以应用新时间
                if (this.isMonitoring) {
                  this.toggleMonitoring(true);
                }
              })
          }
        }
        .padding(20)
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
        .margin({ top: 20, left: 16, right: 16 })
        .shadow({ radius: 20, color: 'rgba(0,0,0,0.05)', offsetY: 5 })

      }
      .width('100%')
      .height('100%')

      // 返回按钮
      BackButton()
        .margin({ top: 10, left: 10 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }

  // 切换监测状态
  toggleMonitoring(enable: boolean) {
    this.isMonitoring = enable;
    if (enable) {
      this.healthVM.startMonitoring(this.updateInterval * 1000, (data) => {
        this.currentData = data;
        // console.info(`HealthApp UI刷新: 心率=${data.heartRate}, 时间=${data.timestamp}`);
      });
    } else {
      this.healthVM.stopMonitoring();
    }
  }
}