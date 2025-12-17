/**
 * @file ExploreView.ets
 * @description Main View for the Explore Feature
 */
import { ExploreVM } from '../viewmodel/ExploreVM';
import { GreetingData, DietData, ExerciseData, ScheduleData, HealthTipsData, DietRecommendation, ExerciseRecommendation, DailySchedule, HealthTip } from '../model/ExploreModels';

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

  @StorageLink('Explore_Greeting') greetingJson: string = '';
  @StorageLink('Explore_Diet') dietJson: string = '';
  @StorageLink('Explore_Exercise') exerciseJson: string = '';
  @StorageLink('Explore_Schedule') scheduleJson: string = '';
  @StorageLink('Explore_Tips') tipsJson: string = '';

  @StorageProp('Explore_Greeting_Loading') isGreetingLoading: boolean = false;
  @StorageProp('Explore_Diet_Loading') isDietLoading: boolean = false;
  @StorageProp('Explore_Exercise_Loading') isExerciseLoading: boolean = false;
  @StorageProp('Explore_Schedule_Loading') isScheduleLoading: boolean = false;
  @StorageProp('Explore_Tips_Loading') isTipsLoading: boolean = false;

  getGreetingData(): GreetingData | null {
    return this.greetingJson ? JSON.parse(this.greetingJson) : null;
  }

  getDietData(): DietData | null {
    return this.dietJson ? JSON.parse(this.dietJson) : null;
  }

  getExerciseData(): ExerciseData | null {
    return this.exerciseJson ? JSON.parse(this.exerciseJson) : null;
  }

  getScheduleData(): ScheduleData | null {
    return this.scheduleJson ? JSON.parse(this.scheduleJson) : null;
  }

  getTipsData(): HealthTipsData | null {
    return this.tipsJson ? JSON.parse(this.tipsJson) : null;
  }

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
          this.vm.refreshAll();
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 10, bottom: 10 })
      .backgroundColor(COLOR_BG)

      Scroll() {
        Column({ space: 20 }) {
          // 1. Greeting & Quote
          if (this.isGreetingLoading) {
            this.SectionLoading()
          } else if (this.getGreetingData()) {
            this.GreetingSection(this.getGreetingData()!)
          } else {
            this.SectionError(() => { this.vm.refreshGreeting() })
          }

          // 1.5 Banner Swiper
          this.BannerSwiper()

          // 2. Diet Plan
          Row() {
            this.SectionHeader("营养计划")
            Blank()
            this.RefreshIcon(() => { this.vm.refreshDiet() }, this.isDietLoading)
          }.width('100%').padding({ right: 20 })
          
          if (this.isDietLoading) {
            this.SectionLoading()
          } else if (this.getDietData()) {
            List({ space: 12 }) {
              ForEach(this.getDietData()!.dietPlan, (item: DietRecommendation) => {
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
          } else {
            this.SectionError(() => { this.vm.refreshDiet() })
          }

          // 3. Exercise Plan
          Row() {
            this.SectionHeader("运动建议")
            Blank()
            this.RefreshIcon(() => { this.vm.refreshExercise() }, this.isExerciseLoading)
          }.width('100%').padding({ right: 20 })

          if (this.isExerciseLoading) {
            this.SectionLoading()
          } else if (this.getExerciseData()) {
            List({ space: 12 }) {
              ForEach(this.getExerciseData()!.exercisePlan, (item: ExerciseRecommendation) => {
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
          } else {
            this.SectionError(() => { this.vm.refreshExercise() })
          }

          // 4. Schedule
          Row() {
            this.SectionHeader("每日流程")
            Blank()
            this.RefreshIcon(() => { this.vm.refreshSchedule() }, this.isScheduleLoading)
          }.width('100%').padding({ right: 20 })

          if (this.isScheduleLoading) {
            this.SectionLoading()
          } else if (this.getScheduleData()) {
            Column({ space: 10 }) {
              ForEach(this.getScheduleData()!.schedule, (item: DailySchedule) => {
                this.ScheduleItem(item)
              })
            }
            .padding({ left: 20, right: 20 })
          } else {
            this.SectionError(() => { this.vm.refreshSchedule() })
          }

          // 5. Tips
          Row() {
            this.SectionHeader("健康小贴士")
            Blank()
            this.RefreshIcon(() => { this.vm.refreshTips() }, this.isTipsLoading)
          }.width('100%').padding({ right: 20 })

          if (this.isTipsLoading) {
            this.SectionLoading()
          } else if (this.getTipsData()) {
            Grid() {
              ForEach(this.getTipsData()!.healthTips, (item: HealthTip) => {
                GridItem() {
                  this.TipCard(item)
                }
              })
            }
            .columnsTemplate('1fr 1fr')
            .rowsGap(12)
            .columnsGap(12)
            .height(200)
            .padding({ left: 20, right: 20, bottom: 50 })
          } else {
            this.SectionError(() => { this.vm.refreshTips() })
          }

        }
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLOR_BG)
  }

  @Builder
  SectionHeader(title: string): void {
    Row() {
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLOR_TEXT_MAIN)
    }
    .padding({ left: 20, top: 20, bottom: 10 })
  }

  @Builder
  BannerSwiper(): void {
    Swiper() {
      this.BannerItem("7天瑜伽挑战", "开始你的柔韧之旅", '#6C5CE7')
      this.BannerItem("健康饮食指南", "吃出好身材", '#00B894')
      this.BannerItem("改善睡眠质量", "拥有深度睡眠", '#FD79A8')
    }
    .autoPlay(true)
    .interval(5000)
    .height(110)
    .itemSpace(15)
    .margin({ left: 20, right: 20, top: 10, bottom: 10 })
    .borderRadius(16)
    .indicator(true)
  }

  @Builder
  BannerItem(title: string, subtitle: string, color: string): void {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(color)
        .borderRadius(16)
        .opacity(0.9)
      
      Column() {
        Text(title)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ bottom: 8 })
        
        Text(subtitle)
          .fontSize(14)
          .fontColor(Color.White)
          .opacity(0.9)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)
      .padding(24)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  RefreshIcon(action: () => void, isLoading: boolean): void {
    if (isLoading) {
      LoadingProgress().width(20).height(20).color(COLOR_PRIMARY)
    } else {
      Image($r('app.media.update')) // Replace with refresh icon
        .width(20)
        .height(20)
        .fillColor(COLOR_TEXT_SUB)
        .onClick(action)
    }
  }

  @Builder
  SectionLoading(): void {
    Row() {
      LoadingProgress().width(24).height(24).color(COLOR_PRIMARY).margin({ right: 10 })
      Text("正在生成...").fontSize(14).fontColor(COLOR_TEXT_SUB)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding(20)
  }

  @Builder
  SectionError(retry: () => void): void {
    Row() {
      Text("加载失败 ").fontSize(14).fontColor(COLOR_TEXT_SUB)
      Text("重试").fontSize(14).fontColor(COLOR_PRIMARY).onClick(retry)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding(20)
  }

  @Builder
  GreetingSection(data: GreetingData): void {
    Column() {
      // Main Colored Card Container
      Column() {
        // 1. Greeting Title (White Text)
        Text(data.greeting)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .width('100%')
          .margin({ bottom: 16 })

        // 2. Inspiration Inner Box (Layered)
        Column() {
          Row() {
            Text("每日灵感")
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor(COLOR_PRIMARY)
              .backgroundColor(Color.White)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .borderRadius(8)
          }
          .width('100%')
          .margin({ bottom: 10 })

          Text(`“${data.dailyQuote}”`)
            .fontSize(14)
            .fontStyle(FontStyle.Italic)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .opacity(0.9)
            .lineHeight(24)
            .width('100%')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .backgroundColor('rgba(255, 255, 255, 0.15)') // Glassmorphism effect
        .borderRadius(12)
        .padding(16)
        .backdropBlur(10)
      }
      .width('100%')
      .linearGradient({
        angle: 135,
        colors: [[COLOR_PRIMARY, 0.0], ['#6C5CE7', 1.0]] // Blue to Purple gradient
      })
      .borderRadius(20)
      .padding(20)
      .shadow({ radius: 10, color: 'rgba(74, 144, 226, 0.3)', offsetY: 5 })
    }
    .padding({ left: 20, right: 20 })
  }

  @Builder
  DietCard(item: DietRecommendation): void {
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
  ExerciseCard(item: ExerciseRecommendation): void {
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
  ScheduleItem(item: DailySchedule): void {
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
  TipCard(item: HealthTip): void {
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
// Removed sectionTitle extension as it is replaced by SectionHeader builder
