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
      // 1. 背景层
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [['#FFF0F5', 0.0], ['#FFFFFF', 0.4]] // 浅粉色渐变
        })

      Column() {
        // 标题栏占位 (由 BackButton 和 标题组成)
        Row() {
          Text('步数趋势')
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
            Text('平均步数')
              .fontSize(14)
              .fontColor('#666')
            Text(`${this.avgSteps}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF6B81')
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          Divider().vertical(true).height(30).color('#EEE')

          Column() {
            Text('总计步数')
              .fontSize(14)
              .fontColor('#666')
            Text(`${this.totalSteps}`)
              .fontSize(24)
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
        .shadow({ radius: 10, color: 'rgba(255, 182, 193, 0.2)', offsetY: 4 })
        .margin({ top: 20, bottom: 20 })

        // 3. 图表区域
        if (this.stepsData.length > 0) {
          Column() {
            Text('近期活动记录')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .width('100%')
              .padding({ left: 16, top: 16 })
            
            List({ space: 12 }) {
              ForEach(this.stepsData, (item: HealthData) => {
                ListItem() {
                  Column() {
                    // 柱子
                    Column()
                      .width(16)
                      .height(this.getBarHeight(item.steps)) // 使用动态高度
                      .backgroundColor(item.steps >= this.avgSteps ? '#FF6B81' : '#FFB6C1') // 高于平均值颜色更深
                      .borderRadius({ topLeft: 8, topRight: 8, bottomLeft: 8, bottomRight: 8 })
                    
                    // 数值
                    Text(`${item.steps}`)
                      .fontSize(10)
                      .fontColor('#999')
                      .margin({ top: 6 })
                    
                    // 时间 (只显示时:分)
                    Text(new Date(item.timestamp).toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' }))
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
            Text('暂无步数数据')
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
    .backgroundColor('#F9FAFB') // 整体背景微灰
  }
}