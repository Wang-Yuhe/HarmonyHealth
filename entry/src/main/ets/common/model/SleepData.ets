/**
 * @file SleepData.ets
 * @description 睡眠数据模型
 */

export class SleepData {
  id?: number;
  userId: number; // 用户ID
  date: string; // YYYY-MM-DD
  totalMinutes: number; // 总睡眠时长(分)
  deepSleepMinutes: number; // 深睡
  lightSleepMinutes: number; // 浅睡
  awakeMinutes: number; // 清醒

  constructor(date: string, total: number, deep: number, light: number, awake: number, userId: number = 0) {
    this.date = date;
    this.totalMinutes = total;
    this.deepSleepMinutes = deep;
    this.lightSleepMinutes = light;
    this.awakeMinutes = awake;
    this.userId = userId;
  }
}
