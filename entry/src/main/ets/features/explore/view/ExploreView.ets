/**
 * @file ExploreView.ets
 * @description Main View for the Explore Feature with Vibrant Background
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
// 基础背景色改为纯白，让上面的彩色光晕更通透
const COLOR_BG_BASE = '#FFFFFF';
const COLOR_PRIMARY = '#4A90E2'; // Bright Blue
const COLOR_ACCENT = '#FF6B6B'; // Soft Red
const COLOR_PURPLE = '#6C5CE7'; // Soft Purple
const COLOR_SUCCESS = '#2ECC71'; // Green
const COLOR_TEXT_MAIN = '#1A2A3A';
const COLOR_TEXT_SUB = '#7F8C8D';

// 卡片背景调整为半透明白色，以透出背景色
const CARD_BG_COLOR = 'rgba(255, 255, 255, 0.85)';

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
    // 根容器使用 Stack 叠加层级
    Stack({ alignContent: Alignment.TopStart }) {

      // --- 层级 1: 鲜艳的弥散背景 ---
      this.BackgroundDecorations()

      // --- 层级 2: 页面主要内容 ---
      Column() {
        // 顶部标题栏
        Row() {
          Text("发现")
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLOR_TEXT_MAIN)

          Blank()

          Button({ type: ButtonType.Circle, stateEffect: true }) {
            Image($r('app.media.update'))
              .width(22)
              .height(22)
              .fillColor(Color.White)
          }
          .width(44)
          .height(44)
          .backgroundColor(COLOR_PRIMARY)
          .shadow({ radius: 8, color: 'rgba(74, 144, 226, 0.4)', offsetY: 4 })
          .onClick(() => {
            this.vm.refreshAll();
          })
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 16, bottom: 10 })
        .zIndex(2)

        Scroll() {
          Column({ space: 24 }) {
            // 1. Banner 轮播图
            this.BannerSwiper()

            // 2. 问候语
            if (this.isGreetingLoading) {
              this.SectionLoading()
            } else if (this.getGreetingData()) {
              this.GreetingSection(this.getGreetingData()!)
            } else {
              this.SectionError(() => { this.vm.refreshGreeting() })
            }

            // 3. 营养计划
            Column() {
              Row() {
                this.SectionHeader("营养计划")
                Blank()
                this.RefreshIcon(() => { this.vm.refreshDiet() }, this.isDietLoading)
              }.width('100%').padding({ right: 24 })

              if (this.isDietLoading) {
                this.SectionLoading()
              } else if (this.getDietData()) {
                List({ space: 16 }) {
                  ForEach(this.getDietData()!.dietPlan, (item: DietRecommendation) => {
                    ListItem() {
                      this.DietCard(item)
                    }
                  })
                }
                .listDirection(Axis.Horizontal)
                .width('100%')
                .height(190)
                .scrollBar(BarState.Off)
                .edgeEffect(EdgeEffect.Spring)
                .padding({ left: 24, right: 24, bottom: 10 })
              } else {
                this.SectionError(() => { this.vm.refreshDiet() })
              }
            }

            // 4. 运动建议
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
                .height(170)
                .scrollBar(BarState.Off)
                .edgeEffect(EdgeEffect.Spring)
                .padding({ left: 24, right: 24, bottom: 10 })
              } else {
                this.SectionError(() => { this.vm.refreshExercise() })
              }
            }

            // 5. 每日流程
            Column() {
              Row() {
                this.SectionHeader("每日流程")
                Blank()
                this.RefreshIcon(() => { this.vm.refreshSchedule() }, this.isScheduleLoading)
              }.width('100%').padding({ right: 24 })

              if (this.isScheduleLoading) {
                this.SectionLoading()
              } else if (this.getScheduleData()) {
                Column({ space: 0 }) {
                  ForEach(this.getScheduleData()!.schedule, (item: DailySchedule, index: number) => {
                    this.ScheduleItem(item, index === this.getScheduleData()!.schedule.length - 1)
                  })
                }
                .padding({ left: 24, right: 24 })
                .backgroundColor(CARD_BG_COLOR) // 使用半透明背景
                .backdropBlur(10) // 开启背景模糊，增强玻璃质感
                .borderRadius(24)
                .margin({ left: 24, right: 24 })
                .padding({ top: 24, bottom: 24 })
                .shadow({ radius: 15, color: 'rgba(0,0,0,0.05)', offsetY: 8 })
              } else {
                this.SectionError(() => { this.vm.refreshSchedule() })
              }
            }

            // 6. 健康小贴士
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
                .height(240)
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
    }
  }

  /**
   * 背景装饰层 - 增强版
   * 颜色更深，位置更显著
   */
  @Builder
  BackgroundDecorations(): void {
    Stack() {
      // 1. 左上角 - 深蓝色 (主色调)
      Circle({ width: 350, height: 350 })
        .fill('rgba(74, 144, 226, 0.4)') // Opacity 提高到 0.4
        .position({ x: -100, y: -100 })
        .blur(80) // 保持高模糊以融合

      // 2. 右上角 - 亮紫色 (对比色)
      Circle({ width: 320, height: 320 })
        .fill('rgba(108, 92, 231, 0.4)') // Opacity 提高到 0.4
        .position({ x: '50%', y: -80 })
        .blur(70)

      // 3. 左下/中部 - 暖红色 (活力点缀)
      Circle({ width: 380, height: 380 })
        .fill('rgba(255, 107, 107, 0.25)') // 稍微淡一点，因为红色很抢眼
        .position({ x: -120, y: '35%' })
        .blur(90)

      // 4. 右下角 - 清新绿 (平衡视觉)
      Circle({ width: 250, height: 250 })
        .fill('rgba(46, 204, 113, 0.2)')
        .position({ x: '60%', y: '80%' })
        .blur(60)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLOR_BG_BASE)
  }

  @Builder
  SectionHeader(title: string): void {
    Row() {
      Column()
        .width(6)
        .height(22)
        .backgroundColor(COLOR_PRIMARY)
        .borderRadius(3)
        .margin({ right: 10 })
        .shadow({ radius: 4, color: 'rgba(74, 144, 226, 0.4)', offsetX: 2 })

      Text(title)
        .fontSize(22)
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
    .height(200)
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
    .shadow({ radius: 20, color: 'rgba(0,0,0,0.12)', offsetY: 10 })
  }

  @Builder
  BannerItem(imagePath: string): void {
    Stack() {
      Image($rawfile(`explore_pictures/${imagePath}`))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
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
      Image($r('app.media.update'))
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
      Column() {
        Text(data.greeting)
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .width('100%')
          .margin({ bottom: 20 })

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
        .backgroundColor('rgba(255, 255, 255, 0.2)')
        .borderRadius(16)
        .padding(20)
        .backdropBlur(20)
      }
      .width('100%')
      .linearGradient({
        angle: 135,
        colors: [[COLOR_PRIMARY, 0.0], [COLOR_PURPLE, 1.0]]
      })
      .borderRadius(28)
      .padding(24)
      .shadow({ radius: 20, color: 'rgba(74, 144, 226, 0.4)', offsetY: 10 })
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
        ForEach(item.tags.slice(0, 2), (tag: string) => {
          Text(tag)
            .fontSize(10)
            .fontColor(COLOR_SUCCESS)
            .backgroundColor('rgba(46, 204, 113, 0.1)')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(6)
        })
      }
    }
    .width(230)
    .height('100%')
    .padding(18)
    .backgroundColor(CARD_BG_COLOR) // 半透明
    .backdropBlur(10) // 模糊
    .borderRadius(24)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.05)', offsetY: 6 })
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
        Image($r('app.media.startIcon'))
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
          .fontColor(item.intensity === 'High' ? COLOR_ACCENT : COLOR_SUCCESS)
          .backgroundColor(item.intensity === 'High' ? 'rgba(255, 107, 107, 0.1)' : 'rgba(46, 204, 113, 0.1)')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(8)
      }
      .width('100%')
    }
    .width(180)
    .height('100%')
    .padding(18)
    .backgroundColor(CARD_BG_COLOR) // 半透明
    .backdropBlur(10) // 模糊
    .borderRadius(24)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.05)', offsetY: 6 })
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
        Circle({ width: 12, height: 12 })
          .fill(COLOR_PRIMARY)
          .shadow({ radius: 4, color: 'rgba(74, 144, 226, 0.4)', offsetY: 2 })

        if (!isLast) {
          Column()
            .width(2)
            .height(40)
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
          .margin({ bottom: isLast ? 0 : 28 })
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
    .backgroundColor(CARD_BG_COLOR) // 半透明
    .backdropBlur(10) // 模糊
    .borderRadius(20)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.06)', offsetY: 4 })
  }
}