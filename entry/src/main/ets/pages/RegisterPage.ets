/**
 * @file RegisterPage.ets
 * @description 注册/注销页面
 */

import { Context } from '@kit.AbilityKit';
import { Router, PromptAction, window } from '@kit.ArkUI';
import { LoginVM } from '../features/login/controller/LoginVM';
import { BackButton } from '../common/components/BackButton';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { dataSharePredicates } from '@kit.ArkData';
import { common } from '@kit.AbilityKit'
import fs from '@ohos.file.fs'; // 文件系统 API


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
  }

  aboutToDisappear(): void {
    if (this.avatarUri && this.avatarUri.startsWith('file://')) {
      const tempPath = this.avatarUri.slice(7); // 去掉 file://
      const tempDir  = (this.getUIContext().getHostContext() as common.UIAbilityContext).tempDir;
      // 只删本次落在 temp 目录的文件，防止误删
      if (tempPath.startsWith(tempDir)) {
        fs.unlink(tempPath).catch(() => {}); // 失败就忽略，页面都关了
      }
    }
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
      Image(
        this.avatarUri && this.avatarUri !== ''
          ? this.avatarUri                     // ① 先当字符串路径用
          : $r('app.media.profileIcon')        // ② 空或失败时回资源 ID
      )
        .width(40)
        .height(40)
        .borderRadius(20)
        .objectFit(ImageFit.Cover)
        .onError(() => {
          // ③ 连资源 ID 也失败（基本不会），再落回默认资源
          this.avatarUri = '';                 // 标记为空，下次走资源分支
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
    .onClick(() => this.pickAvatar())
    .margin({ bottom: 16 })
  }


  // ===== 新增：调起系统图片选择器 =====

  private async pickAvatar() {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    try {
      /* ========= 1. 选图 ========= */
      const selectOptions = new photoAccessHelper.PhotoSelectOptions();
      selectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      selectOptions.maxSelectNumber = 1;
      const picker = new photoAccessHelper.PhotoViewPicker();
      const selectResult = await picker.select(selectOptions);
      if (!selectResult.photoUris?.length) return;

      /* ========= 2. 取 PhotoAsset ========= */
      const uri = selectResult.photoUris[0];
      console.info('>>> 1. select success, uri=' + uri);

      const phHelper = photoAccessHelper.getPhotoAccessHelper(context);
      const predicates = new dataSharePredicates.DataSharePredicates();
      predicates.equalTo(photoAccessHelper.PhotoKeys.URI, uri);
      const fetchResult = await phHelper.getAssets({
        fetchColumns: [],
        predicates
      });
      const asset = await fetchResult.getFirstObject();
      fetchResult.close();

      /* ========= 3. 读原始 ArrayBuffer ========= */
       const imageBuffer = await new Promise<ArrayBuffer>((resolve, reject) => {
        photoAccessHelper.MediaAssetManager.requestImageData(
          context,
          asset,
          { deliveryMode: photoAccessHelper.DeliveryMode.HIGH_QUALITY_MODE },
          {
            onDataPrepared(data) {
              data ? resolve(data) : reject(new Error('empty buffer'));
            }
          } as photoAccessHelper.MediaAssetDataHandler<ArrayBuffer>
        );
      });
      console.info('>>> 2. imageBuffer length=' + imageBuffer.byteLength);

      /* ========= 4. 立即持久化：内存 → 私有目录 ========= */
      const tempPath = `${context.tempDir}/temp_avatar.jpg`;
      try { await fs.access(tempPath); } catch { await fs.mkdir(tempPath, true); }
      const destPath = `${tempPath}${'temp_avatar'}.jpg`;   // 永不重名

      const file = await fs.open(destPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      try {
        await fs.write(file.fd, imageBuffer);   // 裸 buffer，不带任何 options
      } finally {
        await fs.close(file.fd);
      }

      /* ========= 5. 仅把持久路径抛给 UI ========= */
      this.avatarUri = `file://${destPath}`;
      console.info('>>> 3. persistentUri = ' + this.avatarUri);

    } catch (e) {
      console.error('pickAvatar error:', e);
      this.showToast('头像选择失败');
    }
  }


  /**
   * 把临时头像文件移动到正式目录，文件名固定为 avatar_<用户名>.jpg
   * 成功返回新的 file:// 路径；失败返回空串。
   */
  private async moveAvatarToPersistent(): Promise<string> {
    if (!this.avatarUri || !this.avatarUri.startsWith('file://')) {
      // 没选图或路径异常
      return '';
    }

    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;

    try {
      /* 1. 源文件路径（去掉 file:// 前缀） */
      const srcPath = this.avatarUri.slice(7); // /data/storage/.../temp/xxx.jpg

      /* 2. 目标目录与文件（正式目录） */
      const destDir  = `${context.filesDir}/avatars/`;
      const destPath = `${destDir}avatar_${this.username}.jpg`; // 固定文件名

      /* 3. 确保目标目录存在 */
      try { await fs.access(destDir); } catch { await fs.mkdir(destDir, true); }



      /* 5. 原子移动（同盘符下 rename 即可） */
      await fs.moveFile(srcPath, destPath);

      /* 6. 返回新的持久化 URI */
      const persistentUri = `file://${destPath}`;
      console.info('[moveAvatar] success >>>', persistentUri);
      return persistentUri;
    } catch (e) {
      console.error('[moveAvatar] failed:', e);
      return '';
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

        /* === 头像落盘：内存 Buffer → 持久文件 === */
        let avatarPath:string='';
        if (this.avatarUri) {
          avatarPath=await this.moveAvatarToPersistent();
        }

        /* === 正式注册 === */
        const success = await this.loginVM.register(
          context,
          this.username,
          this.password,
          this.email,
          this.securityQuestion,
          this.securityAnswer,
          avatarPath
        );

        if (success) {
          this.showToast('注册成功');
          /* === 清掉临时文件 === */
          if (this.avatarUri.startsWith(`file://${context.tempDir}`)) {
            try { await fs.unlink(this.avatarUri.slice(7)); } catch {}
          }
          this.router?.back();
        } else {
          this.showToast('用户已存在');
        }
      } catch (e) {
        this.showToast('注册异常');
      }
    } else {
      /* ===== 注销分支无改动 ===== */
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