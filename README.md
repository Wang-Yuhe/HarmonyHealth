# HarmonyHealth

一个基于HarmonyOS开发的综合健康管理应用，提供健康数据记录、AI健康咨询、运动追踪等功能。

## 快速开始

### 环境要求
- DevEco Studio 4.0+
- HarmonyOS SDK 4.0+
- Node.js 16+ (可选，用于命令行工具)

### 运行测试

#### 方法1: 使用DevEco Studio (推荐)
1. 打开DevEco Studio
2. 导入项目: `File` > `Open` > 选择项目根目录
3. 运行测试: 右键 `entry/src/ohosTest/ets/test/List.test.ets` > `Run`

**注意**: 测试文件位于ohosTest目录下，不是test目录下。

#### 方法2: 使用命令行脚本
```bash
# Windows
run-tests.bat all

# 或Linux/macOS
bash run-tests.sh all
```

#### 方法3: 使用npm脚本
```bash
npm install
npm run test
```

### 构建和运行
```bash
# 构建应用
npm run build

# 构建测试版本
npm run build:test

# 运行测试
npm run run:test
```

## 项目结构

```
HarmonyHealth/
├── entry/                          # 主模块
│   ├── src/
│   │   ├── main/                   # 主源码
│   │   │   ├── ets/
│   │   │   │   ├── common/         # 公共组件和工具
│   │   │   │   ├── database/       # 数据库相关
│   │   │   │   ├── features/       # 功能模块
│   │   │   │   └── pages/          # 页面
│   │   ├── test/                   # 单元测试
│   │   ├── ohosTest/               # 集成测试
│   │   └── mock/                   # 模拟数据
│   └── build-profile.json5         # 构建配置
├── hvigor/                         # 构建配置
├── oh_modules/                     # 依赖模块
└── build-profile.json5             # 应用构建配置
```

## 测试说明

项目包含完整的测试套件：

- **单元测试** (`LocalUnit.test.ets`): 8个测试用例
- **性能测试** (`Performance.test.ets`): 8个测试用例
- **稳定性测试** (`Stability.test.ets`): 8个测试用例
- **异常处理测试** (`ExceptionHandling.test.ets`): 8个测试用例

详细测试文档请参考：
- [系统测试与稳定性综合文档](SYSTEM_TEST_STABILITY_COMPREHENSIVE_DOC.md)
- [测试执行指南](TEST_EXECUTION_GUIDE.md)
- [测试执行时间分析](TEST_EXECUTION_TIME.md)
- [测试故障排除指南](TEST_TROUBLESHOOTING.md)
- [测试结果报告](TEST_RESULTS_REPORT.md)

## 功能特性

- 健康数据记录和追踪
- AI健康咨询助手
- 运动数据管理
- 用户账户管理
- 数据可视化图表

## 技术栈

- **框架**: HarmonyOS ArkTS
- **UI**: ArkUI声明式UI框架
- **测试**: @ohos/hypium测试框架
- **构建**: Hvigor构建工具
- **包管理**: OHPM

## 开发指南

### 代码规范
- 使用TypeScript编写
- 遵循HarmonyOS开发规范
- 组件化开发模式

### 测试驱动开发
项目采用测试驱动开发模式，所有新功能都需要对应的测试用例。

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