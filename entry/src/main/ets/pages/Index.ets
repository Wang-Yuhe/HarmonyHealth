// 加载页组件（自定义启动动画页）
import { router } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  // 初始状态
  @State iconScale: number = 0; // 图标从0开始
  @State iconOpacity: number = 0; // 图标透明度
  @State textOpacity: number = 0; // 文字透明度
  @State textOffset: number = 50; // 文字初始向下偏移 50vp

  onPageShow() {
    // 1. 图标弹跳进入 (0ms 开始)
    animateTo({
      duration: 1200, // 持续 1.2秒
      curve: Curve.EaseOut, // 使用缓出曲线
      delay: 100, // 稍微延迟一点点
      iterations: 1,
      playMode: PlayMode.Normal
    }, () => {
      this.iconScale = 1;
      this.iconOpacity = 1;
    })

    // 2. 文字上浮淡入 (600ms 开始，错开时间)
    animateTo({
      duration: 800,
      curve: Curve.EaseOut,
      delay: 600,
    }, () => {
      this.textOpacity = 1;
      this.textOffset = 0; // 回到原位
    })

    // 3. 页面跳转 (2500ms 后，留出足够时间看清文字)
    setTimeout(() => {
      this.jumpToLogin();
    }, 2500);
  }

  jumpToLogin() {
    try {
      // 销毁当前页，跳转登录
      this.getUIContext().getRouter().replaceUrl({ url: 'pages/LoginPage' });
    } catch (err) {
      console.error('Index jump failed:', err);
    }
  }

  build() {
    Stack() {
      Column() {
        // 图标
        Image($r('app.media.huawei'))
          .width(180)                 // 加大图标尺寸
          .height(180)
          .objectFit(ImageFit.Contain)
          .scale({ x: this.iconScale, y: this.iconScale })
          .opacity(this.iconOpacity)

        // 文字区域
        Column() {
          Text('Harmony Health')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ top: 24 })

          Text('您的智能健康管家')
            .fontSize(14)
            .fontColor('#888888')
            .margin({ top: 8 })
            .letterSpacing(4) // 增加字间距，更显高级
        }
        .opacity(this.textOpacity)
        .translate({ y: this.textOffset }) // 绑定位移属性
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}