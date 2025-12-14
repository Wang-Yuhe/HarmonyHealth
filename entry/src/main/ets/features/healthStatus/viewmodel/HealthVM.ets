/**
 * @file HealthVM.ets
 * @description 健康状态页面 ViewModel
 * @created 2025-12-03 09:12:10
 */

import { HealthData } from '../../../common/model/HealthData';
import { DeviceService } from '../../device/service/DeviceService';
import { HealthDB } from '../../../database/HealthDB';

export class HealthVM {
  private deviceService: DeviceService = new DeviceService();
  private timerId: number = -1;

  /**
   * 获取单次数据
   */
  async fetchData(): Promise<HealthData> {
    return await this.deviceService.getRealTimeData();
  }

  /**
   * 从数据库加载最后一次记录
   */
  async loadLastData(): Promise<HealthData | null> {
    return await HealthDB.getInstance().getLatestHealthData();
  }

  /**
   * 开启自动更新
   * @param intervalMs 更新间隔(毫秒)
   * @param callback 数据回调
   */
  startMonitoring(intervalMs: number, callback: (data: HealthData) => void) {
    this.stopMonitoring(); // 防止重复开启
    
    // 立即执行一次
    this.deviceService.getRealTimeData().then(data => {
      this.saveData(data);
      callback(data);
    });

    // 开启定时器
    this.timerId = setInterval(async () => {
      const data = await this.deviceService.getRealTimeData();
      this.saveData(data);
      callback(data);
    }, intervalMs);
  }

  private async saveData(data: HealthData) {
    await HealthDB.getInstance().insertHealthData(data);
  }

  /**
   * 停止更新
   */
  stopMonitoring() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }
}