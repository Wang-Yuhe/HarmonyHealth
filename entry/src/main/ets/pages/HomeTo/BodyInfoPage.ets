// BodyInfoPage.ets
import { BackButton } from '../../common/components/BackButton'
import { HealthDB } from '../../database/HealthDB'

interface BodyInfoItem {
  label: string
  value: string
}

interface BodyInfoSection {
  title: string
  keys: string[]
}

@Entry
@Component
struct BodyInfoPage {
  private readonly defaultBodyInfoList: BodyInfoItem[] = [
    { label: '性别', value: '男' },
    { label: '身高', value: '175 cm' },
    { label: '体重', value: '65 kg' },
    { label: '头围', value: '58 cm' },
    { label: '肩宽', value: '45 cm' },
    { label: '胸围', value: '90 cm' },
    { label: '腰围', value: '70 cm' },
    { label: '臀围', value: '92 cm' },
    { label: '腿长', value: '95 cm' },
    { label: '常穿鞋码', value: '42' },
    { label: '脚长', value: '26 cm' },
    { label: '脚宽', value: '9.5 cm' }
  ]
  @StorageProp('currentUser') userName: string = "admin"
  @StorageLink('BodyInfoList') bodyInfoList: BodyInfoItem[] = []
  private sections: BodyInfoSection[] = [
    { title: '基础数据', keys: ['性别', '身高', '体重'] },
    { title: '上身围度', keys: ['头围', '肩宽', '胸围'] },
    { title: '下身围度', keys: ['腰围', '臀围', '腿长'] },
    { title: '足部数据', keys: ['常穿鞋码', '脚长', '脚宽'] }
  ]
  @State private editingKey: string = ''
  @State private editValue: string = ''

  async aboutToAppear() {
    HealthDB.getInstance().checkColumns();
    // 1. 先尝试从数据库获取
    console.info(`尝试从数据库获取${this.userName}的数据`)
    let data = await HealthDB.getInstance().getBodyInfo(this.userName)

    if (data && data.length > 0) {
      this.bodyInfoList = data
    } else {
      // 2. 如果数据库没数据，初始化默认值并存入数据库
      this.bodyInfoList = [...this.defaultBodyInfoList]
      await HealthDB.getInstance().saveBodyInfo(this.userName, this.bodyInfoList)
    }
    if (!this.bodyInfoList || this.bodyInfoList.length === 0) {
      this.bodyInfoList = [...this.defaultBodyInfoList]
    }
  }

  private getItemByKey(key: string): BodyInfoItem {
    const item = this.bodyInfoList.find(i => i.label === key)
    return item ?? { label: key, value: '--' }
  }

  private getBMI(): string {
    const hStr = this.getItemByKey('身高').value;
    const wStr = this.getItemByKey('体重').value;
    const h = parseFloat(hStr);
    const w = parseFloat(wStr);
    if (!isNaN(h) && !isNaN(w) && h > 0) {
      return (w / ((h / 100) * (h / 100))).toFixed(1);
    }
    return '--';
  }

  private getBMIStatus(): string {
    const bmi = parseFloat(this.getBMI());
    if (isNaN(bmi)) return '未知';
    if (bmi < 18.5) return '偏瘦';
    if (bmi < 24) return '正常';
    if (bmi < 28) return '超重';
    return '肥胖';
  }

  // 新增：计算 BMI 在进度条上的位置 (百分比 0-100%)
  private getBMIPercent(): string {
    const bmiStr = this.getBMI();
    if (bmiStr === '--') return '0%';
    
    const bmi = parseFloat(bmiStr);
    // 设定显示范围：10 ~ 35 (涵盖绝大多数情况)
    const min = 10;
    const max = 35;
    
    let val = bmi;
    if (val < min) val = min;
    if (val > max) val = max;
    
    const percent = (val - min) / (max - min) * 100;
    return `${percent}%`;
  }

  private startEdit(item: BodyInfoItem): void {
    this.editingKey = item.label
    this.editValue = item.value
  }

  private cancelEdit(): void {
    this.editingKey = ''
    this.editValue = ''
  }
  private async saveEdit(label: string) {
    // 更新本地列表
    console.info(`准备保存数据...当前user为: ${this.userName}`);
    const newList = this.bodyInfoList.map(item => {
      if (item.label === label) {
        return { label: item.label, value: this.editValue } as BodyInfoItem
      }
      return item
    })

    this.bodyInfoList = newList

    // 同步到数据库
    // 检查存储结果
    try {
      await HealthDB.getInstance().saveBodyInfo(this.userName, this.bodyInfoList);
      console.info('数据库保存指令已发送');
    } catch (e) {
      console.error('调用存储方法崩溃:', e);
    }
  }

  @Builder
  private buildEditArea(item: BodyInfoItem) {
    Column() {
      TextInput({ text: this.editValue, placeholder: '请输入数值' })
        .onChange((v: string) => this.editValue = v)
        .height(44)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .border({ width: 1, color: '#E0E0E0', radius: 8 })
        .padding({ left: 12 })

      Row({ space: 12 }) {
        Button('取消')
          .fontSize(14)
          .fontColor('#666')
          .backgroundColor('#F5F5F5')
          .width(70)
          .height(32)
          .onClick(() => this.cancelEdit())

        Button('保存')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor('#007DFF')
          .width(70)
          .height(32)
          .onClick(() => this.saveEdit(item.label))
      }
      .justifyContent(FlexAlign.End)
      .width('100%')
      .margin({ top: 12 })
    }
    .padding(12)
    .backgroundColor('#F9FAFB')
    .borderRadius(8)
    .margin({ top: 8, bottom: 8 })
  }

