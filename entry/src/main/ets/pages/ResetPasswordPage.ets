/**
 * @file ResetPasswordPage.ets
 * @description 找回密码页面
 */

import { Context } from '@kit.AbilityKit';
import { Router, PromptAction } from '@kit.ArkUI';
import { LoginVM } from '../features/login/controller/LoginVM';
import { BackButton } from '../common/components/BackButton';

@Entry
@Component
struct ResetPasswordPage {
  @State username: string = '';
  @State securityAnswer: string = '';
  @State newPassword: string = '';
  @State confirmPassword: string = '';
  @State securityQuestion: string = '';
  @State showQuestion: boolean = false;

  private loginVM: LoginVM = new LoginVM();
  private promptAction: PromptAction | null = null;
  @Provide router: Router | null = null; // 👈 延迟初始化

  // ✅ 安全初始化 UI 上下文（避免 this.getUIContext() 过早调用）
  aboutToAppear() {
    const uiContext = this.getUIContext();
    this.router = uiContext.getRouter();
    this.promptAction = uiContext.getPromptAction();
  }

  build() {
    Stack() {
      // 主内容区域
      Column() {
        // 顶部标题
        Row() {
          Text('找回密码')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
        }
        .width('100%')
        .padding(24)
        .justifyContent(FlexAlign.Center)

        // 输入表单
        Column() {
          TextInput({ placeholder: '请输入用户名' })
            .width('100%')
            .height(48)
            .margin({ bottom: 16 })
            .onChange((v) => this.username = v)

          Button('获取找回问题')
            .width('100%')
            .height(48)
            .margin({ bottom: 16 })
            .backgroundColor('#409EFF')
            .fontColor(Color.White)
            .borderRadius(24)
            .onClick(() => this.getSecurityQuestion())

          if (this.showQuestion) {
            Text(this.securityQuestion)
              .width('100%')
              .margin({ bottom: 16 })
              .fontSize(16)
              .fontColor('#333333')

            TextInput({ placeholder: '请输入找回问题答案' })
              .width('100%')
              .height(48)
              .margin({ bottom: 16 })
              .onChange((v) => this.securityAnswer = v)

            TextInput({ placeholder: '请输入新密码' })
              .type(InputType.Password)
              .width('100%')
              .height(48)
              .margin({ bottom: 16 })
              .onChange((v) => this.newPassword = v)

            TextInput({ placeholder: '请确认新密码' })
              .type(InputType.Password)
              .width('100%')
              .height(48)
              .margin({ bottom: 24 })
              .onChange((v) => this.confirmPassword = v)

            Button('重置密码')
              .width('100%')
              .height(48)
              .backgroundColor('#409EFF')
              .fontColor(Color.White)
              .fontSize(18)
              .borderRadius(24)
              .onClick(() => this.resetPassword())
          }
        }
        .padding(24)
        .width('100%')
        .backgroundColor('#F8FAFF')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F8FAFF')


      if (this.router) {
        BackButton()
          .position({ x: 2, y: 2 })
      }
    }
    .width('100%')
    .height('100%')
  }

  private async getSecurityQuestion() {
    if (!this.username) {
      this.showToast('请输入用户名');
      return;
    }

    try {
      const context = this.getUIContext().getHostContext() as Context;
      const user = await this.loginVM.getUserByUsername(context, this.username);
      if (user && user.securityQuestion) {
        this.securityQuestion = user.securityQuestion;
        this.showQuestion = true;
      } else {
        this.showToast('用户不存在或未设置找回问题');
      }
    } catch (e) {
      this.showToast('获取问题失败');
    }
  }

  private async resetPassword() {
    if (!this.securityAnswer || !this.newPassword || !this.confirmPassword) {
      this.showToast('请完善所有信息');
      return;
    }

    if (this.newPassword !== this.confirmPassword) {
      this.showToast('两次密码输入不一致');
      return;
    }

    try {
      const context = this.getUIContext().getHostContext() as Context;
      const success = await this.loginVM.resetPassword(
        context,
        this.username,
        this.securityAnswer,
        this.newPassword
      );
      if (success) {
        this.showToast('密码重置成功');
        this.router?.back(); // ✅ 安全调用
      } else {
        this.showToast('找回问题答案错误');
      }
    } catch (e) {
      this.showToast('重置密码失败');
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