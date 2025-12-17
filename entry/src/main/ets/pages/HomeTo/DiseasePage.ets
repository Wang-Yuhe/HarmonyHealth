// entry/src/main/ets/pages/MedicalHistory/MedicalHistoryPage.ets (或 DiseasePage.ets)
import router from '@ohos.router';
import { MedicalRecord } from '../../common/model/MedicalRecordModel';
import { HealthDB } from '../../database/HealthDB';

@Entry
@Component
export struct DiseasePage {
  @State records: MedicalRecord[] = [];
  // 获取当前登录用户 (用于数据库查询)
  @StorageProp('currentUser') currentUser: string = '';

  // 搜索关键词状态
  @State searchText: string = '';

  // 页面显示时，从数据库重新拉取数据
  async onPageShow() {
    let targetUser = this.currentUser || 'admin'; // 兜底
    this.records = await HealthDB.getInstance().getMedicalRecords(targetUser);
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // 底层背景容器
      Column() {
        // ===============================================
        // 1. 顶部紫色头部区域
        // ===============================================
        Column() {
          // 1.1 导航栏 (返回按钮 + 标题)
          Row() {
            // 返回按钮 (白色圆形背景)
            Button({ type: ButtonType.Circle, stateEffect: true }) {
              Image($r('app.media.backButton')) // 确保资源存在
                .width(20).height(20)
                .fillColor('#4A3B99')
            }
            .width(40).height(40)
            .backgroundColor(Color.White)
            .onClick(() => router.back())

            Text('疾病历史档案')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .margin({ left: 16 })

            Blank()
          }
          .width('100%')
          .padding({ top: 12, bottom: 20 })

          // 1.2 统计数据展示
          Row() {
            Column() {
              Text(this.records.length.toString()) // 大数字
                .fontSize(48)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .lineHeight(56)

              Text('总记录数') // 小标签
                .fontSize(14)
                .fontColor('rgba(255,255,255,0.7)')
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)

            Blank()
          }
          .width('100%')
          .padding({ left: 10, right: 10, bottom: 30 })

        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 10 })
        // 紫色渐变背景
        .linearGradient({
          angle: 180,
          colors: [['#4A3B99', 0.0], ['#352880', 1.0]]
        })

        // ===============================================
        // 2. 下方白色卡片区域
        // ===============================================
        Column() {
          // 2.1 搜索框
          Search({ placeholder: '搜索病历标题、医院或日期...' })
            .width('100%')
            .height(45)
            .backgroundColor('#F5F6FA') // 浅灰背景
            .placeholderColor('#A0A0A0')
            .margin({ top: 20, bottom: 10 })
            .onChange((value: string) => {
              this.searchText = value;
            })

          // 2.2 内容列表 或 空状态
          if (this.records.length === 0) {
            this.buildEmptyState()
          } else {
            List({ space: 14 }) {
              ForEach(this.records.filter(item =>
              item.title.includes(this.searchText) ||
              item.hospital.includes(this.searchText)
              ), (item: MedicalRecord) => {

                ListItem() {
                  this.buildRecordCard(item)
                }
                .onClick(() => {
                  // 修正跳转路径，指向详情页
                  router.pushUrl({
                    url: 'pages/RecordEditPage', // 确保路径正确
                    params: { record: item }
                  })
                })

              }, (item: MedicalRecord) => JSON.stringify(item))

              // 底部垫高
              ListItem().height(80)
            }
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
          }
        }
        .width('100%')
        .layoutWeight(1) // 占满剩余高度
        .backgroundColor(Color.White)
        .padding({ left: 20, right: 20 })
        // 左上右上圆角
        .borderRadius({ topLeft: 30, topRight: 30 })
        .margin({ top: -20 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#352880') // 防止底部露出白色缝隙

      // ===============================================
      // 3. 悬浮添加按钮 (FAB) - 紫色系
      // ===============================================
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('+')
          .fontSize(32)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Lighter)
          .margin({ bottom: 4 })
      }
      .width(60)
      .height(60)
      .backgroundColor('#6C5DD3')
      .shadow({ radius: 10, color: '#40352880', offsetY: 6 })
      .margin({ right: 24, bottom: 32 })
      .onClick(() => {
        // 修正跳转路径，指向新增页
        router.pushUrl({ url: 'pages/AddRecordPage' })
      })
    }
    .width('100%')
    .height('100%')
  }

  // --- 空状态 UI ---
  @Builder buildEmptyState() {
    Column() {
      Text('📂')
        .fontSize(70)
        .margin({ bottom: 20, top: 60 })
        .opacity(0.8)

      Text('暂无病历数据')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .margin({ bottom: 8 })

      Text('您的健康档案空空如也\n点击右下角按钮录入第一条数据')
        .fontSize(14)
        .fontColor('#999')
        .textAlign(TextAlign.Center)
        .lineHeight(22)
        .margin({ bottom: 40 })

      Button('立即录入')
        .width(160)
        .height(42)
        .fontSize(15)
        .backgroundColor('#F0EFFF')
        .fontColor('#4A3B99')
        .onClick(() => {
          router.pushUrl({ url: 'pages/AddRecordPage' })
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }

  // --- 病历卡片 UI ---
  @Builder buildRecordCard(item: MedicalRecord) {
    Row() {
      // 左侧装饰条
      Column()
        .width(4)
        .height(40)
        .backgroundColor('#6C5DD3')
        .borderRadius(2)
        .margin({ right: 12 })

      // 中间内容
      Column({ space: 4 }) {
        Text(item.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${typeof item.date === 'string' ? item.date.split('T')[0] : '未知日期'} | ${item.hospital}`)
          .fontSize(12)
          .fontColor('#999')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 右侧 PDF/图片 图标
      if (item.pdfUri) {
        Text('PDF')
          .fontSize(10)
          .fontColor(Color.White)
          .backgroundColor('#FF6B6B')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4)
      } else if (item.imageUri) {
        Image(item.imageUri)
          .width(36).height(36)
          .borderRadius(6)
          .objectFit(ImageFit.Cover)
          .backgroundColor('#F0F0F0')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FBFBFD')
    .borderRadius(16)
    .margin({ bottom: 2 })
  }
}