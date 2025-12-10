/**
 * @file RegisterPage.ets
 * @description 注册/注销页面
 */

import { Context } from '@kit.AbilityKit';
import { Router, promptAction, PromptAction, window } from '@kit.ArkUI';
import { LoginVM } from '../features/login/controller/LoginVM';
import { BackButton } from '../common/components/BackButton';

@Entry
@Component
struct RegisterPage {
  @State username: string = '';
  @State password: string = '';
  @State email: string = '';
  @State securityQuestion: string = '';
  @State securityAnswer: string = '';
  @State isRegisterMode: boolean = true;
  @State confirmPassword: string = '';

  private loginVM: LoginVM = new LoginVM();
  private promptAction: PromptAction | null = null;
  @Provide router: Router | null = null;

  // 安全初始化 UI 上下文
  aboutToAppear() {
    const uiContext = this.getUIContext();
    this.router = uiContext.getRouter();
    this.promptAction = uiContext.getPromptAction();
  }

  build() {
    Stack() {
      // 主内容区域
      Column() {
        // 顶部标题（注意：不再手动加 margin 给 BackButton 留位置）
        Row() {
          Text(this.isRegisterMode ? '注册账号' : '注销账号')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
        }
        .width('100%')
        .padding(24)
        .justifyContent(FlexAlign.Center)

        // 表单区域
        Column() {
          TextInput({ placeholder: '请输入用户名' })
            .width('100%')
            .height(48)
            .margin({ bottom: 16 })
            .onChange((v) => this.username = v)

          TextInput({ placeholder: '请输入密码' })
            .type(InputType.Password)
            .width('100%')
            .height(48)
            .margin({ bottom: 16 })
            .onChange((v) => this.password = v)

          if (this.isRegisterMode) {
            TextInput({ placeholder: '请确认密码' })
              .type(InputType.Password)
              .width('100%')
              .height(48)
              .margin({ bottom: 16 })
              .onChange((v) => this.confirmPassword = v)

            TextInput({ placeholder: '请输入邮箱' })
              .width('100%')
              .height(48)
              .margin({ bottom: 16 })
              .onChange((v) => this.email = v)

            TextInput({ placeholder: '请输入找回问题' })
              .width('100%')
              .height(48)
              .margin({ bottom: 16 })
              .onChange((v) => this.securityQuestion = v)

            TextInput({ placeholder: '请输入找回问题答案' })
              .width('100%')
              .height(48)
              .margin({ bottom: 24 })
              .onChange((v) => this.securityAnswer = v)
          }

          Button(this.isRegisterMode ? '注册' : '注销')
            .width('100%')
            .height(48)
            .backgroundColor('#409EFF')
            .fontColor(Color.White)
            .fontSize(18)
            .borderRadius(24)
            .onClick(() => this.handleSubmit())

          Button(this.isRegisterMode ? '切换到注销' : '切换到注册')
            .width('100%')
            .height(48)
            .margin({ top: 16 })
            .backgroundColor(Color.Transparent)
            .fontColor('#409EFF')
            .fontSize(16)
            .border({ width: 1, color: '#409EFF' })
            .borderRadius(24)
            .onClick(() => this.toggleMode())
        }
        .padding(24)
        .width('100%')
        .backgroundColor('#F8FAFF')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F8FAFF')

      // 返回按钮：固定在左上角
      if (this.router) {
        BackButton()
          .position({ x: 2, y: 2 })
      }
    }
    .width('100%')
    .height('100%')
  }

  private toggleMode() {
    this.isRegisterMode = !this.isRegisterMode;
  }

  private async handleSubmit() {
    if (!this.username || !this.password) {
      this.showToast('请输入用户名和密码');
      return;
    }

    if (this.isRegisterMode) {
      if (this.password !== this.confirmPassword) {
        this.showToast('两次密码输入不一致');
        return;
      }
      if (!this.email || !this.securityQuestion || !this.securityAnswer) {
        this.showToast('请完善所有信息');
        return;
      }

      try {
        const context = this.getUIContext().getHostContext() as Context;
        const success = await this.loginVM.register(
          context,
          this.username,
          this.password,
          this.email,
          this.securityQuestion,
          this.securityAnswer
        );
        if (success) {
          this.showToast('注册成功');
          this.router?.back();
        } else {
          this.showToast('用户已存在');
        }
      } catch (e) {
        this.showToast('注册异常');
      }
    } else {
      try {
        const context = this.getUIContext().getHostContext() as Context;
        const success = await this.loginVM.deleteUser(context, this.username, this.password);
        if (success) {
          this.showToast('注销成功');
          this.router?.back();
        } else {
          this.showToast('用户名或密码错误');
        }
      } catch (e) {
        this.showToast('注销异常');
      }
    }
  }

  private showToast(msg: string): void {
    try {
      this.promptAction?.showToast({ message: msg, duration: 2000 });
    } catch (error) {
      console.warn('Failed to show toast:', error);
    }
  }
}