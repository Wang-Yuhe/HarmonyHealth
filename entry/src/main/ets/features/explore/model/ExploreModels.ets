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

export interface ExploreData {
  greeting: string;
  dailyQuote: string;
  dietPlan: DietRecommendation[];
  exercisePlan: ExerciseRecommendation[];
  schedule: DailySchedule[];
  healthTips: HealthTip[];
  generatedDate: number; // Timestamp
}

export class ExploreConfig {
  apiUrl: string = "";
  apiKey: string = "";
  model: string = "";
}
