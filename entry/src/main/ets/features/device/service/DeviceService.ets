/**
 * @file DeviceService.ets
 * @description 设备连接/数据读取服务
 * @created 2025-12-03 09:12:10
 */

import { HealthData } from '../../../common/model/HealthData';

export class DeviceService {
  // 模拟当前步数累加
  private currentSteps: number = 1000;
  private currentCalories: number = 50;

  /**
   * 获取实时健康数据
   * 目前使用模拟数据
   */
  async getRealTimeData(): Promise<HealthData> {
    return new Promise((resolve) => {
      // 模拟网络/蓝牙延迟
      setTimeout(() => {
        // 模拟数据变化
        this.currentSteps += Math.floor(Math.random() * 10);
        this.currentCalories += Math.floor(Math.random() * 2);
        
        // 生成随机心率 (60-100) 和血氧 (95-100)
        const heartRate = 60 + Math.floor(Math.random() * 40);
        const bloodOxygen = 95 + Math.floor(Math.random() * 5);

        const data = new HealthData(
          heartRate,
          this.currentSteps,
          this.currentCalories,
          bloodOxygen
        );
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
}