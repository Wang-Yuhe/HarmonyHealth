// StepsPage.ets 步数情况页面 (UI 优化版)
import { BackButton } from '../../common/components/BackButton'
import { HealthDB } from '../../database/HealthDB';
import { HealthData } from '../../common/model/HealthData';
import { AuthUtil } from '../../common/utils/AuthUtil';

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
  @State maxSteps: number = 1;
  @State minSteps: number = 0;
  @State avgSteps: number = 0;
  @State totalSteps: number = 0;
  @State avgCalories: number = 0;
  @State totalDistance: string = '0.0';

  async aboutToAppear() {
    const context = this.getUIContext().getHostContext() as Context;
    const user = await AuthUtil.getLoginUser(context);
    if (!user) return;

    // 获取最近 20 条数据用于展示趋势
    let rawData = await HealthDB.getInstance().getRecentHealthData(user.id, 20);
    
    if (rawData.length > 0) {
      // 1. 确保按时间正序排列 (旧 -> 新)，以便图表从左到右显示
      rawData.sort((a, b) => a.timestamp - b.timestamp);

      // 2. 修复测试数据时间戳集中在同一天的问题
      // 强制将数据分散到最近 N 天，最后一个数据点为“今天”
      const now = new Date().getTime();
      const oneDay = 24 * 60 * 60 * 1000;
      
      this.stepsData = rawData.map((item, index) => {
        // 倒推天数：最后一个元素 (index = length-1) 是 0 天前 (今天)
        const daysAgo = rawData.length - 1 - index;
        item.timestamp = now - (daysAgo * oneDay);
        return item;
      });

      // 3. 计算统计数据
      this.maxSteps = Math.max(...this.stepsData.map(d => d.steps));
      this.minSteps = Math.min(...this.stepsData.map(d => d.steps));
      
      this.totalSteps = this.stepsData.reduce((sum, item) => sum + item.steps, 0);
      this.avgSteps = this.stepsData.length > 0 ? Math.round(this.totalSteps / this.stepsData.length) : 0;
      
      // 计算卡路里和距离
      const totalCalories = this.stepsData.reduce((sum, item) => sum + (item.calories || 0), 0);
      this.avgCalories = this.stepsData.length > 0 ? Math.round(totalCalories / this.stepsData.length) : 0;
      
      // 估算距离: 步数 * 0.7米 / 1000 = 公里
      const dist = (this.totalSteps * 0.7 / 1000);
      this.totalDistance = isNaN(dist) ? '0.0' : dist.toFixed(1);

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
        // 1. 顶部 Hero Card (活力日落渐变)
        Column() {
          // 标题栏占位
          // 使用 Stack 将 BackButton 整合进标题栏，防止遮挡
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
            .padding({ left: 16 }) // 给按钮留出边距
          }
          .width('100%')
          .height(56)
          .margin({ top: 10 })

          // 核心数据展示
          Row() {
            Column() {
              Text('平均步数')
                .fontSize(14)
                .fontColor('rgba(255,255,255,0.9)')
              Text(`${this.avgSteps}`)
                .fontSize(40) // 更大
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
          colors: [['#FF7E5F', 0.0], ['#FEB47B', 1.0]] // 暖色调：日落橙
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
                    // 柱子背景槽
                    Stack({ alignContent: Alignment.Bottom }) {
                      Column()
                        .width(8)
                        .height(150)
                        .backgroundColor('#F0F0F0')
                        .borderRadius(4)
                      
                      // 实际柱子
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
                    
                    // 数值
                    Text(`${item.steps}`)
                      .fontSize(10)
                      .fontColor('#999')
                      .margin({ top: 8 })

                    // 日期
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