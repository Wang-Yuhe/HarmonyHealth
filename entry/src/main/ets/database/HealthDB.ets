/**
 * @file HealthDB.ets
 * @description 数据库核心操作类
 * @created 2025-12-03 09:12:10
 */

import relationalStore from '@ohos.data.relationalStore';
import { Context } from '@kit.AbilityKit';
import { User } from '../common/model/User';
import { HealthData } from '../common/model/HealthData';
import { SleepData } from '../common/model/SleepData';
import { CREATE_USER_TABLE, CREATE_HEALTH_TABLE, CREATE_SLEEP_TABLE } from './Migrations/InitMigration';

export class HealthDB {
  private static instance: HealthDB;
  private rdbStore: relationalStore.RdbStore | null = null;

  public static getInstance(): HealthDB {
    if (!HealthDB.instance) {
      HealthDB.instance = new HealthDB();
    }
    return HealthDB.instance;
  }

  async initDB(context: Context): Promise<void> {
    try {
      const config: relationalStore.StoreConfig = {
        name: 'HealthDB_v3.db', // 升级数据库名称以重置 Schema (支持多用户)
        securityLevel: relationalStore.SecurityLevel.S1,
      };
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      await this.rdbStore.executeSql(CREATE_USER_TABLE);
      await this.rdbStore.executeSql(CREATE_HEALTH_TABLE);
      await this.rdbStore.executeSql(CREATE_SLEEP_TABLE);
      
      // 注意：现在 initMockSleepData 需要传入 userId，所以这里不再自动调用
      // 而是由上层业务在登录后或页面加载时调用

    } catch (e) {
      console.error('initDB error:', e);
    }
  }

  // ==========================================
  // Sleep Data Operations
  // ==========================================

  public async initMockSleepData(userId: number) {
    try {
      if (userId <= 0) return;

      const today = new Date();
      const todayStr = today.toISOString().split('T')[0];
      
      // 检查今天是否有数据
      const hasData = await this.getSleepDataByDate(userId, todayStr);
      if (!hasData) {
        // 生成过去7天的数据
        for (let i = 6; i >= 0; i--) {
          const d = new Date();
          d.setDate(today.getDate() - i);
          const dateStr = d.toISOString().split('T')[0];
          
          // 随机生成睡眠数据 (6-9小时)
          const totalHours = 6 + Math.random() * 3;
          const totalMinutes = Math.floor(totalHours * 60);
          const deep = Math.floor(totalMinutes * (0.2 + Math.random() * 0.1)); // 20-30% 深睡
          const awake = Math.floor(Math.random() * 30); // 0-30分清醒
          const light = totalMinutes - deep - awake;

          const sleepData = new SleepData(dateStr, totalMinutes, deep, light, awake, userId);
          await this.insertSleepData(sleepData);
        }
      }
    } catch (e) {
      console.error('initMockSleepData error:', e);
    }
  }

