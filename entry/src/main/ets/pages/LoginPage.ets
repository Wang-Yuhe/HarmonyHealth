/**
 * @file LoginPage.ets
 * @description 登录界面（UI 优化版 - 蓝色主题）
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
    Stack() {
      // 1. 背景层：改为与 AskAIPage 呼应的蓝色系渐变
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [['#E0E8FF', 0.0], ['#F5F7FA', 1.0]] // 浅蓝到浅灰，清新通透
        })

      // 装饰性大圆 - 蓝色系
      Circle({ width: 200, height: 200 })
        .fill('#5C7CFF')
        .opacity(0.08)
        .position({ x: -50, y: -50 })
        .blur(40)

      Circle({ width: 150, height: 150 })
        .fill('#4A65E0')
        .opacity(0.08)
        .position({ x: '85%', y: '15%' })
        .blur(40)

      // 2. 内容层
      Column() {
        // 标题区域
        Column({ space: 8 }) {
          Text('Harmony Health')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333') // 深灰标题，更显沉稳
            .textAlign(TextAlign.Center)

          Text('您的智能健康管家')
            .fontSize(14)
            .fontColor('#666666')
            .letterSpacing(2)
        }
        .margin({ top: 100, bottom: 50 })

        // 登录卡片
        Column() {
          /* ========== 头像区域 ========== */
          Image(this.currentAvatar)
            .width(84)
            .height(84)
            .borderRadius(42)
            .margin({ top: -42, bottom: 24 }) // 向上负边距，实现悬浮效果
            .objectFit(ImageFit.Cover)
            .border({ width: 4, color: '#FFFFFF' }) // 白色边框
            .shadow({ radius: 12, color: 'rgba(92, 124, 255, 0.2)', offsetY: 6 }) // 蓝色系阴影

          /* 输入区域 */
          Column({ space: 16 }) {
            // 用户名输入框
            this.InputGroup('请输入用户名', false, (val) => {
              this.username = val;
              if (this.debounceTimer !== -1) {
                clearTimeout(this.debounceTimer);
              }
              this.debounceTimer = setTimeout(() => {
                this.updateAvatarByUser();
              }, 300);
            })
            // 密码输入框
            this.InputGroup('请输入密码', true,
              (val) => this.password = val)
          }
          .padding({ left: 32, right: 32, bottom: 32 })
          .width('100%')

          /* 登录按钮 */
          Button('登 录')
            .width('80%')
            .height(48)
            .backgroundColor('#5C7CFF') // 统一的主蓝色
            .fontColor('#FFFFFF')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .borderRadius(24)
            .shadow({ radius: 10, color: 'rgba(92, 124, 255, 0.4)', offsetY: 4 })
            .onClick(() => this.handleLogin())
            .margin({ bottom: 24 })

          /* 文字链区域 */
          Row() {
            Text('注册账号')
              .fontSize(14)
              .fontColor('#5C7CFF') // 蓝色链接
              .onClick(() => this.gotoRegister())
              .padding(8)

            Text('|')
              .fontSize(14)
              .fontColor('#E0E0E0')
              .margin({ left: 4, right: 4 })

            Text('忘记密码')
              .fontSize(14)
              .fontColor('#999999')
              .onClick(() => this.gotoResetPwd())
              .padding(8)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 24 })

        }
        .width('85%')
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
        .shadow({ radius: 40, color: 'rgba(0,0,0,0.06)', offsetY: 10 }) // 更柔和的大范围阴影
        .alignItems(HorizontalAlign.Center)

      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  // 封装输入框组件 - 极简风格
  @Builder
  InputGroup(placeholder: string, isPassword: boolean, onChange: (val: string) => void) {
    Row() {
      TextInput({ placeholder: placeholder })
        .type(isPassword ? InputType.Password : InputType.Normal)
        .placeholderColor('#C0C4CC')
        .fontColor('#333333')
        .fontSize(16)
        .caretColor('#5C7CFF') // 蓝色光标
        .backgroundColor(Color.Transparent) // 透明背景
        .layoutWeight(1)
        .height(48)
        .onChange(onChange)
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor('#F5F7FA') // 极浅灰底色，比纯白更有质感
    .borderRadius(24) // 全圆角，更现代
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
        const context = this.getUIContext().getHostContext() as Context;
        let user=await this.loginVM.getUserByUsername(context,this.username);
        AppStorage.setOrCreate('currentUser', user?.username);
        AppStorage.setOrCreate('avatar',this.currentAvatar);
        AppStorage.setOrCreate('email',user?.email)
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