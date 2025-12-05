/**
 * @file ProfilePage.ets
 * @description 我的页面
 */
import { myNavigator } from '../common/components/Navigator';

@Entry
@Component
struct ProfilePage {
  build() {
    Stack() {
      // 主内容区域
      Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
        Text('This is ProfilePage')
          .fontSize(30)
          .fontColor('#000000')
      }
      .width('100%')
      .height('100%')

      // 底部导航栏
      myNavigator()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}