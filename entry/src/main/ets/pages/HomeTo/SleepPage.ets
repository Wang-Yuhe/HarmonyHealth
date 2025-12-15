import { BackButton } from '../../common/components/BackButton'
import { HealthDB } from '../../database/HealthDB';
import { SleepData } from '../../common/model/SleepData';

@Entry
@Component
struct SleepPage {
  @State sleepData: SleepData[] = [];
  @State maxDuration: number = 600; // Default max 10 hours (600 mins) for scaling
  @State avgSleepTime: string = '0.0';
  @State deepSleepRatio: string = '0%';

  async aboutToAppear() {
    this.sleepData = await HealthDB.getInstance().getRecentSleepData(7);
    
    if (this.sleepData.length > 0) {
      // Calculate max duration for dynamic scaling
      const max = Math.max(...this.sleepData.map(d => d.totalMinutes));
      if (max > 0) {
        this.maxDuration = max * 1.1; // Add 10% buffer
      }

      // 计算平均睡眠时长
      const totalMins = this.sleepData.reduce((sum, d) => sum + d.totalMinutes, 0);
      this.avgSleepTime = (totalMins / this.sleepData.length / 60).toFixed(1);

      // 计算平均深睡占比
      const totalDeep = this.sleepData.reduce((sum, d) => sum + d.deepSleepMinutes, 0);
      if (totalMins > 0) {
        this.deepSleepRatio = Math.round((totalDeep / totalMins) * 100) + '%';
      }
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 1. 背景层
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [['#E3F2FD', 0.0], ['#FFFFFF', 0.5]] // 浅蓝色渐变
        })

      Column() {
        // 标题栏占位
        Row() {
          Text('睡眠分析')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .height(56)
        .margin({ top: 10 })

        // 2. 统计概览卡片
        Row() {
          Column() {
            Text('平均睡眠')
              .fontSize(14)
              .fontColor('#666')
            Row() {
              Text(this.avgSleepTime)
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1976D2')
              Text(' 小时')
                .fontSize(14)
                .fontColor('#1976D2')
                .margin({ bottom: 4 })
            }
            .alignItems(VerticalAlign.Bottom)
            .margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          Divider().vertical(true).height(30).color('#EEE')

          Column() {
            Text('深睡占比')
              .fontSize(14)
              .fontColor('#666')
            Text(this.deepSleepRatio)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333')
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }
        .width('90%')
        .padding(20)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .shadow({ radius: 10, color: 'rgba(25, 118, 210, 0.15)', offsetY: 4 })
        .margin({ top: 20, bottom: 20 })

        // 3. 图表区域
        if (this.sleepData.length > 0) {
          Column() {
            Row() {
              Text('近7天睡眠结构')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
              Blank()
              // Legend
              Row({ space: 8 }) {
                this.LegendItem('#1976D2', '深睡')
                this.LegendItem('#64B5F6', '浅睡')
                this.LegendItem('#FFB74D', '清醒')
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16 })

            List({ space: 15 }) {
              ForEach(this.sleepData, (item: SleepData) => {
                ListItem() {
                  Column() {
                    // Stacked Bar Chart
                    Column() {
                      // Awake
                      if (item.awakeMinutes > 0) {
                        Column()
                          .width(16)
                          .height(this.getHeight(item.awakeMinutes))
                          .backgroundColor('#FFB74D') // Orange for awake
                          .borderRadius({ topLeft: 8, topRight: 8 })
                      }
                      // Light Sleep
                      if (item.lightSleepMinutes > 0) {
                        Column()
                          .width(16)
                          .height(this.getHeight(item.lightSleepMinutes))
                          .backgroundColor('#64B5F6') // Light Blue
                          .borderRadius(item.awakeMinutes === 0 ? { topLeft: 8, topRight: 8 } : { topLeft: 0, topRight: 0 })
                      }
                      // Deep Sleep
                      if (item.deepSleepMinutes > 0) {
                        Column()
                          .width(16)
                          .height(this.getHeight(item.deepSleepMinutes))
                          .backgroundColor('#1976D2') // Dark Blue
                          .borderRadius({ 
                            topLeft: (item.awakeMinutes === 0 && item.lightSleepMinutes === 0) ? 8 : 0, 
                            topRight: (item.awakeMinutes === 0 && item.lightSleepMinutes === 0) ? 8 : 0,
                            bottomLeft: 8,
                            bottomRight: 8
                          })
                      }
                    }
                    .justifyContent(FlexAlign.End)
                    .alignItems(HorizontalAlign.Center)
                    
                    // Total Hours Label
                    Text(`${(item.totalMinutes / 60).toFixed(1)}h`)
                      .fontSize(10)
                      .fontColor('#666')
                      .margin({ top: 6 })
                    
                    // Date Label
                    Text(item.date.substring(5)) // MM-DD
                      .fontSize(10)
                      .fontColor('#999')
                      .margin({ top: 2 })
                  }
                  .justifyContent(FlexAlign.End)
                  .height(240)
                }
              })
            }
            .listDirection(Axis.Horizontal)
            .height(280)
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 16 })
            .alignListItem(ListItemAlign.Center)
          }
          .width('90%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: 4 })

        } else {
          Column() {
            Image($r('app.media.startIcon')) // 替换为暂无数据图
              .width(100)
              .height(100)
              .opacity(0.3)
              .grayscale(1)
            Text('暂无睡眠数据')
              .fontSize(16)
              .fontColor('#999')
              .margin({ top: 16 })
          }
          .width('100%')
          .height(300)
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .height('100%')

      BackButton()
        .margin({ top: 10, left: 10 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }

  @Builder
  LegendItem(color: string, label: string) {
    Row() {
      Circle({ width: 8, height: 8 })
        .fill(color)
        .margin({ right: 4 })
      Text(label)
        .fontSize(10)
        .fontColor('#666')
    }
  }

  getHeight(minutes: number): number {
    // Max height for the bar area is around 180vp (reduced to fit card)
    const maxHeight = 180;
    return (minutes / this.maxDuration) * maxHeight;
  }
}