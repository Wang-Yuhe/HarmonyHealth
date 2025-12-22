/**
 * @file HomePage.ets
 * @description 应用主界面（UI 升级版 - 背景风格与探索页统一，增强弥散光感）
 */
import { myNavigator } from '../common/components/Navigator';
import { HealthVM } from '../features/healthStatus/viewmodel/HealthVM';
import { HealthData } from '../common/model/HealthData';
import { SleepData } from '../common/model/SleepData';
import { HealthDB } from '../database/HealthDB';
import { AuthUtil } from '../common/utils/AuthUtil';

// --- 全局配色常量 (与 ExploreView 保持一致) ---
const COLOR_BG_BASE = '#FFFFFF'; // 纯白底色，让光晕更透亮
const COLOR_PRIMARY = '#4A90E2';
const COLOR_ACCENT = '#FF6B6B';
const CARD_BG_GRADIENT_START = 'rgba(255, 255, 255, 0.85)'; // 卡片渐变起始
const CARD_BG_GRADIENT_END = 'rgba(255, 255, 255, 0.4)';   // 卡片渐变结束

@Component
struct HealthItemComponent {
  @Prop title: string = '';
  @Prop value: string = '';
  @Prop unit: string = '';
  @Prop themeColor: string = '';
  @Prop pageName: string = '';
  @Prop icon: ResourceStr = $r('app.media.startIcon');

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      // 1. 装饰背景：右上角的半透明大圆环
      Circle({ width: 80, height: 80 })
        .fill('transparent')
        .stroke(this.themeColor)
        .strokeWidth(12)
        .opacity(0.08) // 稍微增加一点可见度
        .margin({ top: -20, right: -20 })
        .blur(15)

      // 2. 主要内容
      Column() {
        // 头部：图标 + 标题
        Row() {
          Stack({ alignContent: Alignment.Center }) {
            Circle({ width: 32, height: 32 })
              .fill(this.themeColor)
              .opacity(0.15)

            Image(this.icon)
              .width(16)
              .height(16)
              .fillColor(this.themeColor)
              .objectFit(ImageFit.Contain)
          }
          .margin({ right: 10 })

          Text(this.title)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#555') // 字体稍微加深
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 12 })

        // 数值显示
        Row() {
          Text(this.value)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2C3E50')

          if (this.unit) {
            Text(this.unit)
              .fontSize(11)
              .fontColor('#888')
              .margin({ left: 4, bottom: 4 })
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Bottom)
      }
      .padding(18)
      .width('100%')
      .borderRadius(24)
      // 玻璃拟态背景：更通透，以展示下方鲜艳的背景
      .linearGradient({
        angle: 135,
        colors: [[CARD_BG_GRADIENT_START, 0.0], [CARD_BG_GRADIENT_END, 1.0]]
      })
      .backdropBlur(40) // 高斯模糊
      // 边框
      .border({
        width: 1.5,
        color: this.themeColor.startsWith('#') ? ('#66' + this.themeColor.substring(1)) : this.themeColor // 降低边框透明度
      })
      // 阴影
      .shadow({
        radius: 40,
        color: this.themeColor.startsWith('#') ? ('#30' + this.themeColor.substring(1)) : 'rgba(0,0,0,0.1)',
        offsetY: 20
      })
      .onClick(() => {
        this.getUIContext().getRouter().pushUrl({ url: this.pageName })
      })
    }
  }
}

@Entry
@Component
struct HomePage {
  @State currentData: HealthData = new HealthData(0, 0, 0, 0);
  @State todaySleep: SleepData | null = null;
  @State todaySteps: number = 0;
  private healthVM: HealthVM = new HealthVM();

