/**
 * @file HomePage.ets
 * @description 应用主界面（UI 优化版 - 修复导航栏）
 */
import { myNavigator } from '../common/components/Navigator';
import { HealthVM } from '../features/healthStatus/viewmodel/HealthVM';
import { HealthData } from '../common/model/HealthData';
import { SleepData } from '../common/model/SleepData';
import { HealthDB } from '../database/HealthDB';

@Component
struct HealthItemComponent {
  @Prop title: string = '';
  @Prop value: string = '';
  @Prop unit: string = '';
  @Prop themeColor: string = '';
  @Prop pageName: string = '';
  @Prop icon: ResourceStr = $r('app.media.startIcon');

  build() {
    Column() {
      // 1. 头部：图标 + 标题
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          Circle({ width: 36, height: 36 })
            .fill(this.themeColor)
            .opacity(0.15)

          Image(this.icon)
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
        }
        .margin({ right: 12 })

        Text(this.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#666')
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 12 })

      // 2. 数值显示
      Row() {
        Text(this.value)
          .fontSize(24) // 加大数值字体
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')

        if (this.unit) {
          Text(this.unit)
            .fontSize(12)
            .fontColor('#999')
            .margin({ left: 4, bottom: 4 })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)

      // 3. 底部装饰条
      Row()
        .width('40%')
        .height(4)
        .backgroundColor(this.themeColor)
        .borderRadius(2)
        .margin({ top: 12 })
        .opacity(0.8)

    }
    .padding(16)
    .borderRadius(24) // 更大的圆角
    .backgroundColor('#FFFFFF')
    .shadow({ radius: 20, color: 'rgba(0,0,0,0.05)', offsetY: 8 }) // 更柔和的阴影
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.getUIContext().getRouter().pushUrl({ url: this.pageName })
    })
  }
}

@Entry
@Component
struct HomePage {
  @State currentData: HealthData = new HealthData(0, 0, 0, 0);
  @State todaySleep: SleepData | null = null;
  private healthVM: HealthVM = new HealthVM();

  private STEP_GOAL: number = 5000;
  private SLEEP_GOAL: number = 8;

  private lerpColor(color1: string, color2: string, t: number): string {
    // 简化的颜色插值，实际项目中建议使用更严谨的算法
    return t > 0.5 ? color2 : color1;
  }

  private getStepColor(steps: number): string {
    return steps >= this.STEP_GOAL ? '#00C853' : '#FF8A80';
  }

  private getSleepColor(hours: number): string {
    return hours >= this.SLEEP_GOAL ? '#448AFF' : '#FFD740';
  }

  /**
   * 退出登录逻辑
   * 使用 ActionSheet 提供底部弹出选择
   */
  private handleLogout(): void {
    AlertDialog.show({
      title: '退出登录',
      message: '确定要退出当前登录吗？',
      autoCancel: true,
      alignment: DialogAlignment.Bottom, // 依然可以从底部弹出
      gridCount: 4,
      primaryButton: {
        value: '取消',
        action: () => {
          console.info('用户取消退出')
        }
      },
      secondaryButton: {
        value: '退出登录',
        fontColor: Color.Red, // 这里支持 fontColor
        action: () => {
          this.executeLogoutAction()
        }
      }
    })
  }

  private executeLogoutAction(): void {
    AppStorage.SetOrCreate('isLogin', false);
    this.getUIContext().getRouter().replaceUrl({
      url: 'pages/LoginPage'
    })
  }

  async aboutToAppear() {
    const lastData = await this.healthVM.loadLastData();
    if (lastData) {
      this.currentData = lastData;
    }
    await this.loadSleepData();
  }

  async loadSleepData() {
    const todayStr = new Date().toISOString().split('T')[0];
    this.todaySleep = await HealthDB.getInstance().getSleepDataByDate(todayStr);
  }

  onPageShow() {
    this.healthVM.startMonitoring(3000, (data) => {
      this.currentData = data;
    });
    this.loadSleepData();
  }

  onPageHide() {
    this.healthVM.stopMonitoring();
  }

  aboutToDisappear() {
    this.healthVM.stopMonitoring();
  }

  build() {
    // 使用 Stack 确保导航栏浮在最上方
    Stack({ alignContent: Alignment.Bottom }) {
      // 1. 背景层
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [['#E0E8FF', 0.0], ['#F5F7FA', 0.6], ['#FFFFFF', 1.0]]
        })

      // 2. 主内容区域
      Column() {
        // Header
        Row() {
          Column() {
            Text('Harmony Health')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333')
            Text('您的智能健康管家')
              .fontSize(14)
              .fontColor('#666')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Image($r('app.media.logout'))
            .width(35)
            .height(35)
            .objectFit(ImageFit.Cover)
            .onClick(() => {
              this.handleLogout()
            })
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 20, bottom: 10 })

        Scroll() {
          Column({ space: 16 }) {
            // 人体模型卡片
            Column() {
              Image($r('app.media.body2'))
                .height(200)
                .objectFit(ImageFit.Contain)
                .margin({ bottom: 10 })

              Text('点击查看尺码档案 >')
                .fontSize(14)
                .fontColor('#5C7CFF')
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#FFFFFF')
            .borderRadius(24)
            .shadow({ radius: 20, color: 'rgba(92, 124, 255, 0.1)', offsetY: 8 })
            .onClick(() => {
              this.getUIContext().getRouter().pushUrl({
                url: 'pages/HomeTo/BodyInfoPage'
              })
            })

            // 双列布局
            Row({ space: 12 }) {
              HealthItemComponent({
                title: '今日步数',
                value: `${this.currentData.steps}`,
                unit: '步',
                themeColor: this.getStepColor(this.currentData.steps),
                pageName: 'pages/HomeTo/StepsPage',
                icon: $r('app.media.steps')
              })
              .layoutWeight(1)

              HealthItemComponent({
                title: '睡眠时长',
                value: this.todaySleep ? `${(this.todaySleep.totalMinutes / 60).toFixed(1)}` : '0.0',
                unit: '小时',
                themeColor: this.getSleepColor(this.todaySleep ? this.todaySleep.totalMinutes / 60 : 0),
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
              themeColor: '#5C7CFF',
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

            // 底部留白，防止被导航栏遮挡
            Blank().height(100)
          }
          .padding({ left: 20, right: 20, top: 10 })
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')

      // 3. 底部导航栏 (修复：添加回此处)
      myNavigator()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

