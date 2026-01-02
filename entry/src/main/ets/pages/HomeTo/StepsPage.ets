// StepsPage.ets
import { BackButton } from '../../common/components/BackButton'
import { HealthDB } from '../../database/HealthDB';
import { HealthData } from '../../common/model/HealthData';
import { AuthUtil } from '../../common/utils/AuthUtil';
import { Context } from '@kit.AbilityKit';

@Component
struct StatCard {
  @Prop title: string = '';
  @Prop value: string = '';
  @Prop unit: string = '';
  @Prop color: string = '';

  build() {
    Column() {
      Row() {
        Circle({ width: 8, height: 8 })
          .fill(this.color)
          .margin({ right: 6 })
        Text(this.title)
          .fontSize(12)
          .fontColor('#666')
      }
      .width('100%')
      .margin({ bottom: 8 })

      Row() {
        Text(this.value)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
        Text(` ${this.unit}`)
          .fontSize(12)
          .fontColor('#999')
          .margin({ bottom: 4 })
      }
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .height(80)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.03)', offsetY: 4 })
  }
}

@Entry
@Component
struct StepsPage {
  @State stepsData: HealthData[] = [];

  // [修改 1] 使用 @StorageProp 接收全局步数
  // 如果 AppStorage 里没值，默认 0。一旦 HomePage 更新，这里自动变。
  @StorageProp('globalStepCount') realTimeSteps: number = 0;

  @State maxSteps: number = 1;
  @State minSteps: number = 0;
  @State avgSteps: number = 0;
  @State totalSteps: number = 0;
  @State avgCalories: number = 0;
  @State totalDistance: string = '0.0';

  private async refreshData() {
    const context = this.getUIContext().getHostContext() as Context;
    const user = await AuthUtil.getLoginUser(context);
    if (!user) return;

    await HealthDB.getInstance().initMockHealthData(user.id, 7);
    this.stepsData = await HealthDB.getInstance().getDailyStepsSummary(user.id, 7);

    if (this.stepsData.length > 0) {
      // [修改 2] 强制更新图表数组中“今天”的数据，使其与传感器一致
      // 防止图表显示 110，而大数字显示 5000 的情况
      const todayStr = new Date().toISOString().split('T')[0];
      const todayIndex = this.stepsData.findIndex(item => {
        const d = new Date(item.timestamp);
        return d.toISOString().split('T')[0] === todayStr;
      });

      // 如果全局步数大于数据库记录的步数，优先使用全局步数（传感器数据）
      if (todayIndex !== -1 && this.realTimeSteps > this.stepsData[todayIndex].steps) {
        this.stepsData[todayIndex].steps = this.realTimeSteps;
      }

      // 重新计算统计数据
      this.maxSteps = Math.max(...this.stepsData.map(d => d.steps));
      this.minSteps = Math.min(...this.stepsData.map(d => d.steps));

      this.totalSteps = this.stepsData.reduce((sum, item) => sum + item.steps, 0);
      this.avgSteps = Math.round(this.totalSteps / this.stepsData.length);

      const totalCalories = this.stepsData.reduce((sum, item) => sum + (item.calories || 0), 0);
      this.avgCalories = Math.round(totalCalories / this.stepsData.length);

      const dist = (this.totalSteps * 0.7 / 1000);
      this.totalDistance = isNaN(dist) ? '0.0' : dist.toFixed(1);

      if (this.maxSteps === this.minSteps) {
        this.minSteps = Math.max(0, this.maxSteps - 100);
      }
    }
  }

  async aboutToAppear() {
    await this.refreshData();
  }

  // [修改 3] 监听 realTimeSteps 的变化，一旦变化立即刷新图表数据
  // 这样你在步数页挂着的时候，图表也会跟着动
  @Watch('onStepsChange')
  @StorageProp('globalStepCount')
  watchSteps: number = 0;

  onStepsChange() {
    this.refreshData();
  }

  onPageShow() {
    this.refreshData();
  }