  private handleLogout(): void {
    AlertDialog.show({
      title: '退出登录',
      message: '确定要退出当前登录吗？',
      autoCancel: true,
      alignment: DialogAlignment.Bottom,
      gridCount: 4,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '退出登录',
        fontColor: Color.Red,
        action: () => { this.executeLogoutAction() }
      }
    })
  }

  private async executeLogoutAction(): Promise<void> {
    AppStorage.setOrCreate('isLogin', false);
    AppStorage.setOrCreate('currentUser', null);
    AppStorage.setOrCreate('BodyInfoList', []);

    this.getUIContext().getRouter().replaceUrl({
      url: 'pages/LoginPage'
    }).catch((err: Error) => {
      console.error(`Navigation failed: ${err.message}`);
    });
  }

  async aboutToAppear() {
    const context = this.getUIContext().getHostContext() as Context;
    const lastData = await this.healthVM.loadLastData(context);
    if (lastData) this.currentData = lastData;

    await this.loadTodaySteps();
    await this.loadSleepData();
  }

  private async loadTodaySteps() {
    const context = this.getUIContext().getHostContext() as Context;
    const user = await AuthUtil.getLoginUser(context);
    if (!user) {
      this.todaySteps = 0;
      return;
    }
    await HealthDB.getInstance().initMockHealthData(user.id, 7);
    const list = await HealthDB.getInstance().getDailyStepsSummary(user.id, 7);
    const todayStr = new Date().toISOString().split('T')[0];
    const todayItem = list.find(item => {
      const d = new Date(item.timestamp);
      return d.toISOString().split('T')[0] === todayStr;
    });
    this.todaySteps = todayItem ? todayItem.steps : 0;
  }

  async loadSleepData() {
    const context = this.getUIContext().getHostContext() as Context;
    const user = await AuthUtil.getLoginUser(context);
    if (user) {
      await HealthDB.getInstance().initMockSleepData(user.id);
      const todayStr = new Date().toISOString().split('T')[0];
      this.todaySleep = await HealthDB.getInstance().getSleepDataByDate(user.id, todayStr);
    }
  }

  onPageShow() {
    const context = this.getUIContext().getHostContext() as Context;
    this.healthVM.startMonitoring(context, 3000, async (data: HealthData) => {
      this.currentData = data;
      await this.loadTodaySteps();
    });
    this.loadSleepData();
  }

  onPageHide() { this.healthVM.stopMonitoring(); }
  aboutToDisappear() { this.healthVM.stopMonitoring(); }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // --- 1. 背景层 (更新：与 ExploreView 一致的鲜艳色块) ---
      this.BackgroundDecorations()

      // --- 2. 主内容区域 ---
      Column() {
        // Header
        Row() {
          Column() {
            Text('Harmony Health')
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2C3E50')
            Text('您的智能健康管家')
              .fontSize(13)
              .fontColor('#7F8C8D')
              .margin({ top: 4 })
              .letterSpacing(1)
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          // 头像
          Image(AppStorage.get('avatar') ?? $r('app.media.profileIcon'))
            .width(42)
            .height(42)
            .borderRadius(21)
            .objectFit(ImageFit.Cover)
            .border({ width: 2, color: 'rgba(255,255,255,0.8)' })
            .shadow({ radius: 10, color: 'rgba(74, 144, 226, 0.3)', offsetY: 4 })
            .onClick(() => {
              this.getUIContext().getRouter().pushUrl({ url: 'pages/UserCenterPage' });
            })
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 20, bottom: 10 })
        .zIndex(2)

        Scroll() {
          Column({ space: 16 }) {
            // 人体模型卡片 - Hero Card
            Stack({ alignContent: Alignment.TopStart }) {
              // 卡片内部装饰
              Circle({ width: 140, height: 140 })
                .fill('#5C7CFF')
                .opacity(0.1) // 略微提高
                .position({ x: '60%', y: -30 })
                .blur(30)

              Column() {
                Image($r('app.media.body2'))
                  .height(170)
                  .objectFit(ImageFit.Contain)
                  .margin({ bottom: 16 })
                  .shadow({ radius: 20, color: 'rgba(0,0,0,0.12)', offsetY: 10 })

                Row() {
                  Column() {
                    Text('身体健康档案')
                      .fontSize(18)
                      .fontColor('#333')
                      .fontWeight(FontWeight.Bold)
                    Text('BMI · 体围数据 · 体态分析')
                      .fontSize(12)
                      .fontColor('#888')
                      .margin({ top: 6 })
                  }
                  .alignItems(HorizontalAlign.Start)

                  Blank()

                  // 按钮
                  Row() {
                    Text('查看详情')
                      .fontSize(12)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(Color.White)
                    Image($r('app.media.startIcon'))
                      .width(10)
                      .height(10)
                      .fillColor(Color.White)
                      .margin({ left: 4 })
                  }
                  .linearGradient({
                    angle: 90,
                    colors: [['#5C7CFF', 0.0], ['#448AFF', 1.0]]
                  })
                  .shadow({ radius: 8, color: 'rgba(92, 124, 255, 0.4)', offsetY: 4 })
                  .padding({ left: 14, right: 10, top: 8, bottom: 8 })
                  .borderRadius(18)
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)
              }
              .padding(24)
            }
            .width('100%')
            .borderRadius(28)
            // 玻璃拟态
            .linearGradient({
              angle: 135,
              colors: [[CARD_BG_GRADIENT_START, 0.0], [CARD_BG_GRADIENT_END, 1.0]]
            })
            .backdropBlur(40)
            .border({ width: 1.5, color: 'rgba(92, 124, 255, 0.3)' })
            .shadow({ radius: 35, color: 'rgba(92, 124, 255, 0.25)', offsetY: 15 })
            .onClick(() => {
              this.getUIContext().getRouter().pushUrl({ url: 'pages/HomeTo/BodyInfoPage' })
            })

            // 双列布局
            Row({ space: 14 }) {
              HealthItemComponent({
                title: '今日步数',
                value: `${this.todaySteps}`,
                unit: '步',
                themeColor: '#FF7043',
                pageName: 'pages/HomeTo/StepsPage',
                icon: $r('app.media.steps')
              })
                .layoutWeight(1)

              HealthItemComponent({
                title: '睡眠时长',
                value: this.todaySleep ? `${(this.todaySleep.totalMinutes / 60).toFixed(1)}` : '0.0',
                unit: '小时',
                themeColor: '#2962FF',
                pageName: 'pages/HomeTo/SleepPage',
                icon: $r('app.media.sleep')
              })
                .layoutWeight(1)
            }

            // 实时状态卡片
            HealthItemComponent({
              title: '实时健康监测',
              value: `${this.currentData.heartRate} bpm  |  ${this.currentData.bloodOxygen}%`,
              unit: '心率 / 血氧',
              themeColor: '#00C853',
              pageName: 'features/healthStatus/view/StatusPage',
              icon: $r('app.media.instantcheck')
            })

            // 疾病历史
            HealthItemComponent({
              title: '疾病历史档案',
              value: '查看记录',
              unit: '',
              themeColor: '#7E57C2',
              pageName: 'pages/HomeTo/DiseasePage',
              icon: $r('app.media.diseasehistory')
            })

            Blank().height(100)
          }
          .padding({ left: 20, right: 20, top: 10 })
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .padding({ bottom: 56 })

      // 3. 底部导航栏
      myNavigator()

    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLOR_BG_BASE)
  }

  /**
   * 构建背景装饰层
   * 与 ExploreView 风格统一：鲜艳、高模糊、白底
   */
  @Builder
  BackgroundDecorations(): void {
    Stack() {
      // 1. 左上角 - 主色调蓝色 (Blue)
      // 略微调大尺寸，覆盖 Header 区域
      Circle({ width: 320, height: 320 })
        .fill('rgba(74, 144, 226, 0.35)') // Opacity 0.35
        .position({ x: -80, y: -100 })
        .blur(80)

      // 2. 右侧中部 - 活力紫色 (Purple)
      // 对应“身体档案”和“睡眠”卡片位置
      Circle({ width: 280, height: 280 })
        .fill('rgba(108, 92, 231, 0.35)')
        .position({ x: '60%', y: 150 })
        .blur(70)

      // 3. 左下方 - 暖色强调 (Red/Pink)
      // 对应“步数”位置
      Circle({ width: 300, height: 300 })
        .fill('rgba(255, 107, 107, 0.25)')
        .position({ x: -100, y: 400 })
        .blur(90)

      // 4. 右下角 - 清新绿色 (Green)
      // 对应“实时监测”和底部
      Circle({ width: 240, height: 240 })
        .fill('rgba(46, 204, 113, 0.25)')
        .position({ x: '50%', y: '85%' })
        .blur(60)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLOR_BG_BASE)
  }
}