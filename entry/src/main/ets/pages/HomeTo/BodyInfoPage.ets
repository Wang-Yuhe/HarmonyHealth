// BodyInfoPage.ets
import { BackButton } from '../../common/components/BackButton'

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
  // 默认数据
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
  // 使用 @StorageLink 实现自动同步和 UI 刷新
  @StorageLink('BodyInfoList') bodyInfoList: BodyInfoItem[] = []
  private sections: BodyInfoSection[] = [
    { title: '基础数据', keys: ['性别', '身高', '体重'] },
    { title: '上身围度', keys: ['头围', '肩宽', '胸围'] },
    { title: '下身围度', keys: ['腰围', '臀围', '腿长'] },
    { title: '足部数据', keys: ['常穿鞋码', '脚长', '脚宽'] }
  ]
  @State private editingKey: string = ''
  @State private editValue: string = ''

  aboutToAppear() {
    // 初始化检查
    if (!this.bodyInfoList || this.bodyInfoList.length === 0) {
      this.bodyInfoList = [...this.defaultBodyInfoList]
    }
  }

  // ---------- 数据逻辑 ----------
  private getItemByKey(key: string): BodyInfoItem {
    const item = this.bodyInfoList.find(i => i.label === key)
    return item ?? { label: key, value: '--' }
  }

  // 计算 BMI
  private getBMI(): string {
    const hStr = this.getItemByKey('身高').value;
    const wStr = this.getItemByKey('体重').value;
    const h = parseFloat(hStr);
    const w = parseFloat(wStr);
    if (!isNaN(h) && !isNaN(w) && h > 0) {
      // 身高单位换算 cm -> m
      return (w / ((h / 100) * (h / 100))).toFixed(1);
    }
    return '--';
  }

  // 获取 BMI 状态
  private getBMIStatus(): string {
    const bmi = parseFloat(this.getBMI());
    if (isNaN(bmi)) return '未知';
    if (bmi < 18.5) return '偏瘦';
    if (bmi < 24) return '正常';
    if (bmi < 28) return '超重';
    return '肥胖';
  }

  private startEdit(item: BodyInfoItem): void {
    this.editingKey = item.label
    this.editValue = item.value
  }

  private cancelEdit(): void {
    this.editingKey = ''
    this.editValue = ''
  }

  private saveEdit(label: string): void {
    this.bodyInfoList = this.bodyInfoList.map(item => {
      if (item.label === label) {
        return { label: item.label, value: this.editValue }
      }
      return item
    })
    this.cancelEdit()
  }

  // ---------- Builder ----------
  @Builder
  private buildEditArea(item: BodyInfoItem) {
    Column() {
      TextInput({
        text: this.editValue,
        placeholder: '请输入数值'
      })
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
            .width(18)
            .height(18)
            .fillColor('#007DFF')
            .opacity(0.6)
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

      // 只有非最后一行且不在编辑状态时显示分割线
      if (!isLast && this.editingKey !== item.label) {
        Divider()
          .color('#F5F5F5')
          .strokeWidth(1)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }

  // ---------- 页面主结构 ----------
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        // 1. 顶部 Hero Header (蓝色渐变 + BMI 卡片)
        Column() {
          // 标题栏 (使用 Stack 防止 BackButton 遮挡)
          Stack({ alignContent: Alignment.Center }) {
            Text('身体档案')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            
            Row() {
              BackButton()
            }
            .width('100%')
            .justifyContent(FlexAlign.Start)
            .padding({ left: 16 })
          }
          .height(56)
          .width('100%')
          .margin({ top: 10 })

          // BMI 概览卡片
          Row() {
            Column() {
              Text('BMI 指数')
                .fontSize(14)
                .fontColor('rgba(255,255,255,0.8)')
              Text(this.getBMI())
                .fontSize(36)
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
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                .borderRadius(16)
            }
            .alignItems(HorizontalAlign.End)
          }
          .width('100%')
          .padding({ left: 24, right: 24, bottom: 24, top: 10 })
        }
        .linearGradient({
          angle: 180,
          colors: [['#448AFF', 0.0], ['#5C7CFF', 1.0]]
        })
        .borderRadius({ bottomLeft: 24, bottomRight: 24 })
        .shadow({ radius: 10, color: 'rgba(68, 138, 255, 0.3)', offsetY: 5 })
        .zIndex(1)

        // 2. 列表内容
        Scroll() {
          Column() {
            ForEach(this.sections, (section: BodyInfoSection) => {
              Column() {
                // 分组标题
                Row() {
                  Text(section.title)
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#007DFF')
                  Blank()
                }
                .width('100%')
                .padding({ left: 4, bottom: 8, top: 20 })

                // 分组卡片
                Column() {
                  ForEach(section.keys, (key: string, index: number) => {
                    this.buildInfoItem(this.getItemByKey(key), index === section.keys.length - 1)
                  }, (key: string) => key + this.getItemByKey(key).value)
                }
                .backgroundColor(Color.White)
                .borderRadius(16)
                .shadow({ radius: 15, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
              }
            })
            
            // 底部留白
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