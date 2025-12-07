/**
 * @file Navigator.ets
 * @description 底部导航栏
 */

function normalizePath(path: string): string {
  return path.replace(/\/+$/g, '') // 去除尾部斜杠
}

@Component
export struct myNavigator {
  @State currentIndex: number = 0

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
    .height(60)
    .backgroundColor('#FFFFFF')
    .padding({ left: 20, right: 20 })
    .shadow({ radius: 8, color: '#20000000', offsetX: 0, offsetY: -2 })
    .position({ x: 0, y: '96%' })
    .margin({ bottom: -60 })
  }

  @Builder
  buildNavItem(icon: Resource, text: string, index: number, routeUrl: string) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
        .margin({ bottom: 4 })
        .opacity(this.currentIndex === index ? 1 : 0.5)

      Text(text)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? '#007AFF' : '#666666')
    }
    .flexGrow(1)
    .onClick(() => {
      const state = this.getUIContext().getRouter().getState()
      let currentPath = state.path + state.name
      // 页面不同时才跳转
      if(normalizePath(currentPath) !== normalizePath(routeUrl))
        this.getUIContext().animateTo({ duration: 100 }, () => {
          this.currentIndex = index
          this.getUIContext().getRouter().replaceUrl({
            url: routeUrl,
            params: { transition: 'slide' }
          })
        })
    })
  }
}