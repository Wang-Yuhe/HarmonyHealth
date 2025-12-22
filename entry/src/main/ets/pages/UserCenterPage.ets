import router from '@ohos.router';
import { PromptAction } from '@kit.ArkUI';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { dataSharePredicates } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';
import { HealthDB } from '../database/HealthDB';
import { image } from '@kit.ImageKit'; 

@Entry
@Component
struct UserCenterPage {
  /* ===== 状态 ===== */
  // 2. 修改类型定义，支持 PixelMap
  @State avatarUri: string | Resource | image.PixelMap = AppStorage.get('avatar') ?? $r('app.media.profileIcon');
  @State username: string = AppStorage.get('currentUser') ?? '';
  @State email: string = AppStorage.get('email') ?? '';
  @State newPwd: string = '';
  @State confirmPwd: string = '';
  @State showPwdDialog: boolean = false;

  /* ===== 临时缓存 ===== */
  @State oldUsername: string = AppStorage.get('currentUser') ?? '';
  @State oldEmail: string = AppStorage.get('email') ?? '';

  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private promptAction: PromptAction = this.getUIContext().getPromptAction();
  private db: HealthDB = HealthDB.getInstance();

  /* ===== 1. 换头像 + 持久化 ===== */
  private async changeAvatar() {
    try {
      const selectOptions = new photoAccessHelper.PhotoSelectOptions();
      selectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      selectOptions.maxSelectNumber = 1;
      const picker = new photoAccessHelper.PhotoViewPicker();
      const result = await picker.select(selectOptions);
      if (!result.photoUris?.length) return;

      const uri = result.photoUris[0];
      const phHelper = photoAccessHelper.getPhotoAccessHelper(this.context);
      const predicates = new dataSharePredicates.DataSharePredicates();
      predicates.equalTo(photoAccessHelper.PhotoKeys.URI, uri);
      const fetchResult = await phHelper.getAssets({ fetchColumns: [], predicates });
      const asset = await fetchResult.getFirstObject();
      fetchResult.close();

      const buffer = await new Promise<ArrayBuffer>((resolve, reject) => {
        photoAccessHelper.MediaAssetManager.requestImageData(
          this.context, asset,
          { deliveryMode: photoAccessHelper.DeliveryMode.HIGH_QUALITY_MODE },
          { onDataPrepared: d => d ? resolve(d) : reject(new Error('empty')) }
        );
      });

      const oldUri = AppStorage.get('avatar') as string;
      if (!oldUri || !oldUri.startsWith('file://')) {
        this.promptAction.showToast({ message: '旧头像路径异常' });
        return;
      }
      const destPath = oldUri.slice(7);
      
      // 3. 修改：增加 TRUNC 选项，确保新文件覆盖时若变小不会残留旧数据
      const file = await fs.open(destPath, fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      await fs.write(file.fd, buffer);
      await fs.close(file.fd);

      // 4. 修改：使用 PixelMap 强制刷新 UI，解决同名文件覆盖不刷新的问题
      const imageSource = image.createImageSource(buffer);
      this.avatarUri = await imageSource.createPixelMap();
      
      this.promptAction.showToast({ message: '头像已更新' });
    } catch (e) {
      this.promptAction.showToast({ message: '换头像失败' });
    }
  }

  private async saveUsername(): Promise<void> {
    const newName = this.username.trim();
    if (!newName) {
      this.promptAction.showToast({ message: '用户名不能为空' });
      return;
    }
    if (newName === this.oldUsername) {
      this.promptAction.showToast({ message: '用户名未变动' });
      return;
    }
    const exist = await this.db.getUserByUsername(newName);
    if (exist) {
      this.promptAction.showToast({ message: '用户名已存在' });
      return;
    }
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const oldUri = AppStorage.get('avatar') as string;
    let newUri = oldUri;
    if (oldUri?.startsWith('file://')) {
      const oldPath = oldUri.slice(7);
      const newPath = `${ctx.filesDir}avatar_${newName}`;
      try {
        await fs.access(newPath).then(() => fs.unlink(newPath)).catch(() => {});
        await fs.mkdir(ctx.filesDir, true);
        await fs.moveFile(oldPath, newPath);
        newUri = `file://${newPath}`;
      } catch {
        this.promptAction.showToast({ message: '头像移动失败' });
        return;
      }
    }
    const okName = await this.db.updateUsername(this.oldUsername, newName);
    if (!okName) {
      this.promptAction.showToast({ message: '用户名更新失败' });
      return;
    }
    await this.db.setUserAvatar(newName, newUri);
    this.oldUsername = newName;
    AppStorage.set('currentUser', newName);
    AppStorage.set('avatar', newUri);
    this.avatarUri = newUri;
    this.promptAction.showToast({ message: '用户名已更新' });
  }

  private async saveEmail(): Promise<void> {
    const newMail = this.email.trim();
    if (!newMail) {
      this.promptAction.showToast({ message: '邮箱不能为空' });
      return;
    }
    if (newMail === this.oldEmail) {
      this.promptAction.showToast({ message: '邮箱未变动' });
      return;
    }
    const ok = await this.db.updateEmail(this.oldUsername, newMail);
    if (!ok) {
      this.promptAction.showToast({ message: '邮箱更新失败' });
      return;
    }
    this.oldEmail = newMail;
    AppStorage.set('email', newMail);
    this.promptAction.showToast({ message: '邮箱已更新' });
  }

  /* ===== 修改密码底部弹窗（沉底 + 半透明 + 圆角）===== */
  @Builder
  pwdDialog() {
    Column({ space: 0 }) {


      // 2. 标题
      Text('修改密码')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 12, bottom: 16 })

      // 3. 输入框卡片
      Column({ space: 12 }) {
        TextInput({ placeholder: '新密码' })
          .type(InputType.Password).width('90%')
          .onChange(v => this.newPwd = v)

        TextInput({ placeholder: '再次输入' })
          .type(InputType.Password).width('90%')
          .onChange(v => this.confirmPwd = v)
      }
      .padding(12)
      .width('90%')
      .backgroundColor('#F5F5F5')
      .borderRadius(8)
      .padding({top:48})

      // 4. 弹簧：沉底按钮
      Blank()

      // 5. 底部操作栏
      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#EEEEEE')
          .fontColor('#666')
          .onClick(() => this.showPwdDialog = false)

        Button('确定')
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#5C7CFF')
          .fontColor(Color.White)
          .onClick(async () => {
            // 完整密码修改逻辑
            if (!this.newPwd || this.newPwd !== this.confirmPwd) {
              this.promptAction.showToast({ message: '两次密码不一致' });
              return;
            }
            const user = await this.db.getUserByUsername(this.username);
            if (user && user.password === this.newPwd) {
              this.promptAction.showToast({ message: '新密码不能与旧密码相同' });
              return;
            }
            const ok = await this.db.updatePassword(this.username, this.newPwd);
            if (ok) {
              this.promptAction.showToast({ message: '密码已修改，请重新登录' });
              this.showPwdDialog = false;
              AppStorage.set('currentUser', '');
              AppStorage.set('avatar', '');
              router.replaceUrl({ url: 'pages/LoginPage' });
            } else {
              this.promptAction.showToast({ message: '密码修改失败' });
            }
          })
      }
      .width('90%')
      .height(48)
      .margin({ bottom: 32 })
    }
    .width('100%')
    .padding({top:48})
    .height('50%')                      // 屏幕一半高度
    .backgroundColor('rgba(255,255,255,0.95)') // 可调整透明度
    .borderRadius({ topLeft: 16, topRight: 16 })
    .justifyContent(FlexAlign.SpaceBetween)   // 沉底
  }

  /* ===== 6. 注销 ===== */
  private async handleDelete() {
    AlertDialog.show({
      title: '注销账号',
      message: '注销后数据无法恢复，确定继续？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '注销',
        fontColor: Color.Red,
        action: async () => {
          this.promptAction.showToast({ message: '账号已注销' });
          AppStorage.set('currentUser', '');
          AppStorage.set('avatar', '');
          router.replaceUrl({ url: 'pages/LoginPage' });
        }
      }
    });
  }

  /* ===== 7. 退出登录 ===== */
  private async handleLogout() {
    AlertDialog.show({
      title: '退出登录',
      message: '确定要退出当前登录吗？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '退出',
        fontColor: Color.Red,
        action: () => {
          AppStorage.set('currentUser', '');
          AppStorage.set('avatar', '');
          router.replaceUrl({ url: 'pages/LoginPage' });
        }
      }
    });
  }

  build() {
    Column({ space: 20 }) {
      Stack({ alignContent: Alignment.Bottom}) {
        Row() {
          Image($r('app.media.backButton'))
            .width(24)
            .onClick(() => router.back())
        }
        .position({ x: 16, y: 12 })   // 左上角固定

        Text('个人中心')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
      }
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .width('100%')
      .backgroundColor(Color.White)

      /* 1. 头像 */
      Stack() {
        Image(this.avatarUri)
          .id('avatarImg')
          .width(88).height(88).borderRadius(44)
          .objectFit(ImageFit.Cover)
          .border({ width: 4, color: '#FFFFFFFF' })
        Circle()
          .width(88).height(88).fill(Color.Transparent)
          .onClick(() => this.changeAvatar())
      }
      .shadow({ radius: 12, color: 'rgba(92,124,255,0.2)', offsetY: 6 })

      /* 2. 用户名（可编辑）+ 保存按钮 */
      Row() {
        Text('用户名').fontColor('#888').width(80)
        TextInput({ text: this.username })
          .layoutWeight(1)
          .onChange(v => this.username = v)
        Button('保存')
          .height(32).margin({ left: 8 })
          .onClick(() => this.saveUsername())
      }.padding({ left: 24, right: 24 })

      /* 3. 邮箱（可编辑）+ 保存按钮 */
      Row() {
        Text('邮箱').fontColor('#888').width(80)
        TextInput({ text: this.email })
          .layoutWeight(1)
          .onChange(v => this.email = v)
        Button('保存')
          .height(32).margin({ left: 8 })
          .onClick(() => this.saveEmail())
      }.padding({ left: 24, right: 24 })

      /* 4. 修改密码（触发下半屏弹窗）*/
      Button('修改密码')
        .width('90%').height(44)
        .onClick(() => this.showPwdDialog = true)

      /* 5. 注销账号（灰色按钮）*/
      Button('注销账号')
        .width('90%').height(44)
        .backgroundColor('#888888') // 灰色
        .onClick(() => this.handleDelete())

      Blank()

      /* 6. 退出登录（最底部） */
      Button('退出登录')
        .width('90%').height(48)
        .backgroundColor('#5C7CFF')
        .margin({ bottom: 32 })
        .onClick(() => this.handleLogout())
    }
    .width('100%').height('100%')
    .padding({ top: 32 })
    .backgroundColor('#F2F5F9')
    .bindContentCover(
      this.showPwdDialog,
      this.pwdDialog(),
      { backgroundColor: 'rgba(0,0,0,0.5)' }
    )
  }
}