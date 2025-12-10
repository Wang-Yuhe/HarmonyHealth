/**
 * @file HomePage.ets
 * @description 应用主界面
 * @created 2025-12-03 09:12:10
 */
import { myNavigator } from '../common/components/Navigator';
import { HealthVM } from '../features/healthStatus/viewmodel/HealthVM';
import { HealthData } from '../common/model/HealthData';

@Component
struct HealthItemComponent {
  @Prop title: string = '';
  @Prop value: string = '';
  @Prop bgColor: string = '';
  @Prop pageName: string = '';
  @Prop icon: ResourceStr = $r('app.media.startIcon'); // 新增 icon 参数，默认给个图标

  build() {
    Button() {
      Column() {
        // 直接使用传入的 icon
        Image(this.icon)
          .width(40)
          .height(40)
          .margin({ bottom: 8 })
          .objectFit(ImageFit.Contain)

        Text(this.title)
          .fontSize(18)
          .fontColor('#333')
        
        if (this.value) {
          Text(this.value)
            .fontSize(16)
            .fontColor('#333')
            .fontWeight(FontWeight.Bold)
            .margin({ top: 5 })
        }
      }
    }
    .padding(16)
    .borderRadius(16)
    .backgroundColor(this.bgColor)
    .width('100%')
    .onClick(() => {
      this.getUIContext().getRouter().pushUrl({ url: this.pageName })
    })
  }
}

@Entry
@Component
struct HomePage {
  @State currentData: HealthData = new HealthData(0, 0, 0, 0);
  private healthVM: HealthVM = new HealthVM();

  async aboutToAppear() {
    // 1. 先尝试加载上次保存的数据（数据库读取）
    const lastData = await this.healthVM.loadLastData();
    if (lastData) {
      this.currentData = lastData;
      console.info(`HealthApp data刷新: 心率=${lastData.heartRate}, 时间=${lastData.timestamp}`);
    }

    // 2. 监听新数据（模拟生成 + 写入数据库）
    this.healthVM.startMonitoring(3000000, (data) => {
      this.currentData = data;
    });
  }

  aboutToDisappear() {
    this.healthVM.stopMonitoring();
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Column() {
        Column({ space: 16 }) {  // space 指定子项之间的间距一致
          HealthItemComponent({
            title: '步数',
            value: `${this.currentData.steps} 步`,
            bgColor: '#FFB6C1',
            pageName: 'pages/HomeTo/StepsPage',
            icon: $r('app.media.homeIcon') // 暂时使用现有图标，请替换为对应图标
          })
          
          HealthItemComponent({
            title: '睡眠质量',
            value: '8h 30m',
            bgColor: '#87CEFA',
            pageName: 'pages/HomeTo/SleepPage',
            icon: $r('app.media.exploreIcon') // 暂时使用现有图标
          })
          
          HealthItemComponent({
            title: '实时健康状态',
            value: `心率: ${this.currentData.heartRate} | 血氧: ${this.currentData.bloodOxygen}%`,
            bgColor: '#98FB98',
            pageName: 'features/healthStatus/view/StatusPage',
            icon: $r('app.media.startIcon') // 暂时使用现有图标
          })

          HealthItemComponent({
            title: '疾病历史',
            value: '无记录',
            bgColor: '#DDA0DD',
            pageName: 'pages/HomeTo/DiseasePage',
            icon: $r('app.media.profileIcon') // 暂时使用现有图标
          })
        }
        .height('90%')
        .padding(16)
        .width('100%')

        myNavigator() // 底部导航
      }
      .width('100%')
      .height('100%')
    }
    .backgroundColor('#F5F5F5')
  }
}
