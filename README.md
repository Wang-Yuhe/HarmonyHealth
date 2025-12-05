## 在dev分支工作

## 可复用组件说明

`/entry/src/main/ets/common/components`中实现了一些可以复用的组件：

- BackButton.ets：返回按键，位于页面左上角，点击返回上一个页面，使用方式参考

  ```TS
  // BodyInfoPage.ets 身体数据页面
  import { BackButton } from '../../common/components/BackButton'
  
  @Entry
  @Component
  struct BodyInfoPage {
    build() {
      Stack() {
        // 主内容容器
        Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
          Text('Hello')
            .fontSize(30)
            .fontColor('#000000')
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .height('100%')
  
        BackButton()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')
    }
  }
  ```

  

- Navigator.ets：导航，位于页面底部，三个按钮点击跳转到对应页面，使用方式参考：

  ```TS
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
  
  ```

  

- 

## 页面文件说明

`entry/src/main/ets/pages`中实现页面，如果要添加新的页面记得在`entry/src/main/resources/base/profile/main_pages.json`中添加相关信息。