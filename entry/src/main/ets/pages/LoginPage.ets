/**
 * @file LoginPage.ets
 * @description 登录界面
 */
import { PromptAction, Router } from '@kit.ArkUI';
import { Context } from '@kit.AbilityKit';
import { LoginVM } from '../features/login/controller/LoginVM';

@Entry
@Component
struct LoginPage {
  /* ---------------- 状态变量 ---------------- */
  @State username: string = '';
  @State password: string = '';

  /* ---------------- 实例变量 ---------------- */
  private loginVM: LoginVM = new LoginVM();
  private router: Router | null = null;
  private promptAction: PromptAction | null = null;

  /* ---------------- 生命周期 ---------------- */
  aboutToAppear() {
    const uiContext = this.getUIContext();
    this.router = uiContext.getRouter();
    this.promptAction = uiContext.getPromptAction();
  }

  /* ---------------- UI ---------------- */
  build() {
    Column() {
      Text('用户登录')
        .fontSize(28)
        .fontColor('#1A1A1A')
        .margin({ bottom: 40 })

      /* 用户名 */
      TextInput({ placeholder: '请输入用户名' })
        .placeholderColor('#999999')
        .fontColor('#333333')
        .height(50)
        .width('90%')
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .padding(10)
        .margin({ bottom: 20 })
        .onChange(v => this.username = v)

      /* 密码 */
      TextInput({ placeholder: '请输入密码' })
        .type(InputType.Password)
        .placeholderColor('#999999')
        .fontColor('#333333')
        .height(50)
        .width('90%')
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .padding(10)
        .margin({ bottom: 30 })
        .onChange(v => this.password = v)

      /* 登录按钮 */
      Button('登录')
        .width('90%')
        .height(50)
        .backgroundColor('#409EFF')
        .fontColor('#FFFFFF')
        .fontSize(20)
        .borderRadius(8)
        .onClick(() => this.handleLogin())

      /* 文字链区域 */
      Row() {
        Text('注册账号')
          .fontSize(14)
          .fontColor('#409EFF')
          .onClick(() => this.gotoRegister())
          .margin({ left: 4 })

        Text(' | ')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ left: 4, right: 4 })

        Text('忘记密码')
          .fontSize(14)
          .fontColor('#409EFF')
          .onClick(() => this.gotoResetPwd())
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 24 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F5F6FA')
  }

  /* ==================== 业务逻辑 ==================== */

  private validate(): boolean {
    return this.username.length > 0 && this.password.length > 0;
  }

  private async handleLogin(): Promise<void> {
    if (!this.validate()) {
      this.showToast('请输入用户名和密码');
      return;
    }

    try {
      const ctx = this.getUIContext().getHostContext() as Context;
      const ok = await this.loginVM.login(ctx, this.username, this.password);
      if (ok) {
        this.showToast('登录成功');
        this.safeNavigate('pages/HomePage', 'replace');
      } else {
        this.showToast('用户名或密码错误');
      }
    } catch (e) {
      console.error('Login error:', e);
      this.showToast('登录异常');
    }
  }

  private gotoRegister(): void {
    this.safeNavigate('pages/RegisterPage');
  }

  private gotoResetPwd(): void {
    this.safeNavigate('pages/ResetPasswordPage');
  }

  /* ---------------- 封装方法 ---------------- */

  /**
   * 安全跳转页面，自动处理异常并提示用户
   * @param url 目标页面路径
   * @param mode 跳转模式：'push'（入栈）或 'replace'（替换当前页）
   */
  private safeNavigate(url: string, mode: 'push' | 'replace' = 'push'): void {
    if (!this.router) {
      this.showToast('页面跳转失败');
      return;
    }

    try { // 将整个操作包裹在try块中
      if (mode === 'push') {
        this.router.pushUrl({ url }).catch((e: Error) => { // 添加Promise的catch处理
          console.error('[Nav] pushUrl failed:', url, e);
          this.showToast('页面跳转失败');
        });
      } else {
        this.router.replaceUrl({ url }).catch((e: Error) => {
          console.error('[Nav] replaceUrl failed:', url, e);
          this.showToast('页面跳转失败');
        });
      }
    } catch (e) { // 同步异常捕获
      console.error('[Nav] navigation error:', e);
      this.showToast('页面跳转失败');
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