  getBarHeight(val: number): number {
    const minHeight = 20;
    const maxHeight = 150;
    if (this.maxSteps === this.minSteps) return minHeight;
    let percentage = (val - this.minSteps) / (this.maxSteps - this.minSteps);
    return minHeight + percentage * (maxHeight - minHeight);
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        // 1. 顶部 Hero Card
        Column() {
          Stack({ alignContent: Alignment.Center }) {
            Text('步数趋势')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')

            Row() {
              BackButton()
            }
            .width('100%')
            .justifyContent(FlexAlign.Start)
            .padding({ left: 16 })
          }
          .width('100%')
          .height(56)
          .margin({ top: 10 })

          Row() {
            Column() {
              Text('今日步数')
                .fontSize(14)
                .fontColor('rgba(255,255,255,0.9)')

              // [修改 4] 这里直接显示实时步数，如果实时步数为0（还没传过来），兜底显示 DB 数据
              Text(`${this.realTimeSteps > 0 ? this.realTimeSteps : (this.stepsData.length > 0 ? this.stepsData[this.stepsData.length-1].steps : 0)}`)
                .fontSize(40)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)

            Blank()

            Column() {
              Text('总计步数')
                .fontSize(14)
                .fontColor('rgba(255,255,255,0.9)')
              Text(`${this.totalSteps}`)
                .fontSize(24)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFFFFF')
                .margin({ top: 12 })
            }
            .alignItems(HorizontalAlign.End)
          }
          .width('100%')
          .padding({ left: 24, right: 24, bottom: 36 })
        }
        .width('100%')
        .linearGradient({
          angle: 135,
          colors: [['#FF7E5F', 0.0], ['#FEB47B', 1.0]]
        })
        .borderRadius({ bottomLeft: 32, bottomRight: 32 })
        .shadow({ radius: 20, color: 'rgba(255, 126, 95, 0.3)', offsetY: 10 })

        // 2. 图表区域
        Column() {
          Text('近期活动记录')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
            .width('100%')
            .padding({ left: 24, top: 24, bottom: 10 })

          if (this.stepsData.length > 0) {
            List({ space: 14 }) {
              ForEach(this.stepsData, (item: HealthData) => {
                ListItem() {
                  Column() {
                    Stack({ alignContent: Alignment.Bottom }) {
                      Column()
                        .width(8)
                        .height(150)
                        .backgroundColor('#F0F0F0')
                        .borderRadius(4)

                      Column()
                        .width(8)
                        .height(this.getBarHeight(item.steps))
                        .linearGradient({
                          angle: 180,
                          colors: item.steps >= this.avgSteps
                            ? [['#FF7E5F', 0.0], ['#FEB47B', 1.0]]
                            : [['#BDC3C7', 0.0], ['#E0E0E0', 1.0]]
                        })
                        .borderRadius(4)
                        .shadow({ radius: 4, color: 'rgba(255, 126, 95, 0.2)', offsetY: 2 })
                    }

                    Text(`${item.steps}`)
                      .fontSize(10)
                      .fontColor('#999')
                      .margin({ top: 8 })

                    Text(`${(new Date(item.timestamp).getMonth() + 1).toString().padStart(2, '0')}-${new Date(item.timestamp).getDate().toString().padStart(2, '0')}`)
                      .fontSize(10)
                      .fontColor('#CCC')
                      .margin({ top: 2 })
                  }
                  .justifyContent(FlexAlign.End)
                  .height(220)
                }
              })
            }
            .listDirection(Axis.Horizontal)
            .height(260)
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 16 })
            .alignListItem(ListItemAlign.End)
          } else {
            Column() {
              Image($r('app.media.startIcon')).width(60).height(60).opacity(0.1).grayscale(1)
              Text('暂无数据').fontSize(14).fontColor('#CCC').margin({ top: 10 })
            }
            .height(200)
            .justifyContent(FlexAlign.Center)
          }
        }
        .width('92%')
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
        .shadow({ radius: 30, color: 'rgba(0,0,0,0.06)', offsetY: 12 })
        .margin({ top: -24 })

        // 3. 底部数据概览
        Column() {
          Text('数据概览')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
            .width('100%')
            .margin({ bottom: 12 })

          Grid() {
            GridItem() {
              StatCard({ title: '平均热量', value: `${this.avgCalories}`, unit: 'kcal', color: '#FF7E5F' })
            }
            GridItem() {
              StatCard({ title: '总里程', value: this.totalDistance, unit: 'km', color: '#FEB47B' })
            }
            GridItem() {
              StatCard({ title: '达标天数', value: `${this.stepsData.filter(d => d.steps >= 5000).length}`, unit: '天', color: '#FF9966' })
            }
            GridItem() {
              StatCard({ title: '活跃时长', value: `${Math.round(this.totalSteps / 100)}`, unit: 'min', color: '#FFCC80' })
            }
          }
          .columnsTemplate('1fr 1fr')
          .rowsGap(12)
          .columnsGap(12)
          .height(200)
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 24 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F8F9FB')
    }
  }
}