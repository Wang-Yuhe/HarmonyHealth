/**
 * @file ExplorePage.ets
 * @description 探索页面 - Wrapper for the Explore Feature
 */
import { myNavigator } from '../common/components/Navigator';
import { ExploreView } from '../features/explore/view/ExploreView';

@Entry
@Component
struct ExplorePage {
  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // Main Content
      Column() {
        ExploreView()
      }
      .width('100%')
      .height('100%')
      // Add padding to avoid content being covered by the navigator
      .padding({ bottom: 56 }) 

      // Bottom Navigation
      myNavigator()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }
}
