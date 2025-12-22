/**
 * @file ExploreView.ets
 * @description Main View for the Explore Feature
 */
import { ExploreVM } from '../viewmodel/ExploreVM';
import { GreetingData, DietData, ExerciseData, ScheduleData, HealthTipsData, DietRecommendation, ExerciseRecommendation, DailySchedule, HealthTip } from '../model/ExploreModels';

const BANNER_IMAGES = [
  '1.png',
  '2025-12-22_005554.png',
  '2025-12-22_005609.png',
  '2025-12-22_005701.png',
  '2025-12-22_005719.png',
  '2025-12-22_005729.png',
  '2025-12-22_005737.png',
  '2025-12-22_005745.png',
  '2025-12-22_005755.png',
  '2025-12-22_005803.png',
  '2025-12-22_005811.png',
  '2025-12-22_005820.png'
];

// --- Constants & Styles ---
const COLOR_BG_START = '#F0F4F8'; // Gradient Start
const COLOR_BG_END = '#E6EEF5';   // Gradient End
const COLOR_BG = '#F5F7FA'; // Fallback
const COLOR_PRIMARY = '#4A90E2'; // Bright Blue
const COLOR_ACCENT = '#FF6B6B'; // Soft Red
const COLOR_SUCCESS = '#2ECC71'; // Green
const COLOR_CARD_BG = '#FFFFFF';
const COLOR_TEXT_MAIN = '#1A2A3A'; // Darker for better contrast
const COLOR_TEXT_SUB = '#7F8C8D';

@Component
export struct ExploreView {
  @State vm: ExploreVM = new ExploreVM();
  @State bannerImages: string[] = [];

  aboutToAppear() {
    this.vm.refreshAll();
    this.randomizeBanners();
  }

