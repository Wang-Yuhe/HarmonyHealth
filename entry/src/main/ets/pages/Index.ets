// 加载页组件（当前入口页）
@Entry
@Component
struct Index {
  aboutToAppear() {
    try {
      // 暂时跳过登录，直接跳转到主页
      this.getUIContext().getRouter().replaceUrl({ url: 'pages/HomePage' });
    } catch (err) {
      console.error('Index jump failed:', err);
    }
  }

  build() {
  }
}