// BackButton.ets 通用返回按钮
@Component
export struct BackButton {
  build() {
    Stack() {
      Button() {
        Image($r('app.media.backButton'))
          .width(24)
          .height(24)
      }
      .type(ButtonType.Circle)
      .backgroundColor('#FFFFFF')
      .onClick(() => {
        // 通过UIContext获取路由上下文
        const uiContext = this.getUIContext();
        uiContext.getRouter().back();
      })
    }
    .alignContent(Alignment.Start)
    .padding({ top: 16, left: 16 })
    .position({ x: 0, y: 0 })
  }
}