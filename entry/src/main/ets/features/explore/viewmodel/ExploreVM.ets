/**
 * @file ExploreVM.ets
 * @description ViewModel for Explore Page
 */
import { ExploreAIService } from '../service/ExploreAIService';
import { ExploreData } from '../model/ExploreModels';

@Observed
export class ExploreVM {
  public exploreData: ExploreData | null = null;
  public isLoading: boolean = false;
  public isError: boolean = false;

  constructor() {
    this.loadData();
  }

  public async loadData(forceRefresh: boolean = false) {
    this.isLoading = true;
    this.isError = false;
    try {
      const service = ExploreAIService.getInstance();
      this.exploreData = await service.getExploreData(forceRefresh);
    } catch (e) {
      console.error("ExploreVM: Failed to load data", e);
      this.isError = true;
    } finally {
      this.isLoading = false;
    }
  }
}
