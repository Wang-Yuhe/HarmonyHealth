/**
 * @file ExploreView.ets
 * @description Main View for the Explore Feature
 */
import { ExploreVM } from '../viewmodel/ExploreVM';
import { ExploreData, DietRecommendation, ExerciseRecommendation, DailySchedule, HealthTip } from '../model/ExploreModels';

// --- Constants & Styles ---
const COLOR_BG = '#F5F7FA'; // Light Grey-Blue
const COLOR_PRIMARY = '#4A90E2'; // Bright Blue
const COLOR_ACCENT = '#FF6B6B'; // Soft Red
const COLOR_SUCCESS = '#2ECC71'; // Green
const COLOR_CARD_BG = '#FFFFFF';
const COLOR_TEXT_MAIN = '#2C3E50';
const COLOR_TEXT_SUB = '#7F8C8D';

@Component
export struct ExploreView {
  @State vm: ExploreVM = new ExploreVM();

  build() {
    Column() {
      // Header / Title Bar
      Row() {
        Text("发现")
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_TEXT_MAIN)
        Blank()
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Image($r('app.media.startIcon')) // Placeholder for refresh icon
            .width(24)
            .height(24)
            .fillColor(COLOR_PRIMARY)
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.vm.loadData(true);
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 10, bottom: 10 })
      .backgroundColor(COLOR_BG)

