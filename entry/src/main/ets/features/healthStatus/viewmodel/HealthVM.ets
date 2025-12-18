/**
 * @file HealthVM.ets
 * @description 健康状态页面 ViewModel
 * @created 2025-12-03 09:12:10
 */

import { HealthData } from '../../../common/model/HealthData';
import { DeviceService } from '../../device/service/DeviceService';
import { HealthDB } from '../../../database/HealthDB';
import { AuthUtil } from '../../../common/utils/AuthUtil';
import { Context } from '@kit.AbilityKit';

export class HealthVM {
  private deviceService: DeviceService = DeviceService.getInstance();
  private timerId: number = -1;
  private currentUserId: number = 0;

  /**
   * 获取单次数据
   */
  async fetchData(): Promise<HealthData> {
    return await this.deviceService.getRealTimeData(this.currentUserId);
  }

  /**
   * 从数据库加载最后一次记录
   */
  async loadLastData(context: Context): Promise<HealthData | null> {
    const user = await AuthUtil.getLoginUser(context);
    if (user) {
      this.currentUserId = user.id;
      return await HealthDB.getInstance().getLatestHealthData(this.currentUserId);
    }
    return null;
  }

  /**
   * 开启自动更新
   * @param intervalMs 更新间隔(毫秒)
   * @param callback 数据回调
   */
  async startMonitoring(context: Context, intervalMs: number, callback: (data: HealthData) => void) {
    this.stopMonitoring(); // 防止重复开启
    
    const user = await AuthUtil.getLoginUser(context);
    if (user) {
      // 如果切换了用户，或者这是第一次加载，我们需要同步设备的数据状态
      if (this.currentUserId !== user.id) {
        this.currentUserId = user.id;
        await this.syncDeviceState(this.currentUserId);
      }
    } else {
      console.warn('HealthVM: No user logged in, monitoring disabled');
      return;
    }

    // 立即执行一次
    this.deviceService.getRealTimeData(this.currentUserId).then(data => {
      data.userId = this.currentUserId; // 关联用户ID
      this.saveData(data);
      callback(data);
    });

    // 开启定时器
    this.timerId = setInterval(async () => {
      const data = await this.deviceService.getRealTimeData(this.currentUserId);
      data.userId = this.currentUserId; // 关联用户ID
      this.saveData(data);
      callback(data);
    }, intervalMs);
  }

  private async saveData(data: HealthData) {
    if (data.userId > 0) {
      await HealthDB.getInstance().insertHealthData(data);
    }
  }

  /**
   * 同步设备状态与数据库记录
   * 确保切换用户时，步数从该用户的最后记录开始（如果是同一天）
   */
  private async syncDeviceState(userId: number) {
    const lastData = await HealthDB.getInstance().getLatestHealthData(userId);
    if (lastData) {
      const lastDate = new Date(lastData.timestamp);
      const today = new Date();
      
      // 检查是否是同一天
      if (lastDate.getFullYear() === today.getFullYear() &&
          lastDate.getMonth() === today.getMonth() &&
          lastDate.getDate() === today.getDate()) {
        // 是今天的数据，恢复步数和卡路里
        this.deviceService.setMockData(userId, lastData.steps, lastData.calories);
        console.info(`HealthVM: Restored steps=${lastData.steps} for user=${userId}`);
      } else {
        // 不是今天的数据，重置为0
        this.deviceService.setMockData(userId, 0, 0);
        console.info(`HealthVM: Reset steps to 0 for user=${userId} (New Day)`);
      }
    } else {
      // 无记录，重置为0
      this.deviceService.setMockData(userId, 0, 0);
      console.info(`HealthVM: Reset steps to 0 for user=${userId} (No Data)`);
    }
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