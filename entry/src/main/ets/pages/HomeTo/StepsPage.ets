// StepsPage.ets 步数情况页面
import { BackButton } from '../../common/components/BackButton'
import { HealthDB } from '../../database/HealthDB';
import { HealthData } from '../../common/model/HealthData';

@Entry
@Component
struct StepsPage {
  @State stepsData: HealthData[] = [];
  @State maxSteps: number = 1;
  @State minSteps: number = 0;

  async aboutToAppear() {
    // 获取最近 20 条数据用于展示趋势
    this.stepsData = await HealthDB.getInstance().getRecentHealthData(20);
    if (this.stepsData.length > 0) {
      this.maxSteps = Math.max(...this.stepsData.map(d => d.steps));
      this.minSteps = Math.min(...this.stepsData.map(d => d.steps));
      
      // 如果最大最小值相等（比如刚开始），手动拉开一点差距防止除以0
      if (this.maxSteps === this.minSteps) {
        this.minSteps = Math.max(0, this.maxSteps - 100);
      }
    }
  }

  // 动态计算高度，放大变化趋势
  getBarHeight(val: number): number {
    const minHeight = 50; // 最小高度
    const maxHeight = 200; // 最大高度
    
    // 归一化计算
    let percentage = (val - this.minSteps) / (this.maxSteps - this.minSteps);
    return minHeight + percentage * (maxHeight - minHeight);
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        // 标题栏
        Text('步数趋势')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 20 })
          .alignSelf(ItemAlign.Center)

        // 简单的柱状图模拟
        if (this.stepsData.length > 0) {
          List({ space: 10 }) {
            ForEach(this.stepsData, (item: HealthData) => {
              ListItem() {
                Column() {
                  // 柱子
                  Column()
                    .width(20)
                    .height(this.getBarHeight(item.steps)) // 使用动态高度
                    .backgroundColor('#FFB6C1')
                    .borderRadius({ topLeft: 4, topRight: 4 })
                  
                  // 数值
                  Text(`${item.steps}`)
                    .fontSize(10)
                    .fontColor('#666')
                    .margin({ top: 4 })
                  
                  // 时间 (只显示时:分)
                  Text(new Date(item.timestamp).toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' }))
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
          .alignListItem(ListItemAlign.End)
        } else {
          Text('暂无数据')
            .fontSize(16)
            .fontColor('#999')
            .margin({ top: 100 })
        }
      }
      .width('100%')
      .height('100%')
      .padding({ top: 60 }) // 避开返回按钮

      BackButton()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}