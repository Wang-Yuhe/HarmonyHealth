/**
 * @file LoginPage.ets
 * @description 登录界面
 */
@Entry
@Component
struct LoginPage {
  @State username: string = ''
  @State password: string = ''
  @State isPasswordVisible: boolean = false

  build() {
    Column() {
      // 标题部分
      Text('用户登录')
        .fontSize(28)
        .fontColor('#1A1A1A')
        .margin({ bottom: 40 })

      // 用户名输入框
      TextInput({ placeholder: '请输入用户名' })
        .placeholderColor('#999999')
        .fontColor('#333333')
        .height(50)
        .width('90%')
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .padding(10)
        .margin({ bottom: 20 })
        .onChange((value: string) => this.username = value)

      // 密码输入框
      TextInput({ placeholder: '请输入密码' })
        .type(this.isPasswordVisible ? InputType.Normal : InputType.Password)
        .placeholderColor('#999999')
        .fontColor('#333333')
        .height(50)
        .width('90%')
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .padding(10)
        .margin({ bottom: 30 })
        .onChange((value: string) => this.password = value)

      // 登录按钮
      Button('登 录')
        .width('90%')
        .height(50)
        .backgroundColor('#409EFF')
        .fontColor('#FFFFFF')
        .fontSize(20)
        .borderRadius(8)
        .margin({ bottom: 20 })
        .stateStyles({
          pressed: {
            .backgroundColor('#337ECC')
          }
        })
        .onClick(() => {
          if (this.validate()) {
            this.getUIContext().animateTo({ duration: 300 }, () => {
              AppStorage.setOrCreate('isLoggedIn', true)
              this.getUIContext().getRouter().replaceUrl({ url: 'pages/HomePage' })
            })
          }
        })

    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F5F6FA')
  }

  private validate(): boolean {
    // 验证逻辑实现
    return true;
  }
}