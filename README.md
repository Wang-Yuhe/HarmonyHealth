## 在dev分支工作

## 可复用组件说明

`/entry/src/main/ets/common/components`中实现了一些可以复用的组件：

- BackButton.ets：返回按键，位于页面左上角，点击返回上一个页面，使用方式参考

  ```TS
   build() {
    Stack() {//stack辅助布局
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

        。。。
 
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
          this.securityAnswer
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
  ```

  

- Navigator.ets：导航，位于页面底部，三个按钮点击跳转到对应页面，使用方式参考：

  ```TS
  /**
   * @file HomePage.ets
   * @description 应用主界面
   * @created 2025-12-03 09:12:10
   */
  import { myNavigator } from '../common/components/Navigator';
  
  @Entry
  @Component
  struct HomePage {
    build() {
      Stack({ alignContent: Alignment.Top }) {
        Column() {
          Column({ space: 16 }) {  // space 指定子项之间的间距一致
            this.HealthItem('步数', '#FFB6C1', 'HomeTo/StepsPage')
            this.HealthItem('睡眠质量', '#87CEFA', 'HomeTo/SleepPage')
            this.HealthItem('身体数据', '#98FB98', 'HomeTo/BodyInfoPage')
            this.HealthItem('疾病历史', '#DDA0DD', 'HomeTo/DiseasePage')
          }
          .height('90%')
          .padding(16)
          .width('100%')
  
          myNavigator() // 底部导航
        }
        .width('100%')
        .height('100%')
      }
      .backgroundColor('#F5F5F5')
    }
  
    @Builder
    HealthItem(title: string, bgColor: string, pageName: string) {
      Button() {
        Column() {
          Image($r(`app.media.ic_${pageName}`))
            .width(40)
            .height(40)
            .margin({ bottom: 8 })
  
          Text(title)
            .fontSize(18)
            .fontColor('#333')
        }
      }
      .padding(16)
      .borderRadius(16)
      .backgroundColor(bgColor)
      .width('100%')
      .onClick(() => {
        this.getUIContext().getRouter().pushUrl({ url: `pages/${pageName}`, })
      })
    }
  }
  
  ```

  

- 

## 页面文件说明

`entry/src/main/ets/pages`中实现页面，如果要添加新的页面记得在`entry/src/main/resources/base/profile/main_pages.json`中添加相关信息。