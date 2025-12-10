import { BackButton } from "../../common/components/BackButton";
import { MedicalRecord } from "../../common/model/MedicalRecordModel";
import { router } from "@kit.ArkUI";

@Entry
@Component
struct DiseasePage {
  @StorageLink('MedicalRecords') records: MedicalRecord[] = [];

  build() {
    Column() {
      // 顶部导航
      Row() {
        Image($r('app.media.backButton'))
          .width(24).height(24)
          .onClick(() => router.back())
        Text('疾病历史档案').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 16 })
      }

      .width('100%')
      .padding(20)
      .backgroundColor(Color.White)

      // 如果没有数据，显示空状态
      if (this.records.length === 0) {
        Column() {
          Text('暂无病历数据').fontColor('#999').margin({ top: 50 })
        }.width('100%')
      } else {
        List({ space: 12 }) {
          ForEach(this.records, (item: MedicalRecord) => {
            ListItem() {
              Row() {
                // 左侧图标或缩略图
                Image($r(`app.media.icon`)) // 替换为默认图标
                  .width(50).height(50)
                  .borderRadius(8)
                  .backgroundColor('#eee')

                // 中间信息
                Column({ space: 4 }) {
                  Text(item.title).fontSize(16).fontWeight(FontWeight.Medium)
                  Text(`${item.date.split('T')[0]} | ${item.hospital}`)
                    .fontSize(12).fontColor('#999')

                  // 标签展示
                  Row() {
                    ForEach(item.tags, (tag: string) => {
                      Text(tag)
                        .fontSize(10)
                        .fontColor('#666')
                        .backgroundColor('#f0f0f0')
                        .padding(3)
                        .borderRadius(4)
                        .margin({ right: 4 })
                    })
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                .padding({ left: 12 })

                // 右侧箭头
                Text('>').fontColor('#ccc')
              }
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .width('100%')
            }
            .onClick(() => {
              router.pushUrl({
                url: 'pages/RecordEditPage', // 跳转到详情页
                params: { record: item } // 传递数据
              })
            })
          }, (item: MedicalRecord) => JSON.stringify(item))
        }

        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 10 })
      }
        // 底部添加按钮 (悬浮)
        Button('+ 录入新病历')
          .width('90%')
          .height(50)
          .backgroundColor('#007DFF')
          .margin({ bottom: 20 })
          .shadow({ radius: 10, color: '#40007DFF', offsetY: 5 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: `pages/AddRecordPage`, })
          })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}
