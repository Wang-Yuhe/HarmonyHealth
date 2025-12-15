import { BackButton } from '../../common/components/BackButton'
import { HealthDB } from '../../database/HealthDB';
import { SleepData } from '../../common/model/SleepData';

@Entry
@Component
struct SleepPage {
  @State sleepData: SleepData[] = [];
  @State maxDuration: number = 600; // Default max 10 hours (600 mins) for scaling

  async aboutToAppear() {
    this.sleepData = await HealthDB.getInstance().getRecentSleepData(7);
    // Calculate max duration for dynamic scaling
    const max = Math.max(...this.sleepData.map(d => d.totalMinutes));
    if (max > 0) {
      this.maxDuration = max * 1.1; // Add 10% buffer
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        Text('睡眠质量趋势 (近7天)')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 20 })
          .alignSelf(ItemAlign.Center)

        if (this.sleepData.length > 0) {
          List({ space: 15 }) {
            ForEach(this.sleepData, (item: SleepData) => {
              ListItem() {
                Column() {
                  // Stacked Bar Chart
                  Column() {
                    // Awake
                    if (item.awakeMinutes > 0) {
                      Column()
                        .width(20)
                        .height(this.getHeight(item.awakeMinutes))
                        .backgroundColor('#FFB74D') // Orange for awake
                        .borderRadius({ topLeft: 4, topRight: 4 })
                    }
                    // Light Sleep
                    if (item.lightSleepMinutes > 0) {
                      Column()
                        .width(20)
                        .height(this.getHeight(item.lightSleepMinutes))
                        .backgroundColor('#64B5F6') // Light Blue
                        .borderRadius(item.awakeMinutes === 0 ? { topLeft: 4, topRight: 4 } : { topLeft: 0, topRight: 0 })
                    }
                    // Deep Sleep
                    if (item.deepSleepMinutes > 0) {
                      Column()
                        .width(20)
                        .height(this.getHeight(item.deepSleepMinutes))
                        .backgroundColor('#1976D2') // Dark Blue
                        .borderRadius(item.awakeMinutes === 0 && item.lightSleepMinutes === 0 ? { topLeft: 4, topRight: 4 } : { topLeft: 0, topRight: 0 })
                    }
                  }
                  .justifyContent(FlexAlign.End)
                  .alignItems(HorizontalAlign.Center)
                  
                  // Total Hours Label
                  Text(`${(item.totalMinutes / 60).toFixed(1)}h`)
                    .fontSize(10)
                    .fontColor('#666')
                    .margin({ top: 4 })
                  
                  // Date Label
                  Text(item.date.substring(5)) // MM-DD
                    .fontSize(10)
                    .fontColor('#999')
                }
                .justifyContent(FlexAlign.End)
                .height(250)
              }
            })
          }
          .listDirection(Axis.Horizontal)
          .height(300)
          .width('100%')
          .padding(16)
          .alignListItem(ListItemAlign.Center)

          // Legend
          Row() {
            this.LegendItem('#1976D2', '深睡')
            this.LegendItem('#64B5F6', '浅睡')
            this.LegendItem('#FFB74D', '清醒')
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 10 })

        } else {
          Text('暂无睡眠数据')
            .fontSize(16)
            .fontColor('#999')
            .margin({ top: 100 })
        }
      }
      .width('100%')
      .height('100%')
      .padding({ top: 60 })

      BackButton()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  LegendItem(color: string, label: string) {
    Row() {
      Circle({ width: 10, height: 10 })
        .fill(color)
        .margin({ right: 5 })
      Text(label)
        .fontSize(12)
        .fontColor('#666')
    }
    .margin({ left: 10, right: 10 })
  }

  getHeight(minutes: number): number {
    // Max height for the bar area is around 200vp
    const maxHeight = 200;
    return (minutes / this.maxDuration) * maxHeight;
  }
}