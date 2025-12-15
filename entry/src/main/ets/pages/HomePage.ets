/**
 * @file HomePage.ets
 * @description 应用主界面（包含动态配色）
 * @created 2025-12-03 09:12:10
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
  @Prop bgColor: string = '';
  @Prop pageName: string = '';
  @Prop icon: ResourceStr = $r('app.media.startIcon');

  build() {
    Button() {
      Column() {
        Image(this.icon)
          .width(40)
          .height(40)
          .margin({ bottom: 8 })
          .objectFit(ImageFit.Contain)

        Text(this.title)
          .fontSize(18)
          .fontColor('#333')

        if (this.value) {
          Text(this.value)
            .fontSize(16)
            .fontColor('#333')
            .fontWeight(FontWeight.Bold)
            .margin({ top: 5 })
        }
      }
    }
    .padding(16)
    .borderRadius(16)
    .backgroundColor(this.bgColor)
    .width('100%')
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
  private SLEEP_GOAL: number = 8; // 单位：小时

  //------------------------------
  // 颜色辅助函数（线性插值）
  //------------------------------
  private lerpColor(color1: string, color2: string, t: number): string {
    let c1 = color1.replace('#', '');
    let c2 = color2.replace('#', '');

    let r1 = parseInt(c1.substring(0, 2), 16);
    let g1 = parseInt(c1.substring(2, 4), 16);
    let b1 = parseInt(c1.substring(4, 6), 16);

    let r2 = parseInt(c2.substring(0, 2), 16);
    let g2 = parseInt(c2.substring(2, 4), 16);
    let b2 = parseInt(c2.substring(4, 6), 16);

    let r = Math.floor(r1 + (r2 - r1) * t);
    let g = Math.floor(g1 + (g2 - g1) * t);
    let b = Math.floor(b1 + (b2 - b1) * t);

    return `#${r.toString(16).padStart(2,'0')}${g.toString(16).padStart(2,'0')}${b.toString(16).padStart(2,'0')}`;
  }

  // 步数颜色：红 → 绿
  private getStepColor(steps: number): string {
    let ratio = Math.min(1, Math.max(0, steps / this.STEP_GOAL));
    let fromRed = '#FF8080';    // 柔和红
    let toGreen = '#98FB98';    // 柔和绿
    return this.lerpColor(fromRed, toGreen, ratio);
  }

  // 睡眠颜色：黄 → 蓝
  private getSleepColor(hours: number): string {
    let ratio = Math.min(1, Math.max(0, hours / this.SLEEP_GOAL));
    let fromYellow = '#FFF2A6'; // 柔和黄
    let toBlue = '#A7D8FF';     // 柔和蓝
    return this.lerpColor(fromYellow, toBlue, ratio);
  }

  async aboutToAppear() {
    const lastData = await this.healthVM.loadLastData();
    if (lastData) {
      this.currentData = lastData;
      console.info(`HealthApp data刷新: 心率=${lastData.heartRate}, 时间=${lastData.timestamp}`);
    }
    await this.loadSleepData();
  }

  async loadSleepData() {
    const todayStr = new Date().toISOString().split('T')[0];
    this.todaySleep = await HealthDB.getInstance().getSleepDataByDate(todayStr);
  }

  onPageShow() {
    // 页面显示时（包括从子页面返回），开启监测
    this.healthVM.startMonitoring(3000, (data) => {
      this.currentData = data;
    });
    // 刷新睡眠数据（防止在详情页修改后返回不更新）
    this.loadSleepData();
  }

  onPageHide() {
    // 页面隐藏时（跳转到子页面或后台），停止监测以节省资源
    this.healthVM.stopMonitoring();
  }

  aboutToDisappear() {
    this.healthVM.stopMonitoring();
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Column() {

        //--------------------------
        // 顶部图片区 + 灰色标题
        //--------------------------
        Image($r('app.media.body'))
          .width('55%')
          .margin({ top: 20, bottom: 10 })
          .objectFit(ImageFit.Contain)
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({
              url: 'pages/HomeTo/BodyInfoPage'
            })
          })

        Text('身体数据')
          .fontSize(15)
          .fontColor('#666666')
          .margin({ bottom: 10 })

        Column({ space: 16 }) {

          //--------------------------
          // 第一行：步数 + 睡眠
          //--------------------------
          Row({ space: 16 }) {

            // 步数颜色根据步数动态变化
            HealthItemComponent({
              title: '步数',
              value: `${this.currentData.steps} 步`,
              bgColor: this.getStepColor(this.currentData.steps),
              pageName: 'pages/HomeTo/StepsPage',
              icon: $r('app.media.steps')
            })
              .layoutWeight(1)

            // 睡眠颜色根据时长变化
            HealthItemComponent({
              title: '睡眠质量',
              value: this.todaySleep ? `${(this.todaySleep.totalMinutes / 60).toFixed(1)}h` : '无数据',
              bgColor: this.getSleepColor(this.todaySleep ? this.todaySleep.totalMinutes / 60 : 0),
              pageName: 'pages/HomeTo/SleepPage',
              icon: $r('app.media.sleep')
            })
              .layoutWeight(1)
          }

          //--------------------------
          // 第二行：实时健康状态
          //--------------------------
          HealthItemComponent({
            title: '实时健康状态',
            value: `心率: ${this.currentData.heartRate} | 血氧: ${this.currentData.bloodOxygen}%`,
            bgColor: '#C9F7D1',  // 与风格统一的浅绿色
            pageName: 'features/healthStatus/view/StatusPage',
            icon: $r('app.media.startIcon')
          })
            .width('100%')

          //--------------------------
          // 第三行：疾病历史
          //--------------------------
          HealthItemComponent({
            title: '疾病历史',
            value: '无记录',
            bgColor: '#E5D0F5',  // 柔和紫
            pageName: 'pages/HomeTo/DiseasePage',
            icon: $r('app.media.diseasehistory')
          })
            .width('100%')

        }
        .height('90%')
        .padding(16)
        .width('100%')

        myNavigator()
      }
      .width('100%')
      .height('100%')
    }
    .backgroundColor('#F5F5F5')
  }
}