      if (this.vm.isLoading) {
        this.LoadingView()
      } else if (this.vm.exploreData) {
        Scroll() {
          Column({ space: 20 }) {
            // 1. Greeting & Quote
            this.GreetingSection(this.vm.exploreData!)

            // 2. Diet Plan
            Text("营养计划")
              .sectionTitle()
            List({ space: 12 }) {
              ForEach(this.vm.exploreData!.dietPlan, (item: DietRecommendation) => {
                ListItem() {
                  this.DietCard(item)
                }
              })
            }
            .listDirection(Axis.Horizontal)
            .width('100%')
            .height(160)
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
            .padding({ left: 20, right: 20 })

            // 3. Exercise Plan
            Text("运动建议")
              .sectionTitle()
            List({ space: 12 }) {
              ForEach(this.vm.exploreData!.exercisePlan, (item: ExerciseRecommendation) => {
                ListItem() {
                  this.ExerciseCard(item)
                }
              })
            }
            .listDirection(Axis.Horizontal)
            .width('100%')
            .height(140)
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
            .padding({ left: 20, right: 20 })

            // 4. Schedule
            Text("每日流程")
              .sectionTitle()
            Column({ space: 10 }) {
              ForEach(this.vm.exploreData!.schedule, (item: DailySchedule) => {
                this.ScheduleItem(item)
              })
            }
            .padding({ left: 20, right: 20 })

            // 5. Tips
            Text("健康小贴士")
              .sectionTitle()
            Grid() {
              ForEach(this.vm.exploreData!.healthTips, (item: HealthTip) => {
                GridItem() {
                  this.TipCard(item)
                }
              })
            }
            .columnsTemplate('1fr 1fr')
            .rowsGap(12)
            .columnsGap(12)
            .height(200) // Fixed height for grid or calculate dynamic
            .padding({ left: 20, right: 20, bottom: 50 })

          }
          .width('100%')
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)
      } else {
        // Error State
        Column() {
          Text("出错了，请稍后重试。")
          Button("重试").onClick(() => this.vm.loadData(true))
        }
        .justifyContent(FlexAlign.Center)
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLOR_BG)
  }

  @Builder
  LoadingView() {
    Column() {
      LoadingProgress()
        .color(COLOR_PRIMARY)
        .width(50)
        .height(50)
      Text("正在为您生成个性化计划...")
        .margin({ top: 20 })
        .fontColor(COLOR_TEXT_SUB)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  GreetingSection(data: ExploreData) {
    Column() {
      Text(data.greeting)
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(COLOR_TEXT_MAIN)
        .width('100%')
      
      Stack() {
        Image($r('app.media.startIcon')) // Background pattern or gradient
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .opacity(0.1)
          .borderRadius(16)
        
        Column() {
          Text("每日灵感")
            .fontSize(12)
            .fontColor(Color.White)
            .backgroundColor(COLOR_ACCENT)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(8)
            .margin({ bottom: 8 })
          
          Text(`"${data.dailyQuote}"`)
            .fontSize(16)
            .fontStyle(FontStyle.Italic)
            .fontWeight(FontWeight.Medium)
            .fontColor(COLOR_TEXT_MAIN)
            .textAlign(TextAlign.Center)
        }
        .padding(20)
        .width('100%')
      }
      .margin({ top: 15 })
      .width('100%')
      .height(120)
      .backgroundColor(Color.White)
      .borderRadius(16)
      .shadow({ radius: 10, color: '#10000000', offsetY: 5 })
    }
    .padding({ left: 20, right: 20 })
  }

  @Builder
  DietCard(item: DietRecommendation) {
    Column() {
      Row() {
        Text(item.mealType)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_PRIMARY)
        Blank()
        Text(`${item.calories} kcal`)
          .fontSize(12)
          .fontColor(COLOR_TEXT_SUB)
      }
      .width('100%')
      
      Text(item.suggestion)
        .fontSize(14)
        .fontColor(COLOR_TEXT_MAIN)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 8, bottom: 8 })
        .layoutWeight(1)

      Row({ space: 5 }) {
        ForEach(item.tags, (tag: string) => {
          Text(tag)
            .fontSize(10)
            .fontColor(COLOR_SUCCESS)
            .backgroundColor('#E8F8F5')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(4)
        })
      }
    }
    .width(200)
    .height('100%')
    .padding(15)
    .backgroundColor(COLOR_CARD_BG)
    .borderRadius(16)
    .shadow({ radius: 5, color: '#05000000', offsetY: 2 })
  }

  @Builder
  ExerciseCard(item: ExerciseRecommendation) {
    Column() {
      Row() {
        Text(item.activity)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_TEXT_MAIN)
      }
      .width('100%')
      
      Row() {
        Text(item.duration)
          .fontSize(12)
          .fontColor(COLOR_TEXT_SUB)
        Blank()
        Text(item.intensity)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(item.intensity === 'High' ? COLOR_ACCENT : COLOR_SUCCESS)
      }
      .width('100%')
      .margin({ top: 5 })

      Text(item.benefits)
        .fontSize(12)
        .fontColor(COLOR_TEXT_SUB)
        .margin({ top: 10 })
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width(160)
    .height('100%')
    .padding(15)
    .backgroundColor(COLOR_CARD_BG)
    .borderRadius(16)
    .shadow({ radius: 5, color: '#05000000', offsetY: 2 })
  }

  @Builder
  ScheduleItem(item: DailySchedule) {
    Row() {
      Column() {
        Text(item.time)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_PRIMARY)
      }
      .width(50)
      .alignItems(HorizontalAlign.Start)

      Column()
        .width(2)
        .height(30)
        .backgroundColor('#E0E0E0')
        .margin({ left: 5, right: 15 })

      Text(item.activity)
        .fontSize(15)
        .fontColor(COLOR_TEXT_MAIN)
    }
    .width('100%')
    .padding({ top: 5, bottom: 5 })
  }

  @Builder
  TipCard(item: HealthTip) {
    Column() {
      Text(item.category)
        .fontSize(10)
        .fontColor(COLOR_ACCENT)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 5 })
      
      Text(item.title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLOR_TEXT_MAIN)
        .margin({ bottom: 5 })
      
      Text(item.content)
        .fontSize(12)
        .fontColor(COLOR_TEXT_SUB)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(120)
    .padding(12)
    .backgroundColor(COLOR_CARD_BG)
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
    .shadow({ radius: 5, color: '#05000000', offsetY: 2 })
  }
}

// --- Styles Extension ---
@Extend(Text) function sectionTitle() {
  .fontSize(18)
  .fontWeight(FontWeight.Bold)
  .fontColor(COLOR_TEXT_MAIN)
  .width('100%')
  .padding({ left: 20, top: 20, bottom: 10 })
}
