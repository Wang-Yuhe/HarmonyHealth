/**
 * @file LoginPage.ets
 * @description 登录界面（支持输入账号自动切换头像）
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
  @State currentAvatar: Resource | string = $r('app.media.profileIcon'); // 支持 Resource 或 URI

  /* ---------------- 实例变量 ---------------- */
  private loginVM: LoginVM = new LoginVM();
  private router: Router | null = null;
  private promptAction: PromptAction | null = null;
  private debounceTimer: number = -1;

  /* ---------------- 生命周期 ---------------- */
  aboutToAppear() {
    const uiContext = this.getUIContext();
    this.router = uiContext.getRouter();
    this.promptAction = uiContext.getPromptAction();
    const abilityContext = this.getUIContext().getHostContext() as Context;
    this.loginVM.initializeDefaultUsers(abilityContext);
  }

  /* ---------------- UI ---------------- */
  build() {
    Column() {
      Text('Harmony\n  Health')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .shaderStyle({
          direction: GradientDirection.LeftTop,
          colors: [['#EC13FC', 0.0], ['#13D8FC', 1]]
        })
        .width('30%')
        .height(50)
        .margin({ top: 60, bottom: 60 })

      /* ========== 头像区域 ========== */
      Image(this.currentAvatar) // 👈 直接绑定
        .width(80)
        .height(80)
        .borderRadius('50%')
        .margin({ bottom: 60 })
        .objectFit(ImageFit.Cover)

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
        .onChange(v => {
          this.username = v;
          // 防抖更新头像
          if (this.debounceTimer !== -1) {
            clearTimeout(this.debounceTimer);
          }
          this.debounceTimer = setTimeout(() => {
            this.updateAvatarByUser();
          }, 300);
        })

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
    .justifyContent(FlexAlign.Start)
    .backgroundColor('#F5F6FA')
  }

  /**
   * 根据当前 username 查询用户，并更新头像
   */
  private async updateAvatarByUser(): Promise<void> {
    if (!this.username.trim()) {
      this.currentAvatar = $r('app.media.profileIcon');
      return;
    }

    try {
      const context = this.getUIContext().getHostContext() as Context;
      const user = await this.loginVM.getUserByUsername(context, this.username);

      if (user && user.avatar) {
        // 判断 avatar 是否为有效 URI（支持 file, persist, http）
        if (
          user.avatar.startsWith('file://') ||
          user.avatar.startsWith('persist://') ||
          user.avatar.startsWith('http://') ||
          user.avatar.startsWith('https://')
        ) {
          this.currentAvatar = user.avatar; // 直接使用 URI
          return;
        }
      }
      // 兜底：默认头像
      this.currentAvatar = $r('app.media.profileIcon');
    } catch (e) {
      console.warn('Failed to load user avatar:', e);
      this.currentAvatar = $r('app.media.profileIcon');
    }
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

  private safeNavigate(url: string, mode: 'push' | 'replace' = 'push'): void {
    if (!this.router) {
      this.showToast('页面跳转失败');
      return;
    }

    try {
      if (mode === 'push') {
        this.router.pushUrl({ url }).catch((e: Error) => {
          console.error('[Nav] pushUrl failed:', url, e);
          this.showToast('页面跳转失败');
        });
      } else {
        this.router.replaceUrl({ url }).catch((e: Error) => {
          console.error('[Nav] replaceUrl failed:', url, e);
          this.showToast('页面跳转失败');
        });
      }
    } catch (e) {
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