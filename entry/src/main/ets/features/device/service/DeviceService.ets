/**
 * @file DeviceService.ets
 * @description 设备连接/数据读取服务
 * @created 2025-12-03 09:12:10
 */

import { HealthData } from '../../../common/model/HealthData';

export class DeviceService {
  private static instance: DeviceService;

  public static getInstance(): DeviceService {
    if (!DeviceService.instance) {
      DeviceService.instance = new DeviceService();
    }
    return DeviceService.instance;
  }

  // 使用 Map 存储不同用户的模拟数据状态
  private userSteps: Map<number, number> = new Map();
  private userCalories: Map<number, number> = new Map();

  /**
   * 获取实时健康数据
   * 目前使用模拟数据
   * @param userId 当前用户ID，用于区分不同用户的模拟数据
   */
  async getRealTimeData(userId: number): Promise<HealthData> {
    return new Promise((resolve) => {
      // 模拟网络/蓝牙延迟
      setTimeout(() => {
        // 获取该用户的当前步数，如果不存在则初始化为 0
        let steps = this.userSteps.get(userId) || 0;
        let calories = this.userCalories.get(userId) || 0;

        // 模拟数据变化
        steps += Math.floor(Math.random() * 10);
        calories += Math.floor(Math.random() * 2);
        
        // 更新 Map
        this.userSteps.set(userId, steps);
        this.userCalories.set(userId, calories);
        
        // 生成随机心率 (60-100) 和血氧 (95-100)
        const heartRate = 60 + Math.floor(Math.random() * 40);
        const bloodOxygen = 95 + Math.floor(Math.random() * 5);

        const data = new HealthData(
          heartRate,
          steps,
          calories,
          bloodOxygen
        );
        // 确保返回的数据包含 userId
        data.userId = userId;
        
        resolve(data);
      }, 500);
    });
  }


  /**
   * 检查设备连接状态
   */
  async checkConnection(): Promise<boolean> {
    // 模拟设备已连接
    return true;
  }

  /**
   * 更新模拟数据的当前状态（用于切换用户时重置或恢复数据）
   */
  public setMockData(userId: number, steps: number, calories: number) {
    this.userSteps.set(userId, steps);
    this.userCalories.set(userId, calories);
  }
}