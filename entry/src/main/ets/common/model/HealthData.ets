/**
 * @file HealthData.ets
 * @description 健康数据模型（如心率/步数等）
 * @created 2025-12-03 09:12:10
 */

@Observed
export class HealthData {
  heartRate: number = 0;      // 心率 (bpm)
  steps: number = 0;          // 步数
  calories: number = 0;       // 卡路里 (kcal)
  bloodOxygen: number = 0;    // 血氧 (%)
  timestamp: number = 0;      // 时间戳

  constructor(heartRate: number, steps: number, calories: number, bloodOxygen: number) {
    this.heartRate = heartRate;
    this.steps = steps;
    this.calories = calories;
    this.bloodOxygen = bloodOxygen;
    this.timestamp = new Date().getTime();
  }
}