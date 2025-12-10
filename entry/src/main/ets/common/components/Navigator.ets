/**
 * @file Navigator.ets
 * @description 底部导航栏 - 稳定版 (无位移，高亮明显)
 */
import router from '@ohos.router';

function normalizePath(path: string): string {
  return path.replace(/\/+$/g, '') // 去除尾部斜杠
}

@Component
export struct myNavigator {
  @State currentIndex: number = 0
  
  // 颜色配置
  private readonly activeColor: string = '#5C7CFF' // 选中：图标和文字颜色 (主蓝色)
  private readonly activeBgColor: string = '#E0E8FF' // 选中：背景颜色 (淡蓝色，高亮明显且柔和)
  private readonly inactiveColor: string = '#C4D0E5' // 未选中：浅蓝灰色

  aboutToAppear() {
    // 自动根据当前 URL 设置选中项
    const state = router.getState()
    const path = state.path + state.name
    if (path.includes('HomePage')) {
      this.currentIndex = 0
    } else if (path.includes('ExplorePage')) {
      this.currentIndex = 1
    } else if (path.includes('AskAIPage')) {
      this.currentIndex = 2
    }
  }

  build() {
    Row() {
      // 主页导航
      this.buildNavItem($r('app.media.homeIcon'), '主页', 0, 'pages/HomePage')

      // 健康信息推荐功能按钮
      this.buildNavItem($r('app.media.exploreIcon'), '探索', 1, 'pages/ExplorePage')

      // 个人主页，能够咨询，可以询问AI查询
      this.buildNavItem($r('app.media.profileIcon'), '咨询', 2, 'pages/AskAIPage')
    }
    .width('100%')
    .height(70)
    .backgroundColor('#FFFFFF')
    .padding({
      left: 16,
      right: 16,
      top: 8,
      bottom: 8
    })
    .shadow({
      radius: 10,
      color: 'rgba(0,0,0,0.05)',
      offsetX: 0,
      offsetY: -4
    })
    .position({ x: 0, y: '100%' })
    .markAnchor({ x: 0, y: '100%' })
  }

  @Builder
  buildNavItem(icon: Resource, text: string, index: number, routeUrl: string) {
    Column() {
      // 图标容器 - 固定大小，避免位置跳动
      Column() {
        Image(icon)
          .width(24)
          .height(24)
          .objectFit(ImageFit.Contain)
          // 选中变蓝，未选中变灰
          .fillColor(this.currentIndex === index ? this.activeColor : this.inactiveColor)
          .animation({ duration: 200 })
      }
      .width(48) // ✅ 固定宽度，防止图标左右移动
      .height(32)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      // 选中显示淡蓝色背景，未选中透明
      .backgroundColor(this.currentIndex === index ? this.activeBgColor : 'transparent')
      .borderRadius(16)
      .animation({ duration: 200 }) // 仅背景色渐变

      Text(text)
        .fontSize(11)
        .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.currentIndex === index ? this.activeColor : this.inactiveColor)
        .margin({ top: 4 })
        .animation({ duration: 200 })
    }
    .height('100%')
    .flexGrow(1)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      const state = router.getState()
      let currentPath = state.path + state.name
      if (normalizePath(currentPath) !== normalizePath(routeUrl)) {
        this.currentIndex = index
        animateTo({ duration: 200, curve: Curve.EaseInOut }, () => {
          router.replaceUrl({
            url: routeUrl,
            params: { transition: 'slide' }
          })
        })
      }
    })
  }
}