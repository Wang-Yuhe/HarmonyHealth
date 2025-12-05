/**
 * @file HomePage.ets
 * @description 应用主界面
 * @created 2025-12-03 09:12:10
 */
import { myNavigator } from '../common/components/Navigator';

@Entry
@Component
struct HomePage {
  build() {
    Stack({ alignContent: Alignment.Top }) {
      Column() {
        Column({ space: 16 }) {  // space 指定子项之间的间距一致
          this.HealthItem('步数', '#FFB6C1', 'HomeTo/StepsPage')
          this.HealthItem('睡眠质量', '#87CEFA', 'HomeTo/SleepPage')
          this.HealthItem('身体数据', '#98FB98', 'HomeTo/BodyInfoPage')
          this.HealthItem('疾病历史', '#DDA0DD', 'HomeTo/DiseasePage')
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

  @Builder
  HealthItem(title: string, bgColor: string, pageName: string) {
    Button() {
      Column() {
        Image($r(`app.media.ic_${pageName}`))
          .width(40)
          .height(40)
          .margin({ bottom: 8 })

        Text(title)
          .fontSize(18)
          .fontColor('#333')
      }
    }
    .padding(16)
    .borderRadius(16)
    .backgroundColor(bgColor)
    .width('100%')
    .onClick(() => {
      this.getUIContext().getRouter().pushUrl({ url: `pages/${pageName}`, })
    })
  }
}
