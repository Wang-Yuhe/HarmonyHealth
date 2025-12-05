// 加载页组件（当前入口页）
@Entry
@Component
struct Index {
  // 生命周期函数中启动加载
  aboutToAppear() {
    // 直接跳转到登录页面
    this.getUIContext().getRouter().replaceUrl({url: 'pages/LoginPage'});
  }
  build() {
  }
}
