/**
 * @file RegisterPage.ets
 * @description 注册/注销页面
 */

import { Context } from '@kit.AbilityKit';
import { Router, PromptAction, window } from '@kit.ArkUI';
import { LoginVM } from '../features/login/controller/LoginVM';
import { BackButton } from '../common/components/BackButton';
import { abilityAccessCtrl } from '@kit.AbilityKit';

import { photoAccessHelper } from '@kit.MediaLibraryKit';

interface PhotoSelectOptions {
  MIMEType: string;
  maxSelectNumber: number;
}

interface PhotoAsset {
  uri: string;
}

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

  @State avatarUri: string = '';

  private loginVM: LoginVM = new LoginVM();
  private promptAction: PromptAction | null = null;
  @Provide router: Router | null = null;

  // 安全初始化 UI 上下文
  aboutToAppear() {
    const uiContext = this.getUIContext();
    this.router = uiContext.getRouter();
    this.promptAction = uiContext.getPromptAction();
    this.avatarUri=$r('app.media.profileIcon').id.toString();
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

            this.buildAvatarPicker()

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

  // ===== 新增：头像选择 UI 组件 =====
  @Builder
  buildAvatarPicker() {
    Row() {
      // 左侧：头像预览（圆形）
      Image(this.avatarUri)
        .width(40)
        .height(40)
        .borderRadius(20) // 圆形
        .objectFit(ImageFit.Cover)
        .onError(() => {
          // 加载失败时回退到默认头像
          this.avatarUri = $r('app.media.profileIcon').id.toString();
        })

      // 右侧：提示文字
      Text('点击上传头像')
        .fontColor('#666666')
        .fontSize(16)
        .opacity(0.8)
    }
    .width('100%')
    .height(56)
    .padding({
      left: 12,
      right: 12,  // 替代horizontal
      top: 8,
      bottom: 8   // 替代vertical
    })
    .backgroundColor('#FFFFFF')
    .border({ width: 1, color: '#E0E0E0' })
    .borderRadius(12)
    .justifyContent(FlexAlign.SpaceBetween) // 自动分配左右空间
    .onClick(() => this.pickImage())
    .margin({ bottom: 16 })
  }

  // ===== 新增：检查并申请相册读取权限 =====
  private async checkAndRequestPermission(): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();

    const hostContext = this.getUIContext().getHostContext() as Context;
    const tokenId = hostContext?.applicationInfo?.accessTokenId ?? 0;
    const permission = 'ohos.permission.READ_IMAGEVIDEO';

    // 检查是否已授权
    const authStatus = await atManager.checkAccessToken(tokenId, permission);
    if (authStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      return true;
    }

    // 未授权，发起请求
    try {
      const requestResult = await atManager.requestPermissionsFromUser(hostContext, [permission]);
      return requestResult.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (err) {
      console.error('Permission request failed:', err);
      return false;
    }
  }

  // ===== 新增：调起系统图片选择器 =====

  private async pickImage() {
    const hasPermission = await this.checkAndRequestPermission();
    if (!hasPermission) {
      this.showToast('需要相册访问权限才能上传头像');
      return;
    }

    try {
      // ✅ 直接调用 select（注意：不是 createPhotoPicker）
      const options: PhotoSelectOptions = {
        MIMEType: 'image/*', // ✅ 使用标准 MIME 字符串（更兼容）
        maxSelectNumber: 1
      };

      const photoAccessor =new photoAccessHelper.PhotoViewPicker();
      const photoAccessOptions = new photoAccessHelper.PhotoSelectOptions();
      photoAccessOptions.maxSelectNumber=1;

      const result: photoAccessHelper.PhotoSelectResult = await photoAccessor.select(photoAccessOptions);

      if (!result || !result.photoUris || result.photoUris.length === 0) {
        this.showToast('未选择图片');
        return;
      }

      const asset = result.photoUris[0];
      if (!asset|| typeof asset!== 'string') {
        this.showToast('图片 URI 无效');
        return;
      }

      const context = this.getUIContext().getHostContext() as Context;
      const targetUsername = this.username || `temp_${Date.now()}`;
      const savedUri = await this.loginVM.saveUserAvatar(context, targetUsername, asset);

      if (savedUri) {
        this.avatarUri = savedUri;
        this.showToast('头像上传成功');
      } else {
        this.showToast('头像保存失败');
      }

    } catch (err) {
      console.error('[pickImage] Error:', err);
      this.showToast(`操作失败: ${(err as Error).message}`);
    }
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
          this.securityAnswer,
          this.avatarUri
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