  @Builder
  private buildInfoItem(item: BodyInfoItem, isLast: boolean) {
    Column() {
      Row() {
        Text(item.label)
          .fontSize(16)
          .fontColor('#333')
          .fontWeight(FontWeight.Medium)

        Row() {
          Text(item.value)
            .fontSize(16)
            .fontColor('#666')
            .margin({ right: 8 })
          
          Image($r('app.media.alter')) 
            .width(16)
            .height(16)
            .fillColor('#007DFF')
            .opacity(0.5)
        }
        .onClick(() => this.startEdit(item))
      }
      .width('100%')
      .height(56)
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      if (this.editingKey === item.label) {
        this.buildEditArea(item)
      }

      if (!isLast && this.editingKey !== item.label) {
        Divider().color('#F0F0F0').strokeWidth(1)
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20 })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        // 1. 顶部 Hero Header (科技蓝渐变)
        Column() {
          Stack({ alignContent: Alignment.Center }) {
            Text('身体档案')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            Row() { BackButton() }
            .width('100%')
            .justifyContent(FlexAlign.Start)
            .padding({ left: 16 })
          }
          .height(56)
          .width('100%')
          .margin({ top: 10 })

          Row() {
            Column() {
              Text('BMI 指数')
                .fontSize(14)
                .fontColor('rgba(255,255,255,0.8)')
              Text(this.getBMI())
                .fontSize(40)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)

            Blank()

            Column() {
              Text('体型评估')
                .fontSize(14)
                .fontColor('rgba(255,255,255,0.8)')
              Text(this.getBMIStatus())
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.White)
                .margin({ top: 12 })
                .backgroundColor('rgba(255,255,255,0.2)')
                .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                .borderRadius(20)
            }
            .alignItems(HorizontalAlign.End)
          }
          .width('100%')
          .padding({ left: 24, right: 24, bottom: 10, top: 10 })

          // 新增：BMI 彩色进度条
          Column() {
            // 1. 进度条背景 (分段颜色)
            Row()
              .width('100%')
              .height(6)
              .linearGradient({
                angle: 90, // 从左到右
                colors: [
                  ['#81D4FA', 0.0],  // 偏瘦 (<18.5)
                  ['#81D4FA', 0.34], 
                  ['#69F0AE', 0.34], // 正常 start (Green)
                  ['#69F0AE', 0.56], 
                  ['#FFD740', 0.56], // 超重 start (Yellow)
                  ['#FFD740', 0.72], 
                  ['#FF5252', 0.72], // 肥胖 start (Red)
                  ['#FF5252', 1.0]
                ]
              })
              .borderRadius(3)
              .clip(true)

            // 2. 指示器
            Row() {
               // 占位，推挤指示器
               Row().width(this.getBMIPercent()).height(1)
               
               // 指示器本体
               Stack({ alignContent: Alignment.Center }) {
                 Circle({ width: 14, height: 14 }).fill(Color.White)
                   .shadow({ radius: 4, color: 'rgba(0,0,0,0.2)', offsetY: 2 })
                 Circle({ width: 6, height: 6 }).fill('#2979FF')
               }
               .offset({ x: -7 }) // 向左回退半径宽度，实现中心对齐
            }
            .width('100%')
            .margin({ top: -10 }) // 向上重叠

            // 3. 刻度标签
            Row() {
              Text('偏瘦').fontSize(10).fontColor('rgba(255,255,255,0.7)')
              Text('正常').fontSize(10).fontColor('rgba(255,255,255,0.9)').fontWeight(FontWeight.Medium)
              Text('超重').fontSize(10).fontColor('rgba(255,255,255,0.7)')
              Text('肥胖').fontSize(10).fontColor('rgba(255,255,255,0.7)')
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ top: 4 })
          }
          .width('100%')
          .padding({ left: 24, right: 24, bottom: 24 })
        }
        .linearGradient({
          angle: 135,
          colors: [['#2979FF', 0.0], ['#448AFF', 1.0]]
        })
        .borderRadius({ bottomLeft: 32, bottomRight: 32 })
        .shadow({ radius: 20, color: 'rgba(41, 121, 255, 0.3)', offsetY: 8 })
        .zIndex(1)

        // 2. 列表内容
        Scroll() {
          Column() {
            ForEach(this.sections, (section: BodyInfoSection) => {
              Column() {
                Row() {
                  Text(section.title)
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#2979FF')
                  Blank()
                }
                .width('100%')
                .padding({ left: 8, bottom: 12, top: 24 })

                Column() {
                  ForEach(section.keys, (key: string, index: number) => {
                    this.buildInfoItem(this.getItemByKey(key), index === section.keys.length - 1)
                  }, (key: string) => key + this.getItemByKey(key).value)
                }
                .backgroundColor(Color.White)
                .borderRadius(20)
                .shadow({ radius: 20, color: 'rgba(0,0,0,0.04)', offsetY: 4 })
              }
            })
            Blank().height(40)
          }
          .padding({ left: 16, right: 16 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .margin({ top: 10 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F1F3F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}