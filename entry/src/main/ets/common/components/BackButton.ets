// BackButton.ets
import { Router } from '@kit.ArkUI';

@Component
export struct BackButton {
  @Consume router: Router; // 👈 消费父级提供的 router

  build() {
    Button() {
      Image($r('app.media.backButton'))
        .width(24)
        .height(24)
    }
    .type(ButtonType.Circle)
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      this.router.back(); // ✅ 安全调用
    })
    .width(48)
    .height(48)
    .margin({ top: 16, left: 16 })
  }
}