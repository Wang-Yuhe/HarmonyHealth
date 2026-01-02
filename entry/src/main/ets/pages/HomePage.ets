/**
 * @file HomePage.ets
 * @description 应用主界面（已集成传感器实时监听）
 */
import { myNavigator } from '../common/components/Navigator';
import { HealthVM } from '../features/healthStatus/viewmodel/HealthVM';
import { HealthData } from '../common/model/HealthData';
import { SleepData } from '../common/model/SleepData';
import { HealthDB } from '../database/HealthDB';
import { AuthUtil } from '../common/utils/AuthUtil';
import { image } from '@kit.ImageKit';
import sensor from '@ohos.sensor'; // 引入传感器模块
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@kit.BasicServicesKit';

// --- 全局配色常量 ---
const COLOR_BG_BASE = '#FFFFFF';
const COLOR_PRIMARY = '#4A90E2';
const COLOR_ACCENT = '#FF6B6B';
const CARD_BG_GRADIENT_START = 'rgba(255, 255, 255, 0.85)';
const CARD_BG_GRADIENT_END = 'rgba(255, 255, 255, 0.4)';

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
      Circle({ width: 80, height: 80 })
        .fill('transparent')
        .stroke(this.themeColor)
        .strokeWidth(12)
        .opacity(0.08)
        .margin({ top: -20, right: -20 })
        .blur(15)

      Column() {
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
            .fontColor('#555')
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 12 })

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
      .linearGradient({
        angle: 135,
        colors: [[CARD_BG_GRADIENT_START, 0.0], [CARD_BG_GRADIENT_END, 1.0]]
      })
      .backdropBlur(40)
      .border({
        width: 1.5,
        color: this.themeColor.startsWith('#') ? ('#66' + this.themeColor.substring(1)) : this.themeColor
      })
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
  @State todaySteps: number = 0; // 这个变量将由传感器驱动

  @StorageProp('avatar') @Watch('onAvatarChange') currentUserAvatar: string | Resource = $r('app.media.profileIcon');
  @State displayAvatar: string | Resource | image.PixelMap = $r('app.media.profileIcon');

  private healthVM: HealthVM = new HealthVM();

  // --- 传感器监听逻辑 Start ---

  /**
   * 启动步数传感器监听
   * 注意：模拟器的 Pedometer 数据会直接触发此回调
   */
  private startStepSensor() {
    try {
      // 订阅 SensorId.PEDOMETER
      sensor.on(sensor.SensorId.PEDOMETER, (data) => {
        // data.steps 是累计步数
        console.info(`[HomePage] Sensor Callback Triggered! Raw Steps: ${data.steps}`);

        // 强制刷新 UI (ArkTS 有时对数值变化不敏感，加个 Math.floor 确保是整数)
        this.todaySteps = Math.floor(data.steps);
        AppStorage.setOrCreate('globalStepCount', this.todaySteps);
      }, { interval: 100000000 }); // 0.1秒采样

      console.info('[HomePage] sensor.on executed successfully');
    } catch (err) {
      console.error('[HomePage] Failed to start sensor (Try-Catch):', JSON.stringify(err));
    }
  }

  /**
   * 停止传感器监听
   */
  private stopStepSensor() {
    try {
      sensor.off(sensor.SensorId.PEDOMETER);
    } catch (err) {
      console.error('[HomePage] Failed to stop sensor:', JSON.stringify(err));
    }
  }

  // --- 传感器监听逻辑 End ---

  async aboutToAppear() {
    const context = this.getUIContext().getHostContext() as Context;

    // 1. 加载基本数据
    const lastData = await this.healthVM.loadLastData(context);
    if (lastData) this.currentData = lastData;
    await this.loadTodaySteps(); // 加载数据库里的旧数据作为兜底
    await this.loadSleepData();
    this.loadAvatar();

    // 2. [关键] 动态申请权限，成功后再启动传感器
    this.reqPermissionsAndStartSensor();
  }

  // [新增] 动态权限申请函数
  private reqPermissionsAndStartSensor() {
    let atManager = abilityAccessCtrl.createAtManager();
    let context = getContext(this) as common.UIAbilityContext;

    try {
      // 申请 ACTIVITY_MOTION 权限
      atManager.requestPermissionsFromUser(context, ['ohos.permission.ACTIVITY_MOTION'])
        .then((data) => {
          // data.authResults[0] === 0 表示用户点击了“允许”
          if (data.authResults.length > 0 && data.authResults[0] === 0) {
            console.info('[HomePage] Permission granted, starting sensor...');
            this.startStepSensor();
          } else {
            console.error('[HomePage] User denied permission');
            // 可以弹窗提示用户去设置里开启
          }
        })
        .catch((err: Object) => {
          console.error(`[HomePage] Request permission failed: ${JSON.stringify(err)}`);
        })
    } catch (err) {
      console.error(`[HomePage] Auth catch err: ${JSON.stringify(err)}`);
    }
  }

  // 页面销毁时务必关闭传感器
  aboutToDisappear() {
    this.healthVM.stopMonitoring();
    this.stopStepSensor();
  }

  onAvatarChange() {
    this.loadAvatar();
  }

  private async loadAvatar() {
    if (typeof this.currentUserAvatar !== 'string' || !this.currentUserAvatar.startsWith('file://')) {
      this.displayAvatar = this.currentUserAvatar;
      return;
    }
    try {
      const imageSource = image.createImageSource(this.currentUserAvatar);
      const pixelMap = await imageSource.createPixelMap();
      this.displayAvatar = pixelMap;
    } catch (e) {
      console.error('Load avatar failed:', e);
      this.displayAvatar = this.currentUserAvatar;
    }
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
    // 只有在传感器未启动前，这个值才会短暂显示，随后会被 sensor.on 的回调覆盖
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
      // 注意：这里不再调用 loadTodaySteps，以免覆盖掉传感器的实时数据
      // await this.loadTodaySteps();
    });
    this.loadSleepData();
    this.loadAvatar();

    // 页面重新显示时，确保传感器是开启的
    this.startStepSensor();
  }

  onPageHide() {
    this.healthVM.stopMonitoring();
    // 页面隐藏时可以暂停传感器以省电
    this.stopStepSensor();
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      this.BackgroundDecorations()

      Column() {
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

          Image(this.displayAvatar || $r('app.media.profileIcon'))
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
            Stack({ alignContent: Alignment.TopStart }) {
              Circle({ width: 140, height: 140 })
                .fill('#5C7CFF')
                .opacity(0.1)
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

            Row({ space: 14 }) {
              HealthItemComponent({
                title: '今日步数',
                value: `${this.todaySteps}`, // 这里绑定了 state，会自动更新
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

            HealthItemComponent({
              title: '实时健康监测',
              value: `${this.currentData.heartRate} bpm  |  ${this.currentData.bloodOxygen}%`,
              unit: '心率 / 血氧',
              themeColor: '#00C853',
              pageName: 'features/healthStatus/view/StatusPage',
              icon: $r('app.media.instantcheck')
            })

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

      myNavigator()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLOR_BG_BASE)
  }

  @Builder
  BackgroundDecorations(): void {
    Stack() {
      Circle({ width: 320, height: 320 })
        .fill('rgba(74, 144, 226, 0.35)')
        .position({ x: -80, y: -100 })
        .blur(80)

      Circle({ width: 280, height: 280 })
        .fill('rgba(108, 92, 231, 0.35)')
        .position({ x: '60%', y: 150 })
        .blur(70)

      Circle({ width: 300, height: 300 })
        .fill('rgba(255, 107, 107, 0.25)')
        .position({ x: -100, y: 400 })
        .blur(90)

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