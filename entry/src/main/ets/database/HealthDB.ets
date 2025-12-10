/**
 * @file HealthDB.ets
 * @description 数据库核心操作类
 * @created 2025-12-03 09:12:10
 */

import relationalStore from '@ohos.data.relationalStore';
import { Context } from '@kit.AbilityKit';
import { User } from '../common/model/User';
import { HealthData } from '../common/model/HealthData';
import { CREATE_USER_TABLE, CREATE_HEALTH_TABLE } from './Migrations/InitMigration';

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
        name: 'HealthDB.db',
        securityLevel: relationalStore.SecurityLevel.S1,
      };
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      await this.rdbStore.executeSql(CREATE_USER_TABLE);
      await this.rdbStore.executeSql(CREATE_HEALTH_TABLE);
      
      /* 默认账号 admin/123456，仅首次 */
      const hasAdmin = await this.getUserByUsername('admin');
      if (!hasAdmin) {
        const v: relationalStore.ValuesBucket = {
          username: 'admin',
          password: '123456',
          email: 'admin@example.com',
          securityQuestion: '您的出生地是？',
          securityAnswer: '北京'
        };
        await this.rdbStore.insert('users', v);
      }
    } catch (e) {
      console.error('initDB error:', e);
    }
  }

  // ==========================================
  // Health Data Operations
  // ==========================================

  async insertHealthData(data: HealthData): Promise<number> {
    try {
      const value: relationalStore.ValuesBucket = {
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

  async getLatestHealthData(): Promise<HealthData | null> {
    try {
      const predicates = new relationalStore.RdbPredicates('health_data');
      predicates.orderByDesc('timestamp'); // 按时间倒序
      predicates.limitAs(1); // 取最新一条
      
      const result = await this.rdbStore!.query(predicates);
      if (result.goToFirstRow()) {
        const data = new HealthData(
          result.getLong(result.getColumnIndex('heartRate')),
          result.getLong(result.getColumnIndex('steps')),
          result.getLong(result.getColumnIndex('calories')),
          result.getLong(result.getColumnIndex('bloodOxygen'))
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
      const result = await this.rdbStore!.query(predicates, ['id', 'username', 'password', 'email', 'securityQuestion', 'securityAnswer']);
      if (result.goToFirstRow()) {
        const u = new User(
          result.getString(result.getColumnIndex('username')),
          result.getString(result.getColumnIndex('password')),
          result.getString(result.getColumnIndex('email')),
          result.getString(result.getColumnIndex('securityQuestion')),
          result.getString(result.getColumnIndex('securityAnswer'))
        );
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
}