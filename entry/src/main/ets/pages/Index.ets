// 加载页组件（当前入口页）
@Entry
@Component
struct Index {
  aboutToAppear() {
    try {
      this.getUIContext().getRouter().replaceUrl({ url: 'pages/LoginPage' });
    } catch (err) {
      console.error('Index jump failed:', err);
    }
  }

  build() {
  }
}