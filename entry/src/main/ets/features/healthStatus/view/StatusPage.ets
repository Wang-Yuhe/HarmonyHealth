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
  @Prop color: string = '';

  build() {
    Column() {
      Text(this.title)
        .fontSize(16)
        .fontColor('#666')
        .margin({ bottom: 10 })
      
      Row() {
        Text(this.value)
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
        Text(this.unit)
          .fontSize(14)
          .fontColor('#999')
          .margin({ left: 5, bottom: 5 })
      }
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .height(120)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .justifyContent(FlexAlign.Center)
    .border({ width: 2, color: this.color })
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
    Stack() {
      Column() {
        // 标题栏
        Column() {
          Text('实时健康状态')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
          
          // 新增：显示最后更新时间，用于确认 UI 是否刷新
          Text(`更新时间: ${new Date(this.currentData.timestamp).toLocaleTimeString()}`)
            .fontSize(14)
            .fontColor('#999')
            .margin({ top: 5 })
        }
        .margin({ top: 20, bottom: 20 })

        // 数据展示区域 (Grid布局)
        Grid() {
          GridItem() {
            DataCard({
              title: '心率',
              value: `${this.currentData.heartRate}`,
              unit: 'bpm',
              color: '#FFB6C1'
            })
          }
          GridItem() {
            DataCard({
              title: '血氧',
              value: `${this.currentData.bloodOxygen}`,
              unit: '%',
              color: '#87CEFA'
            })
          }
          GridItem() {
            DataCard({
              title: '步数',
              value: `${this.currentData.steps}`,
              unit: '步',
              color: '#98FB98'
            })
          }
          GridItem() {
            DataCard({
              title: '消耗',
              value: `${this.currentData.calories}`,
              unit: 'kcal',
              color: '#DDA0DD'
            })
          }
        }
        .columnsTemplate('1fr 1fr')
        .rowsGap(15)
        .columnsGap(15)
        .padding(15)
        .height(300)

        // 控制区域
        Column() {
          Text('数据更新设置')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 10 })

          Row() {
            Text(`更新频率 (CD): ${this.updateInterval} 秒`)
              .fontSize(16)
            
            Toggle({ type: ToggleType.Switch, isOn: this.isMonitoring })
              .onChange((isOn) => {
                this.toggleMonitoring(isOn);
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ bottom: 10 })

          // 滑动条控制 CD
          Slider({
            value: this.updateInterval,
            min: 1,
            max: 10,
            step: 1,
            style: SliderStyle.OutSet
          })
            .showSteps(true)
            .onChange((value: number) => {
              this.updateInterval = value;
              // 如果正在监测，需要重启定时器以应用新时间
              if (this.isMonitoring) {
                this.toggleMonitoring(true);
              }
            })
          
          Text('滑动调整更新间隔 (1-10秒)')
            .fontSize(12)
            .fontColor('#999')
            .margin({ top: 5 })

        }
        .padding(20)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .margin(15)
        .shadow({ radius: 10, color: '#10000000' })

      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      // 返回按钮
      if (this.router) {
        BackButton()
          .position({ x: 2, y: 2 })
      }
    }
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