  randomizeBanners() {
    const shuffled = [...BANNER_IMAGES].sort(() => 0.5 - Math.random());
    this.bannerImages = shuffled.slice(0, 5);
  }

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
          .fontSize(34) // Larger font
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_TEXT_MAIN)
          .shadow({ radius: 2, color: 'rgba(0,0,0,0.1)', offsetY: 2 }) // Text shadow
        Blank()
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Image($r('app.media.update')) 
            .width(22)
            .height(22)
            .fillColor(Color.White)
        }
        .width(44)
        .height(44)
        .backgroundColor(COLOR_PRIMARY) // Colored button background
        .shadow({ radius: 8, color: 'rgba(74, 144, 226, 0.4)', offsetY: 4 })
        .onClick(() => {
          this.vm.refreshAll();
        })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16, bottom: 10 }) // Increased padding
      .backgroundColor(Color.Transparent) // Transparent to show gradient

      Scroll() {
        Column({ space: 24 }) { // Increased vertical spacing
          // 1. Banner Swiper (Moved to top for better UX)
          this.BannerSwiper()

          // 2. Greeting & Quote
          if (this.isGreetingLoading) {
            this.SectionLoading()
          } else if (this.getGreetingData()) {
            this.GreetingSection(this.getGreetingData()!)
          } else {
            this.SectionError(() => { this.vm.refreshGreeting() })
          }

          // 3. Diet Plan
          Column() {
            Row() {
              this.SectionHeader("营养计划")
              Blank()
              this.RefreshIcon(() => { this.vm.refreshDiet() }, this.isDietLoading)
            }.width('100%').padding({ right: 24 })
            
            if (this.isDietLoading) {
              this.SectionLoading()
            } else if (this.getDietData()) {
              List({ space: 16 }) { // Increased list spacing
                ForEach(this.getDietData()!.dietPlan, (item: DietRecommendation) => {
                  ListItem() {
                    this.DietCard(item)
                  }
                })
              }
              .listDirection(Axis.Horizontal)
              .width('100%')
              .height(190) // Increased height for better card layout
              .scrollBar(BarState.Off)
              .edgeEffect(EdgeEffect.Spring)
              .padding({ left: 24, right: 24, bottom: 10 }) // Add bottom padding for shadow
            } else {
              this.SectionError(() => { this.vm.refreshDiet() })
            }
          }

          // 4. Exercise Plan
          Column() {
            Row() {
              this.SectionHeader("运动建议")
              Blank()
              this.RefreshIcon(() => { this.vm.refreshExercise() }, this.isExerciseLoading)
            }.width('100%').padding({ right: 24 })

            if (this.isExerciseLoading) {
              this.SectionLoading()
            } else if (this.getExerciseData()) {
              List({ space: 16 }) {
                ForEach(this.getExerciseData()!.exercisePlan, (item: ExerciseRecommendation) => {
                  ListItem() {
                    this.ExerciseCard(item)
                  }
                })
              }
              .listDirection(Axis.Horizontal)
              .width('100%')
              .height(170) // Increased height
              .scrollBar(BarState.Off)
              .edgeEffect(EdgeEffect.Spring)
              .padding({ left: 24, right: 24, bottom: 10 }) // Add bottom padding for shadow
            } else {
              this.SectionError(() => { this.vm.refreshExercise() })
            }
          }

          // 5. Schedule
          Column() {
            Row() {
              this.SectionHeader("每日流程")
              Blank()
              this.RefreshIcon(() => { this.vm.refreshSchedule() }, this.isScheduleLoading)
            }.width('100%').padding({ right: 24 })

            if (this.isScheduleLoading) {
              this.SectionLoading()
            } else if (this.getScheduleData()) {
              Column({ space: 0 }) { // Space handled inside item for timeline effect
                ForEach(this.getScheduleData()!.schedule, (item: DailySchedule, index: number) => {
                  this.ScheduleItem(item, index === this.getScheduleData()!.schedule.length - 1)
                })
              }
              .padding({ left: 24, right: 24 })
              .backgroundColor(Color.White)
              .borderRadius(24)
              .margin({ left: 24, right: 24 })
              .padding({ top: 24, bottom: 24 }) // Inner padding for the card
              .shadow({ radius: 15, color: 'rgba(0,0,0,0.08)', offsetY: 8 })
            } else {
              this.SectionError(() => { this.vm.refreshSchedule() })
            }
          }

          // 6. Tips
          Column() {
            Row() {
              this.SectionHeader("健康小贴士")
              Blank()
              this.RefreshIcon(() => { this.vm.refreshTips() }, this.isTipsLoading)
            }.width('100%').padding({ right: 24 })

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
              .rowsGap(16)
              .columnsGap(16)
              .height(240) // Increased height
              .padding({ left: 24, right: 24, bottom: 50 })
            } else {
              this.SectionError(() => { this.vm.refreshTips() })
            }
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
    .linearGradient({
      angle: 180,
      colors: [[COLOR_BG_START, 0.0], [COLOR_BG_END, 1.0]]
    })
  }

  @Builder
  SectionHeader(title: string): void {
    Row() {
      // Decorative vertical bar
      Column()
        .width(6) // Thicker
        .height(22) // Taller
        .backgroundColor(COLOR_PRIMARY)
        .borderRadius(3)
        .margin({ right: 10 })
        .shadow({ radius: 4, color: 'rgba(74, 144, 226, 0.4)', offsetX: 2 })

      Text(title)
        .fontSize(22) // Larger
        .fontWeight(FontWeight.Bold)
        .fontColor(COLOR_TEXT_MAIN)
    }
    .padding({ left: 24, top: 10, bottom: 10 })
  }

  @Builder
  BannerSwiper(): void {
    Swiper() {
      ForEach(this.bannerImages, (image: string) => {
        this.BannerItem(image)
      })
    }
    .autoPlay(true)
    .interval(5000)
    .height(200) // Increased height to show more image content
    .itemSpace(16)
    .margin({ left: 24, right: 24 })
    .borderRadius(24)
    .indicator(
      Indicator.dot()
        .itemWidth(8)
        .itemHeight(8)
        .selectedItemWidth(24)
        .selectedItemHeight(8)
        .color('rgba(255, 255, 255, 0.6)')
        .selectedColor(Color.White)
    )
    .shadow({ radius: 20, color: 'rgba(0,0,0,0.15)', offsetY: 10 }) // Stronger shadow
  }

  @Builder
  BannerItem(imagePath: string): void {
    Stack() {
      Image($rawfile(`explore_pictures/${imagePath}`))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Fill) // Changed to Fill to show full image
        .borderRadius(24)
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
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .width('100%')
          .margin({ bottom: 20 })

        // 2. Inspiration Inner Box (Layered)
        Column() {
          Row() {
            Text("每日灵感")
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor(COLOR_PRIMARY)
              .backgroundColor(Color.White)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .borderRadius(12)
          }
          .width('100%')
          .margin({ bottom: 12 })

          Text(`“${data.dailyQuote}”`)
            .fontSize(16)
            .fontStyle(FontStyle.Italic)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .opacity(0.95)
            .lineHeight(26)
            .width('100%')
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .backgroundColor('rgba(255, 255, 255, 0.2)') // More visible glass effect
        .borderRadius(16)
        .padding(20)
        .backdropBlur(20)
      }
      .width('100%')
      .linearGradient({
        angle: 135,
        colors: [[COLOR_PRIMARY, 0.0], ['#6C5CE7', 1.0]]
      })
      .borderRadius(28)
      .padding(24)
      .shadow({ radius: 20, color: 'rgba(74, 144, 226, 0.5)', offsetY: 10 })
    }
    .padding({ left: 24, right: 24 })
  }

  @Builder
  DietCard(item: DietRecommendation): void {
    Column() {
      Row() {
        Text(item.mealType)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_TEXT_MAIN)
        Blank()
        Text(`${item.calories} kcal`)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(COLOR_PRIMARY)
          .backgroundColor('rgba(74, 144, 226, 0.1)')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(8)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      
      Text(item.suggestion)
        .fontSize(14)
        .fontColor(COLOR_TEXT_SUB)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 12, bottom: 12 })
        .lineHeight(20)
        .layoutWeight(1)

      Row({ space: 6 }) {
        ForEach(item.tags.slice(0, 2), (tag: string) => { // Limit tags to prevent overflow
          Text(tag)
            .fontSize(10)
            .fontColor(COLOR_SUCCESS)
            .backgroundColor('#E8F8F5')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(6)
        })
      }
    }
    .width(230) // Slightly wider
    .height('100%')
    .padding(18)
    .backgroundColor(COLOR_CARD_BG)
    .borderRadius(24)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.08)', offsetY: 6 }) // Enhanced shadow
  }

  @Builder
  ExerciseCard(item: ExerciseRecommendation): void {
    Column() {
      Row() {
        Text(item.activity)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_TEXT_MAIN)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      
      Row() {
        Image($r('app.media.startIcon')) // Placeholder for clock icon, or use text
          .width(14).height(14).fillColor(COLOR_TEXT_SUB).margin({right: 4})
        Text(item.duration)
          .fontSize(13)
          .fontColor(COLOR_TEXT_SUB)
      }
      .margin({ top: 8 })

      Blank()

      Text(item.benefits)
        .fontSize(13)
        .fontColor(COLOR_TEXT_SUB)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 10 })

      Row() {
        Text(item.intensity)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(item.intensity === 'High' ? '#FF6B6B' : '#2ECC71')
          .backgroundColor(item.intensity === 'High' ? 'rgba(255, 107, 107, 0.1)' : 'rgba(46, 204, 113, 0.1)')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(8)
      }
      .width('100%')
    }
    .width(180)
    .height('100%')
    .padding(18)
    .backgroundColor(COLOR_CARD_BG)
    .borderRadius(24)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.08)', offsetY: 6 }) // Enhanced shadow
  }

  @Builder
  ScheduleItem(item: DailySchedule, isLast: boolean): void {
    Row() {
      // Time Column
      Column() {
        Text(item.time)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_TEXT_MAIN)
          .textAlign(TextAlign.End)
      }
      .width(55)
      .alignItems(HorizontalAlign.End)
      .margin({ right: 14 })

      // Timeline Graphic
      Column() {
        // Dot
        Circle({ width: 12, height: 12 })
          .fill(COLOR_PRIMARY)
          .shadow({ radius: 4, color: 'rgba(74, 144, 226, 0.4)', offsetY: 2 })
        // Line
        if (!isLast) {
          Column()
            .width(2)
            .height(40) // Adjust height based on content
            .backgroundColor('#E0E6ED')
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Center)
      .margin({ right: 14 })

      // Content
      Column() {
        Text(item.activity)
          .fontSize(16)
          .fontColor(COLOR_TEXT_MAIN)
          .margin({ bottom: isLast ? 0 : 28 }) // Spacing for next item
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ left: 10, right: 10 })
  }

  @Builder
  TipCard(item: HealthTip): void {
    Column() {
      Row() {
        Text(item.category)
          .fontSize(10)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(COLOR_ACCENT)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(8)
      }
      .width('100%')
      .margin({ bottom: 10 })
      
      Text(item.title)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLOR_TEXT_MAIN)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 6 })
      
      Text(item.content)
        .fontSize(13)
        .fontColor(COLOR_TEXT_SUB)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .lineHeight(19)
    }
    .width('100%')
    .height(140)
    .padding(16)
    .backgroundColor(COLOR_CARD_BG)
    .borderRadius(20)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.06)', offsetY: 4 })
  }
}

