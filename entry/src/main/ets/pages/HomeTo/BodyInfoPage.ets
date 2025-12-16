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
    { title: '基础', keys: ['性别', '身高', '体重'] },
    { title: '上身', keys: ['头围', '肩宽', '胸围'] },
    { title: '下身', keys: ['腰围', '臀围', '腿长'] },
    { title: '脚部', keys: ['常穿鞋码', '脚长', '脚宽'] }
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

  private startEdit(item: BodyInfoItem): void {
    this.editingKey = item.label
    this.editValue = item.value
  }

  private cancelEdit(): void {
    this.editingKey = ''
    this.editValue = ''
  }

  private saveEdit(label: string): void {
    // 关键点：通过 map 创建新对象并替换数组中的元素
    // 这会触发 @StorageLink 的 Setter，进而通知所有关联组件
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
        placeholder: '请输入新数值'
      })
        .onChange((v: string) => this.editValue = v)
        .height(45)
        .width('100%')
        .backgroundColor('#F1F3F5')
        .borderRadius(8)

      Row({ space: 12 }) {
        Button('取消')
          .fontSize(14)
          .fontColor(Color.Gray)
          .backgroundColor(Color.Transparent)
          .onClick(() => this.cancelEdit())

        Button('保存')
          .fontSize(14)
          .backgroundColor('#007DFF')
          .onClick(() => this.saveEdit(item.label))
      }
      .justifyContent(FlexAlign.End)
      .width('100%')
      .margin({ top: 12 })
    }
    .padding(12)
    .backgroundColor('#F9F9F9')
    .borderRadius(8)
    .margin({ top: 10, bottom: 10 })
  }

  @Builder
  private buildInfoItem(item: BodyInfoItem) {
    Column() {
      Row() {
        Text(item.label)
          .fontSize(16)
          .fontColor('#666')

        Row() {
          Text(item.value)
            .fontSize(16)
            .margin({ right: 10 })
          Image($r('app.media.alter')) // 使用现有图标替代
            .width(20)
            .height(20)
            .fillColor('#007DFF')
            .onClick(() => this.startEdit(item))
        }
      }
      .width('100%')
      .height(50)
      .justifyContent(FlexAlign.SpaceBetween)

      if (this.editingKey === item.label) {
        this.buildEditArea(item)
      }

      Divider()
        .color('#EEE')
        .strokeWidth(1)
    }
    .width('100%')
  }

  // ---------- 页面主结构 ----------
  build() {
    Column() {
      // 自定义顶部栏（代替原有的 Stack + BackButton 逻辑，提升布局稳定性）
      Row() {
        BackButton()
        Text('身体档案')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 8 })
          .lineHeight(48)
      }
      .width('100%')
      .padding({ left: 16, top: 16, bottom: 8 })
      .backgroundColor(Color.White)

      Scroll() {
        Column() {
          ForEach(this.sections, (section: BodyInfoSection) => {
            Column() {
              Text(section.title)
                .fontSize(14)
                .fontColor('#999')
                .width('100%')
                .margin({ top: 20, bottom: 8 })

              Column() {
                ForEach(section.keys, (key: string) => {
                  // 注意：这里 getItemByKey 会从 @StorageLink 实时取值
                  this.buildInfoItem(this.getItemByKey(key))
                }, (key: string) => {
                  // 这里的 key 必须包含 value 才能在数据改变时强制刷新该项 ForEach
                  return key + this.getItemByKey(key).value
                })
              }
              .backgroundColor(Color.White)
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
            }
          })
        }
        .padding({ left: 16, right: 16, bottom: 40 })
      }
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}