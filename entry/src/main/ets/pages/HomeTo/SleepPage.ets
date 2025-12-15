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
      const max = Math.max(...this.sleepData.map(d => d.totalMinutes));
      if (max > 0) this.maxDuration = max * 1.1;
      const totalMins = this.sleepData.reduce((sum, d) => sum + d.totalMinutes, 0);
      this.avgSleepTime = (totalMins / this.sleepData.length / 60).toFixed(1);
      const totalDeep = this.sleepData.reduce((sum, d) => sum + d.deepSleepMinutes, 0);
      if (totalMins > 0) {
        this.deepSleepRatio = Math.round((totalDeep / totalMins) * 100) + '%';
      }
    }
  }

  getHeight(minutes: number): number {
    const maxHeight = 160;
    return (minutes / this.maxDuration) * maxHeight;
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        // 1. 顶部 Hero Card (深蓝夜空渐变)
        Column() {
          // 使用 Stack 将 BackButton 整合进标题栏，防止遮挡
          Stack({ alignContent: Alignment.Center }) {
            Text('睡眠分析')
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
              Text('平均睡眠')
                .fontSize(14)
                .fontColor('rgba(255,255,255,0.7)')
              Row() {
                Text(this.avgSleepTime)
                  .fontSize(36)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                Text(' h')
                  .fontSize(18)
                  .fontColor('rgba(255,255,255,0.9)')
                  .margin({ bottom: 6 })
              }
              .alignItems(VerticalAlign.Bottom)
              .margin({ top: 8 })
            }
            .alignItems(HorizontalAlign.Start)
            
            Blank()

            Column() {
              Text('深睡占比')
                .fontSize(14)
                .fontColor('rgba(255,255,255,0.7)')
              Text(this.deepSleepRatio)
                .fontSize(24)
                .fontWeight(FontWeight.Medium)
                .fontColor('#81D4FA') // 亮蓝色高亮
                .margin({ top: 12 })
            }
            .alignItems(HorizontalAlign.End)
          }
          .width('100%')
          .padding({ left: 24, right: 24, bottom: 30 })
        }
        .width('100%')
        .linearGradient({
          angle: 180,
          colors: [['#1A237E', 0.0], ['#3949AB', 1.0]] // 深蓝渐变
        })
        .borderRadius({ bottomLeft: 30, bottomRight: 30 })
        .shadow({ radius: 20, color: 'rgba(26, 35, 126, 0.4)', offsetY: 10 })

        // 2. 图表区域
        Column() {
          Row() {
            Text('睡眠结构')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333')
            Blank()
            Row({ space: 8 }) {
              this.LegendItem('#304FFE', '深睡')
              this.LegendItem('#8C9EFF', '浅睡')
              this.LegendItem('#FFAB91', '清醒')
            }
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 20 })

          if (this.sleepData.length > 0) {
            List({ space: 15 }) {
              ForEach(this.sleepData, (item: SleepData) => {
                ListItem() {
                  Column() {
                    // 堆叠柱状图
                    Column() {
                      if (item.awakeMinutes > 0) {
                        Column().width(12).height(this.getHeight(item.awakeMinutes))
                          .backgroundColor('#FFAB91').borderRadius({ topLeft: 6, topRight: 6 })
                      }
                      if (item.lightSleepMinutes > 0) {
                        Column().width(12).height(this.getHeight(item.lightSleepMinutes))
                          .backgroundColor('#8C9EFF')
                          .borderRadius(item.awakeMinutes === 0 ? { topLeft: 6, topRight: 6 } : 0)
                      }
                      if (item.deepSleepMinutes > 0) {
                        Column().width(12).height(this.getHeight(item.deepSleepMinutes))
                          .backgroundColor('#304FFE')
                          .borderRadius({ 
                            topLeft: (item.awakeMinutes === 0 && item.lightSleepMinutes === 0) ? 6 : 0, 
                            topRight: (item.awakeMinutes === 0 && item.lightSleepMinutes === 0) ? 6 : 0,
                            bottomLeft: 6, bottomRight: 6 
                          })
                      }
                    }
                    .justifyContent(FlexAlign.End)
                    
                    Text(item.date.substring(5))
                      .fontSize(10)
                      .fontColor('#999')
                      .margin({ top: 8 })
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
            .alignListItem(ListItemAlign.Center)
          } else {
            Column() {
              Image($r('app.media.startIcon'))
                .width(80).height(80).opacity(0.2).grayscale(1)
              Text('暂无数据').fontSize(14).fontColor('#CCC').margin({ top: 10 })
            }
            .height(200)
            .justifyContent(FlexAlign.Center)
          }
        }
        .width('90%')
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
        .shadow({ radius: 30, color: 'rgba(0,0,0,0.05)', offsetY: 10 })
        .margin({ top: -20 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F7FA')
    }
  }

  @Builder
  LegendItem(color: string, label: string) {
    Row() {
      Circle({ width: 8, height: 8 }).fill(color).margin({ right: 4 })
      Text(label).fontSize(10).fontColor('#666')
    }
  }
}