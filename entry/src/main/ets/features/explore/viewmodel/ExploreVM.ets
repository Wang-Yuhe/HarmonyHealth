/**
 * @file ExploreVM.ets
 * @description ViewModel for Explore Page
 */
import { ExploreAIService } from '../service/ExploreAIService';
import { GreetingData, DietData, ExerciseData, ScheduleData, HealthTipsData } from '../model/ExploreModels';

@Observed
export class ExploreVM {
  constructor() {
    // Data is prefetched in EntryAbility, but we can trigger again if needed
    // or just rely on AppStorage updates.
  }

  // Refresh methods
  public async refreshGreeting() {
    await ExploreAIService.getInstance().fetchGreeting(true);
  }

  public async refreshDiet() {
    await ExploreAIService.getInstance().fetchDiet(true);
  }

  public async refreshExercise() {
    await ExploreAIService.getInstance().fetchExercise(true);
  }

  public async refreshSchedule() {
    await ExploreAIService.getInstance().fetchSchedule(true);
  }

  public async refreshTips() {
    await ExploreAIService.getInstance().fetchTips(true);
  }

  public refreshAll() {
    this.refreshGreeting();
    this.refreshDiet();
    this.refreshExercise();
    this.refreshSchedule();
    this.refreshTips();
  }
}
