import { myNavigator } from '../common/components/Navigator';

@Entry
@Component
struct AskAIPage {
  @State inputText: string = ''

  build() {
    Stack() {
      // 底部导航栏
      myNavigator()

      Column() {
        Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
          TextInput({ text: this.inputText, placeholder: '输入消息' })
            .padding(12)
            .fontSize(16)
            .flexGrow(1)
            .backgroundColor(Color.White)
            .borderRadius(20)
            .onChange((value: string) => {
              this.inputText = value
            })

          Image($r('app.media.enter'))
            .width(80)
            .height(40)
            .margin({ right: 16 })
            .opacity(this.inputText ? 1 : 0.6)
            .onClick(() => {
              // 在此处添加消息发送逻辑
              // this.handleSendMessage()
            })
            .borderRadius(20)
        }
        .padding({
          left: 24,
          right: 24,
          top: 16,
          bottom: 16
        })
        .backgroundColor('#F5F5F5')
      }
    }


    }

  }