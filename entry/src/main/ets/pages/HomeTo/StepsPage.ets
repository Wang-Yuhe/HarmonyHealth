// StepsPage.ets 步数情况页面 (UI 优化版)
import { BackButton } from '../../common/components/BackButton'
import { HealthDB } from '../../database/HealthDB';
import { HealthData } from '../../common/model/HealthData';

@Entry
@Component
struct StepsPage {
  @State stepsData: HealthData[] = [];
  @State maxSteps: number = 1;
  @State minSteps: number = 0;
  @State avgSteps: number = 0;
  @State totalSteps: number = 0;

  async aboutToAppear() {
    // 获取最近 20 条数据用于展示趋势
    this.stepsData = await HealthDB.getInstance().getRecentHealthData(20);
    if (this.stepsData.length > 0) {
      this.maxSteps = Math.max(...this.stepsData.map(d => d.steps));
      this.minSteps = Math.min(...this.stepsData.map(d => d.steps));
      
      // 计算统计数据
      this.totalSteps = this.stepsData.reduce((sum, item) => sum + item.steps, 0);
      this.avgSteps = Math.round(this.totalSteps / this.stepsData.length);

      // 如果最大最小值相等（比如刚开始），手动拉开一点差距防止除以0
      if (this.maxSteps === this.minSteps) {
        this.minSteps = Math.max(0, this.maxSteps - 100);
      }
    }
  }

  // 动态计算高度，放大变化趋势
  getBarHeight(val: number): number {
    const minHeight = 20; // 最小高度
    const maxHeight = 150; // 最大高度
    
    if (this.maxSteps === this.minSteps) return minHeight;

    // 归一化计算
    let percentage = (val - this.minSteps) / (this.maxSteps - this.minSteps);
    return minHeight + percentage * (maxHeight - minHeight);
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        // 1. 顶部 Hero Card (渐变背景)
        Column() {
          // 标题栏占位
          Row() {
            Text('步数趋势')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .height(56)
          .margin({ top: 10 })

          // 核心数据展示
          Row() {
            Column() {
              Text('平均步数')
                .fontSize(14)
                .fontColor('rgba(255,255,255,0.8)')
              Text(`${this.avgSteps}`)
                .fontSize(36)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .margin({ top: 8 })
            }
            .alignItems(HorizontalAlign.Start)
            
            Blank()

            Column() {
              Text('总计步数')
                .fontSize(14)
                .fontColor('rgba(255,255,255,0.8)')
              Text(`${this.totalSteps}`)
                .fontSize(24)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFFFFF')
                .margin({ top: 12 })
            }
            .alignItems(HorizontalAlign.End)
          }
          .width('100%')
          .padding({ left: 24, right: 24, bottom: 30 })
        }
        .width('100%')
        .linearGradient({
          angle: 135,
          colors: [['#FF9A9E', 0.0], ['#FECFEF', 1.0]] // 暖色调渐变
        })
        .borderRadius({ bottomLeft: 30, bottomRight: 30 })
        .shadow({ radius: 20, color: 'rgba(255, 154, 158, 0.4)', offsetY: 10 })

        // 2. 图表区域 (上浮卡片)
        Column() {
          Text('近期活动记录')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
            .width('100%')
            .padding({ left: 20, top: 20 })
          
          if (this.stepsData.length > 0) {
            List({ space: 12 }) {
              ForEach(this.stepsData, (item: HealthData) => {
                ListItem() {
                  Column() {
                    // 柱子
                    Column()
                      .width(12)
                      .height(this.getBarHeight(item.steps))
                      .linearGradient({
                        angle: 180,
                        colors: item.steps >= this.avgSteps 
                          ? [['#FF9A9E', 0.0], ['#FECFEF', 1.0]] 
                          : [['#E0E0E0', 0.0], ['#F5F5F5', 1.0]]
                      })
                      .borderRadius(6)
                    
                    // 数值
                    Text(`${item.steps}`)
                      .fontSize(10)
                      .fontColor('#999')
                      .margin({ top: 6 })
                  }
                  .justifyContent(FlexAlign.End)
                  .height(200)
                }
              })
            }
            .listDirection(Axis.Horizontal)
            .height(240)
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 16 })
            .alignListItem(ListItemAlign.End)
          } else {
            Column() {
              Image($r('app.media.startIcon'))
                .width(80)
                .height(80)
                .opacity(0.2)
                .grayscale(1)
              Text('暂无数据')
                .fontSize(14)
                .fontColor('#CCC')
                .margin({ top: 10 })
            }
            .height(200)
            .justifyContent(FlexAlign.Center)
          }
        }
        .width('90%')
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
        .shadow({ radius: 30, color: 'rgba(0,0,0,0.05)', offsetY: 10 })
        .margin({ top: -20 }) // 负边距，实现卡片上浮效果
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F9FAFB')

      BackButton()
        .margin({ top: 10, left: 10 })
    }
  }
}