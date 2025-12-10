/**
 * @file ExploreAIService.ets
 * @description Service to handle AI data generation and fetching
 */
import http from '@ohos.net.http';
import { ExploreData, ExploreConfig } from '../model/ExploreModels';
// Importing JSONs directly for prototype simplicity. 
// In a real app, these might be read from rawfile or preferences.
import userData from '../data/userData.json';
import configData from '../data/exploreConfig.json';

const STORAGE_KEY_EXPLORE_DATA = 'ExploreDataCache';

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
   * Get explore data. Checks cache first (valid for 1 day).
   * Force refresh can be requested.
   */
  public async getExploreData(forceRefresh: boolean = false): Promise<ExploreData> {
    // 1. Check Cache
    if (!forceRefresh) {
      const cachedStr = AppStorage.Get<string>(STORAGE_KEY_EXPLORE_DATA);
      if (cachedStr) {
        try {
          const cachedData: ExploreData = JSON.parse(cachedStr);
          const now = new Date().getTime();
          // Check if data is from today (simple check: same day)
          const dataDate = new Date(cachedData.generatedDate);
          const today = new Date();
          if (dataDate.getDate() === today.getDate() && 
              dataDate.getMonth() === today.getMonth() && 
              dataDate.getFullYear() === today.getFullYear()) {
            console.info('ExploreAIService: Returning cached data');
            return cachedData;
          }
        } catch (e) {
          console.error('ExploreAIService: Cache parse error', e);
        }
      }
    }

    // 2. Fetch New Data
    return this.fetchFromAI();
  }

  private async fetchFromAI(): Promise<ExploreData> {
    console.info('ExploreAIService: Fetching from AI...');
    
    // Check if API Key is set (Mock check)
    if (this.config.apiKey === "YOUR_API_KEY_HERE" || !this.config.apiKey) {
      console.warn('ExploreAIService: No API Key set, returning mock data.');
      return this.getMockData();
    }

    const userContext = userData.userContext;
    const prompt = `
      You are a health assistant. Based on the following user context, generate a daily health plan in JSON format.
      User Context: ${userContext}
      
      IMPORTANT: All text content (greeting, quotes, suggestions, etc.) MUST be in Chinese (Simplified).
      
      Return ONLY valid JSON matching this structure:
      {
        "greeting": "A short, encouraging greeting in Chinese",
        "dailyQuote": "A motivational quote in Chinese",
        "dietPlan": [
          {"mealType": "早餐", "suggestion": "...", "calories": 300, "tags": ["高蛋白"]},
          ...
        ],
        "exercisePlan": [
          {"activity": "...", "duration": "...", "intensity": "...", "benefits": "..."}
        ],
        "schedule": [
          {"time": "08:00", "activity": "...", "icon": "sun"},
          ...
        ],
        "healthTips": [
          {"title": "...", "content": "...", "category": "..."}
        ]
      }
    `;

    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        this.config.apiUrl,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.config.apiKey}`
          },
          extraData: {
            model: this.config.model,
            messages: [
              // { role: "system", content: "say hello" },
              { role: "system", content: "You are a helpful health assistant that outputs JSON.(简略生成）" },
              { role: "user", content: prompt }
            ],
            temperature: 0.7
          },
          readTimeout: 60000,
          connectTimeout: 10000
        }
      );

      if (response.responseCode === 200) {
        const result: OpenAIResponse = JSON.parse(response.result as string) as OpenAIResponse;
        const content: string = result.choices[0].message.content;
        // Clean up markdown code blocks if present
        const jsonStr: string = content.replace(/```json\n|\n```/g, "").trim();
        const data: ExploreData = JSON.parse(jsonStr) as ExploreData;
        data.generatedDate = new Date().getTime();
        
        // Cache it
        AppStorage.SetOrCreate(STORAGE_KEY_EXPLORE_DATA, JSON.stringify(data));
        return data;
      } else {
        throw new Error(`HTTP Error: ${response.responseCode}`);
      }
    } catch (error) {
      console.error('ExploreAIService: AI Request failed', error);
      // Fallback to mock data on error so the app doesn't crash
      return this.getMockData();
    }
  }

  private getMockData(): ExploreData {
    // Simulate network delay
    return {
      greeting: "早上好！准备好开启充满活力的一天了吗？",
      dailyQuote: "唯一的坏锻炼是那些没有发生的锻炼。",
      dietPlan: [
        { mealType: "早餐", suggestion: "燕麦粥配浆果和坚果", calories: 350, tags: ["高纤维", "能量"] },
        { mealType: "午餐", suggestion: "烤鸡肉沙拉配藜麦", calories: 500, tags: ["高蛋白", "轻食"] },
        { mealType: "晚餐", suggestion: "烤三文鱼配芦笋", calories: 450, tags: ["Omega-3", "低碳水"] }
      ],
      exercisePlan: [
        { activity: "晨间拉伸", duration: "10 分钟", intensity: "低", benefits: "唤醒肌肉" },
        { activity: "快走", duration: "30 分钟", intensity: "中", benefits: "心肺健康" }
      ],
      schedule: [
        { time: "07:00", activity: "起床 & 喝水", icon: "water" },
        { time: "07:30", activity: "晨间拉伸", icon: "accessibility" },
        { time: "12:30", activity: "健康午餐", icon: "restaurant" },
        { time: "22:00", activity: "放松 & 阅读", icon: "bed" }
      ],
      healthTips: [
        { title: "体态检查", content: "记得坐直。你的背部会感谢你的。", category: "体态" },
        { title: "补水", content: "每顿饭前喝一杯水。", category: "营养" }
      ],
      generatedDate: new Date().getTime()
    };
  }
}
