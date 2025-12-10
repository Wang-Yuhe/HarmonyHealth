/**
 * @file ExploreModels.ets
 * @description Data models for the Explore feature
 */

export interface DietRecommendation {
  mealType: string; // Breakfast, Lunch, Dinner, Snack
  suggestion: string;
  calories: number;
  tags: string[]; // e.g., "High Protein", "Quick"
}

export interface ExerciseRecommendation {
  activity: string;
  duration: string; // e.g., "30 mins"
  intensity: string; // Low, Medium, High
  benefits: string;
}

export interface DailySchedule {
  time: string;
  activity: string;
  icon?: string; // Optional icon name
}

export interface HealthTip {
  title: string;
  content: string;
  category: string; // e.g., "Sleep", "Posture", "Mental"
}

// Separate interfaces for granular loading
export interface GreetingData {
  greeting: string;
  dailyQuote: string;
}

export interface DietData {
  dietPlan: DietRecommendation[];
}

export interface ExerciseData {
  exercisePlan: ExerciseRecommendation[];
}

export interface ScheduleData {
  schedule: DailySchedule[];
}

export interface HealthTipsData {
  healthTips: HealthTip[];
}

export interface ExploreData {
  greetingData?: GreetingData;
  dietData?: DietData;
  exerciseData?: ExerciseData;
  scheduleData?: ScheduleData;
  healthTipsData?: HealthTipsData;
  generatedDate: number; // Timestamp
}

export class ExploreConfig {
  apiUrl: string = "";
  apiKey: string = "";
  model: string = "";
}
