// BodyInfoPage.ets 身体数据页面
import { BackButton } from '../../common/components/BackButton'

@Entry
@Component
struct BodyInfoPage {
  build() {
    Stack() {
      // 主内容容器
      Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
        Text('This is pages/HomeTo/BodyInfoPage')
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