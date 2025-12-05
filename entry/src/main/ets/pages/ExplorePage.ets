/**
 * @file ExplorePage.ets
 * @description 探索页面
 */
import { myNavigator } from '../common/components/Navigator';

// 步骤1: 定义数据结构 (直接添加在文件中)
interface RecommendItem {
  id: number;
  title: string;
  description: string;
  icon: Resource; // 图标资源
}

@Entry
@Component
struct ExplorePage {
  // 步骤2: 创建推荐数据源
  private recommendList: RecommendItem[] = [
    {
      id: 1,
      title: '健康科普',
      description: '基于健康状态的科普知识推送',
      icon: $r('app.media.startIcon') // 需要添加对应资源
    },
    {
      id: 2,
      title: '饮食建议',
      description: '个性化营养膳食方案',
      icon: $r('app.media.startIcon')
    },
    {
      id: 3,
      title: '运动计划',
      description: '科学运动方案定制',
      icon: $r('app.media.startIcon')
    },
    {
      id: 4,
      title: '生活习惯',
      description: '健康生活方式指导',
      icon: $r('app.media.startIcon')
    }
  ];

  build() {
    Stack() {
      // 主内容区域 - 修改为列表展示
      List({ space: 10 }) {
        ForEach(this.recommendList, (item: RecommendItem) => {
          ListItem() {
            this.RecommendCard(item) // 使用自定义卡片组件
          }
        }, (item: RecommendItem) => item.id.toString())
      }
      .width('100%')
      .height('100%')
      .padding(10)

      // 底部导航栏
      myNavigator()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // 步骤3: 创建自定义列表项组件
  @Builder
  RecommendCard(item: RecommendItem) {
    Row() {
      Image(item.icon)
        .width(50)
        .height(50)
        .margin({ right: 15 })

      Column() {
        Text(item.title)
          .fontSize(18)
          .fontColor('#000000')
          .fontWeight(FontWeight.Bold)

        Text(item.description)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 5 })
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 6, color: '#20000000' })
  }
}