  async insertSleepData(data: SleepData): Promise<number> {
    try {
      const value: relationalStore.ValuesBucket = {
        userId: data.userId,
        date: data.date,
        totalMinutes: data.totalMinutes,
        deepSleepMinutes: data.deepSleepMinutes,
        lightSleepMinutes: data.lightSleepMinutes,
        awakeMinutes: data.awakeMinutes
      };
      // 使用 REPLACE 策略，如果同一天已有数据则覆盖
      return await this.rdbStore!.insert('sleep_data', value, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    } catch (e) {
      console.error('insertSleepData error:', e);
      return -1;
    }
  }

  async getSleepDataByDate(userId: number, date: string): Promise<SleepData | null> {
    try {
      const predicates = new relationalStore.RdbPredicates('sleep_data');
      predicates.equalTo('userId', userId);
      predicates.equalTo('date', date);
      const result = await this.rdbStore!.query(predicates);
      if (result.goToFirstRow()) {
        return new SleepData(
          result.getString(result.getColumnIndex('date')),
          result.getLong(result.getColumnIndex('totalMinutes')),
          result.getLong(result.getColumnIndex('deepSleepMinutes')),
          result.getLong(result.getColumnIndex('lightSleepMinutes')),
          result.getLong(result.getColumnIndex('awakeMinutes')),
          result.getLong(result.getColumnIndex('userId'))
        );
      }
      return null;
    } catch (e) {
      console.error('getSleepDataByDate error:', e);
      return null;
    }
  }

  async getRecentSleepData(userId: number, limit: number = 7): Promise<SleepData[]> {
    try {
      const predicates = new relationalStore.RdbPredicates('sleep_data');
      predicates.equalTo('userId', userId);
      predicates.orderByDesc('date');
      predicates.limitAs(limit);
      
      const result = await this.rdbStore!.query(predicates);
      const list: SleepData[] = [];
      while (result.goToNextRow()) {
        list.push(new SleepData(
          result.getString(result.getColumnIndex('date')),
          result.getLong(result.getColumnIndex('totalMinutes')),
          result.getLong(result.getColumnIndex('deepSleepMinutes')),
          result.getLong(result.getColumnIndex('lightSleepMinutes')),
          result.getLong(result.getColumnIndex('awakeMinutes')),
          result.getLong(result.getColumnIndex('userId'))
        ));
      }
      return list.reverse();
    } catch (e) {
      console.error('getRecentSleepData error:', e);
      return [];
    }
  }

  // ==========================================
  // Health Data Operations
  // ==========================================

  async insertHealthData(data: HealthData): Promise<number> {
    try {
      const value: relationalStore.ValuesBucket = {
        userId: data.userId,
        timestamp: data.timestamp,
        heartRate: data.heartRate,
        steps: data.steps,
        calories: data.calories,
        bloodOxygen: data.bloodOxygen
      };
      return await this.rdbStore!.insert('health_data', value);
    } catch (e) {
      console.error('insertHealthData error:', e);
      return -1;
    }
  }

  async getLatestHealthData(userId: number): Promise<HealthData | null> {
    try {
      const predicates = new relationalStore.RdbPredicates('health_data');
      predicates.equalTo('userId', userId);
      predicates.orderByDesc('timestamp'); // 按时间倒序
      predicates.limitAs(1); // 取最新一条
      
      const result = await this.rdbStore!.query(predicates);
      if (result.goToFirstRow()) {
        const data = new HealthData(
          result.getLong(result.getColumnIndex('heartRate')),
          result.getLong(result.getColumnIndex('steps')),
          result.getLong(result.getColumnIndex('calories')),
          result.getLong(result.getColumnIndex('bloodOxygen')),
          result.getLong(result.getColumnIndex('userId'))
        );
        data.timestamp = result.getLong(result.getColumnIndex('timestamp'));
        return data;
      }
      return null;
    } catch (e) {
      console.error('getLatestHealthData error:', e);
      return null;
    }
  }

  /**
   * 获取最近N条健康数据用于图表展示
   * @param limit 条数
   */
  async getRecentHealthData(userId: number, limit: number = 7): Promise<HealthData[]> {
    try {
      const predicates = new relationalStore.RdbPredicates('health_data');
      predicates.equalTo('userId', userId);
      predicates.orderByDesc('timestamp');
      predicates.limitAs(limit);
      
      const result = await this.rdbStore!.query(predicates);
      const list: HealthData[] = [];
      while (result.goToNextRow()) {
        const data = new HealthData(
          result.getLong(result.getColumnIndex('heartRate')),
          result.getLong(result.getColumnIndex('steps')),
          result.getLong(result.getColumnIndex('calories')),
          result.getLong(result.getColumnIndex('bloodOxygen')),
          result.getLong(result.getColumnIndex('userId'))
        );
        data.timestamp = result.getLong(result.getColumnIndex('timestamp'));
        list.push(data);
      }
      // 数据库查出来是倒序的，反转一下变成时间正序，方便图表展示
      return list.reverse();
    } catch (e) {
      console.error('getRecentHealthData error:', e);
      return [];
    }
  }

  // ==========================================
  // User Operations
  // ==========================================

  async insertUser(user: User): Promise<number> {
    try {
      const value: relationalStore.ValuesBucket = {
        username: user.username,
        password: user.password,
        email: user.email,
        securityQuestion: user.securityQuestion,
        securityAnswer: user.securityAnswer
      };
      return await this.rdbStore!.insert('users', value);
    } catch (e) {
      console.error('insertUser error:', e);
      return -1;
    }
  }

  async getUserByUsername(username: string): Promise<User | null> {
    try {
      const predicates = new relationalStore.RdbPredicates('users');
      predicates.equalTo('username', username);
      const result = await this.rdbStore!.query(predicates, ['id', 'username', 'password', 'email', 'securityQuestion', 'securityAnswer', 'avatar']);
      if (result.goToFirstRow()) {
        const u = new User(
          result.getString(result.getColumnIndex('username')),
          result.getString(result.getColumnIndex('password')),
          result.getString(result.getColumnIndex('email')),
          result.getString(result.getColumnIndex('securityQuestion')),
          result.getString(result.getColumnIndex('securityAnswer'))
        );
        u.avatar=result.getString(result.getColumnIndex('avatar'))
        u.id = result.getLong(result.getColumnIndex('id'));
        return u;
      }
      return null;
    } catch (e) {
      console.error('getUserByUsername error:', e);
      return null;
    }
  }

  async deleteUser(username: string, password: string): Promise<boolean> {
    try {
      const user = await this.getUserByUsername(username);
      if (!user || user.password !== password) {
        return false;
      }
      const predicates = new relationalStore.RdbPredicates('users');
      predicates.equalTo('username', username);
      await this.rdbStore!.delete(predicates);
      return true;
    } catch (e) {
      console.error('deleteUser error:', e);
      return false;
    }
  }

  async updatePassword(username: string, newPassword: string): Promise<boolean> {
    try {
      const predicates = new relationalStore.RdbPredicates('users');
      predicates.equalTo('username', username);
      const value: relationalStore.ValuesBucket = { password: newPassword };
      const rows = await this.rdbStore!.update(value, predicates);
      return rows > 0;
    } catch (e) {
      console.error('updatePassword error:', e);
      return false;
    }
  }

  async setUserAvatar(username: string, avatarPath: string): Promise<boolean> {
    if (!this.rdbStore || !username || !avatarPath) {
      return false;
    }
    try {
      const predicates = new relationalStore.RdbPredicates('users');
      predicates.equalTo('username', username);
      const value: relationalStore.ValuesBucket = {
        avatar: avatarPath // 存储有效路径，如 file://...
      };
      const rows = await this.rdbStore.update(value, predicates);
      return rows > 0;
    } catch (e) {
      console.error('setUserAvatar error:', e);
      return false;
    }
  }

  // 删除（清空）用户头像
  async removeUserAvatar(username: string): Promise<boolean> {
    if (!this.rdbStore || !username) {
      return false;
    }
    try {
      const predicates = new relationalStore.RdbPredicates('users');
      predicates.equalTo('username', username);
      const value: relationalStore.ValuesBucket = {
        avatar: "" // 或设为 null，但你选择用 "" 表示无头像
      };
      const rows = await this.rdbStore.update(value, predicates);
      return rows > 0;
    } catch (e) {
      console.error('removeUserAvatar error:', e);
      return false;
    }
  }

}

