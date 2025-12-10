/**
 * @file ExploreAIService.ets
 * @description Service to handle AI data generation and fetching
 */
import http from '@ohos.net.http';
import { ExploreData, ExploreConfig, GreetingData, DietData, ExerciseData, ScheduleData, HealthTipsData } from '../model/ExploreModels';
// Importing JSONs directly for prototype simplicity. 
// In a real app, these might be read from rawfile or preferences.
import userData from '../data/userData.json';
import configData from '../data/exploreConfig.json';

const STORAGE_KEY_GREETING = 'Explore_Greeting';
const STORAGE_KEY_DIET = 'Explore_Diet';
const STORAGE_KEY_EXERCISE = 'Explore_Exercise';
const STORAGE_KEY_SCHEDULE = 'Explore_Schedule';
const STORAGE_KEY_TIPS = 'Explore_Tips';

// Define interfaces for API response to avoid "any" types
interface OpenAIMessage {
  role: string;
  content: string;
}

interface OpenAIChoice {
  message: OpenAIMessage;
}

interface OpenAIResponse {
  choices: OpenAIChoice[];
}

interface OpenAIRequest {
  model: string;
  messages: OpenAIMessage[];
  temperature: number;
}

export class ExploreAIService {
  private static instance: ExploreAIService;
  private config: ExploreConfig;

  private constructor() {
    this.config = {
      apiUrl: configData.apiUrl,
      apiKey: configData.apiKey,
      model: configData.model
    };
  }

  public static getInstance(): ExploreAIService {
    if (!ExploreAIService.instance) {
      ExploreAIService.instance = new ExploreAIService();
    }
    return ExploreAIService.instance;
  }

  /**
   * Prefetch all data in parallel.
   * Should be called on app startup.
   */
  public prefetchAll() {
    this.fetchGreeting();
    this.fetchDiet();
    this.fetchExercise();
    this.fetchSchedule();
    this.fetchTips();
  }

  // --- Individual Fetch Methods ---

  public async fetchGreeting(forceRefresh: boolean = false): Promise<void> {
    await this.fetchSection<GreetingData>(
      STORAGE_KEY_GREETING,
      forceRefresh,
      `
      Generate a greeting and a daily quote for a health app user.
      User Context: ${userData.userContext}
      Output JSON: { "greeting": "...", "dailyQuote": "..." }
      Language: Simplified Chinese.
      `
    );
  }

  public async fetchDiet(forceRefresh: boolean = false): Promise<void> {
    await this.fetchSection<DietData>(
      STORAGE_KEY_DIET,
      forceRefresh,
      `
      Generate a daily diet plan.
      User Context: ${userData.userContext}
      Output JSON: { "dietPlan": [ { "mealType": "...", "suggestion": "...", "calories": 0, "tags": ["..."] } ] }
      Language: Simplified Chinese.
      `
    );
  }

  public async fetchExercise(forceRefresh: boolean = false): Promise<void> {
    await this.fetchSection<ExerciseData>(
      STORAGE_KEY_EXERCISE,
      forceRefresh,
      `
      Generate a daily exercise plan.
      User Context: ${userData.userContext}
      Output JSON: { "exercisePlan": [ { "activity": "...", "duration": "...", "intensity": "...", "benefits": "..." } ] }
      Language: Simplified Chinese.
      `
    );
  }

  public async fetchSchedule(forceRefresh: boolean = false): Promise<void> {
    await this.fetchSection<ScheduleData>(
      STORAGE_KEY_SCHEDULE,
      forceRefresh,
      `
      Generate a daily health schedule.
      User Context: ${userData.userContext}
      Output JSON: { "schedule": [ { "time": "HH:mm", "activity": "...", "icon": "sun/moon/water/food" } ] }
      Language: Simplified Chinese.
      `
    );
  }

  public async fetchTips(forceRefresh: boolean = false): Promise<void> {
    await this.fetchSection<HealthTipsData>(
      STORAGE_KEY_TIPS,
      forceRefresh,
      `
      Generate 2-3 health tips.
      User Context: ${userData.userContext}
      Output JSON: { "healthTips": [ { "title": "...", "content": "...", "category": "..." } ] }
      Language: Simplified Chinese.
      `
    );
  }

  // --- Generic Fetch Logic ---

  private async fetchSection<T>(storageKey: string, forceRefresh: boolean, prompt: string): Promise<void> {
    const loadingKey = `${storageKey}_Loading`;
    AppStorage.SetOrCreate(loadingKey, true);

    try {
      // 1. Check Cache
      if (!forceRefresh) {
        const cachedStr = AppStorage.Get<string>(storageKey);
        if (cachedStr) {
          // Simple check: if data exists, assume it's valid for today (simplification)
          // In a real app, you'd store a timestamp wrapper.
          console.info(`ExploreAIService: Cache hit for ${storageKey}`);
          return;
        }
      }

      // 2. Fetch from AI
      console.info(`ExploreAIService: Fetching ${storageKey}...`);
      
      if (this.config.apiKey === "YOUR_API_KEY_HERE" || !this.config.apiKey) {
        console.warn('ExploreAIService: No API Key, using mock.');
        // For simplicity, we won't implement granular mocks here, just skip or use a big mock if needed.
        // But to support the user's request, let's just return empty or handle it gracefully.
        return; 
      }

      const httpRequest = http.createHttp();
      const requestBody: OpenAIRequest = {
        model: this.config.model,
        messages: [
          { role: "system", content: "You are a helpful health assistant that outputs JSON." },
          { role: "user", content: prompt }
        ],
        temperature: 0.7
      };

      const response = await httpRequest.request(
        this.config.apiUrl,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.config.apiKey}`
          },
          extraData: JSON.stringify(requestBody),
          readTimeout: 60000,
          connectTimeout: 60000
        }
      );

      if (response.responseCode === 200) {
        const result: OpenAIResponse = JSON.parse(response.result as string) as OpenAIResponse;
        const content: string = result.choices[0].message.content;
        const jsonStr: string = content.replace(/```json\n|\n```/g, "").trim();
        // Validate JSON by parsing
        const data: object = JSON.parse(jsonStr) as object;
        
        // Save to AppStorage
        AppStorage.SetOrCreate(storageKey, JSON.stringify(data));
      } else {
        console.error(`ExploreAIService: HTTP Error ${response.responseCode} for ${storageKey}`);
      }
    } catch (error) {
      console.error(`ExploreAIService: Request failed for ${storageKey}`, error);
    } finally {
      AppStorage.SetOrCreate(loadingKey, false);
    }
  }
}
