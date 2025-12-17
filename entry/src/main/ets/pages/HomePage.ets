/**
 * @file HomePage.ets
 * @description 应用主界面（UI 优化版 - 修复玻璃拟态边框颜色格式 #AARRGGBB）
 */
import { myNavigator } from '../common/components/Navigator';
import { HealthVM } from '../features/healthStatus/viewmodel/HealthVM';
import { HealthData } from '../common/model/HealthData';
import { SleepData } from '../common/model/SleepData';
import { HealthDB } from '../database/HealthDB';
import { AuthUtil } from '../common/utils/AuthUtil';

@Component
struct HealthItemComponent {
  @Prop title: string = '';
  @Prop value: string = '';
  @Prop unit: string = '';
  @Prop themeColor: string = '';
  @Prop pageName: string = '';
  @Prop icon: ResourceStr = $r('app.media.startIcon');

  build() {
    // 使用 Stack 增加内部装饰层，营造科技层次感
    Stack({ alignContent: Alignment.TopEnd }) {
      // 1. 装饰背景：右上角的半透明大圆环
      Circle({ width: 80, height: 80 })
        .fill('transparent')
        .stroke(this.themeColor)
        .strokeWidth(12)
        .opacity(0.05) // 极淡的装饰
        .margin({ top: -20, right: -20 })
        .blur(10) // 模糊处理，融入背景

      // 2. 主要内容
      Column() {
        // 头部：图标 + 标题
        Row() {
          Stack({ alignContent: Alignment.Center }) {
            // 图标底色光晕
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
            .fontColor('#666')
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 12 })

        // 数值显示
        Row() {
          Text(this.value)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2C3E50') // 深蓝灰，比纯黑更有质感
          
          if (this.unit) {
            Text(this.unit)
              .fontSize(11)
              .fontColor('#999')
              .margin({ left: 4, bottom: 4 })
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Bottom)
      }
      .padding(18)
      .width('100%')
      .borderRadius(24)
      // 优化：调整渐变透明度，模拟强光照射下的玻璃反光
      .linearGradient({
        angle: 135,
        colors: [['rgba(255, 255, 255, 0.8)', 0.0], ['rgba(255, 255, 255, 0.2)', 1.0]]
      })
      // 优化：增加模糊度，增强磨砂质感
      .backdropBlur(70)
      
      // 优化：边框透明度调整为 50% (#80)，保持色彩同时增加通透感
      .border({ 
        width: 2.0,
        color: this.themeColor.startsWith('#') ? ('#80' + this.themeColor.substring(1)) : this.themeColor 
      }) 
      // 优化：大幅增加阴影半径和偏移，增强立体悬浮感 (25% 透明度)
      .shadow({ 
        radius: 65,
        color: this.themeColor.startsWith('#') ? ('#50' + this.themeColor.substring(1)) : '#40000000',
        offsetY: 50
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
  private healthVM: HealthVM = new HealthVM();

  private STEP_GOAL: number = 5000;
  private SLEEP_GOAL: number = 8;

  private getStepColor(steps: number): string {
    return steps >= this.STEP_GOAL ? '#00C853' : '#FF7043'; 
  }

  private getSleepColor(hours: number): string {
    return hours >= this.SLEEP_GOAL ? '#448AFF' : '#FFCA28';
  }

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

  private executeLogoutAction(): void {
    AppStorage.SetOrCreate('isLogin', false);
    this.getUIContext().getRouter().replaceUrl({ url: 'pages/LoginPage' })
  }

  async aboutToAppear() {
    const context = this.getUIContext().getHostContext() as Context;
    const lastData = await this.healthVM.loadLastData(context);
    if (lastData) this.currentData = lastData;
    await this.loadSleepData();
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
    this.healthVM.startMonitoring(context, 3000, (data: HealthData) => { this.currentData = data; });
    this.loadSleepData();
  }

  onPageHide() { this.healthVM.stopMonitoring(); }
  aboutToDisappear() { this.healthVM.stopMonitoring(); }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 1. 背景层 (科技感光影氛围)
      Stack() {
        // 基础底色 - 极淡的冷灰蓝
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#F2F5F9') 

        // 装饰光球 1 (左上 - 科技蓝)
        Circle({ width: 280, height: 280 })
          .fill('#4A90E2')
          .opacity(0.08)
          .position({ x: -80, y: -80 })
          .blur(60)

        // 装饰光球 2 (右中 - 活力紫)
        Circle({ width: 220, height: 220 })
          .fill('#9B59B6')
          .opacity(0.06)
          .position({ x: '70%', y: '25%' })
          .blur(50)
          
        // 装饰光球 3 (左下 - 清新绿)
        Circle({ width: 260, height: 260 })
          .fill('#2ECC71')
          .opacity(0.05)
          .position({ x: -60, y: '65%' })
          .blur(70)
      }
      .width('100%')
      .height('100%')
      .zIndex(0)

      // 2. 主内容区域
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
              .fontColor('#8899A6') // 更高级的灰色
              .margin({ top: 4 })
              .letterSpacing(1)
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          // 退出按钮 - 悬浮玻璃质感
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            Image($r('app.media.logout'))
              .width(20)
              .height(20)
              .fillColor('#5C7CFF') 
          }
          .width(42)
          .height(42)
          .backgroundColor('rgba(255,255,255,0.8)')
          .backdropBlur(10)
          .shadow({ radius: 10, color: 'rgba(92, 124, 255, 0.2)', offsetY: 4 }) 
          .onClick(() => { this.handleLogout() })
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 20, bottom: 10 })

        Scroll() {
          Column({ space: 16 }) { 
            // 人体模型卡片 - Hero Card (特殊样式)
            Stack({ alignContent: Alignment.TopStart }) {
              // 背景装饰
              Circle({ width: 140, height: 140 })
                .fill('#5C7CFF')
                .opacity(0.06)
                .position({ x: '60%', y: -30 })
                .blur(20)

              Column() {
                Image($r('app.media.body2'))
                  .height(170)
                  .objectFit(ImageFit.Contain)
                  .margin({ bottom: 16 })
                  // 图片增加投影，产生悬浮感
                  .shadow({ radius: 15, color: 'rgba(0,0,0,0.1)', offsetY: 8 })

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

                  // 按钮 - 渐变胶囊
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
                  .shadow({ radius: 8, color: 'rgba(92, 124, 255, 0.3)', offsetY: 3 })
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
            // 优化：Hero 卡片增强玻璃质感和反光
            .linearGradient({
              angle: 135,
              colors: [['rgba(255, 255, 255, 0.85)', 0.0], ['rgba(244, 247, 255, 0.25)', 1.0]]
            })
            .backdropBlur(40)
            // 优化：身体健康档案边框颜色为蓝色 (#5C7CFF) + 50% 透明度
            .border({ width: 1.5, color: '#805C7CFF' }) 
            .shadow({ radius: 35, color: 'rgba(92, 124, 255, 0.3)', offsetY: 15 }) 
            .onClick(() => {
              this.getUIContext().getRouter().pushUrl({ url: 'pages/HomeTo/BodyInfoPage' })
            })

            // 双列布局
            Row({ space: 14 }) {
              HealthItemComponent({
                title: '今日步数',
                value: `${this.currentData.steps}`,
                unit: '步',
                // 保持：今日步数边框颜色为橙红色 (#FF7043)
                themeColor: '#FF7043',
                pageName: 'pages/HomeTo/StepsPage',
                icon: $r('app.media.steps')
              })
              .layoutWeight(1)

              HealthItemComponent({
                title: '睡眠时长',
                value: this.todaySleep ? `${(this.todaySleep.totalMinutes / 60).toFixed(1)}` : '0.0',
                unit: '小时',
                // 修改：睡眠时长边框颜色为深蓝色 (#2962FF)
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
              // 修改：实时健康监测边框颜色为绿色 (#00C853)
              themeColor: '#00C853',
              pageName: 'features/healthStatus/view/StatusPage',
              icon: $r('app.media.instantcheck')
            })

            // 疾病历史
            HealthItemComponent({
              title: '疾病历史档案',
              value: '查看记录',
              unit: '',
              // 保持：疾病历史记录边框颜色为深紫色 (#7E57C2)
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
      .zIndex(1)

      // 3. 底部导航栏
      myNavigator().zIndex(2)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F5F9') // 保持背景一致
  }
}

