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
import { CREATE_USER_TABLE, CREATE_HEALTH_TABLE, CREATE_SLEEP_TABLE,
  CREATE_MEDICAL_TABLE,
  CREATE_BODY_INFO_TABLE,
  DROP_BODY_INFO_TABLE} from './Migrations/InitMigration';
import { MedicalRecord } from '../common/model/MedicalRecordModel';
import { BodyInfoItem } from '../common/model/BodyInfoItem';
import { it } from '@ohos/hypium';
import List from '@ohos.util.List';

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
        name: 'HealthDB_v5.db',
        securityLevel: relationalStore.SecurityLevel.S1,
      };
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      await this.rdbStore.executeSql(CREATE_USER_TABLE);
      await this.rdbStore.executeSql(CREATE_HEALTH_TABLE);
      await this.rdbStore.executeSql(CREATE_SLEEP_TABLE);
      await this.rdbStore.executeSql(CREATE_MEDICAL_TABLE);
      await this.rdbStore.executeSql(CREATE_BODY_INFO_TABLE);
      
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

  /**
   * 为无设备连接的情况生成过去若干天的模拟步数数据（不包含今天）
   */
  public async initMockHealthData(userId: number, days: number = 7): Promise<void> {
    if (!this.rdbStore || userId <= 0) {
      return;
    }
    try {
      const oneDay = 24 * 60 * 60 * 1000;
      const today = new Date();
      today.setHours(0, 0, 0, 0); // 今天 00:00

      // 只生成“今天之前”的 days 天
      for (let i = 1; i <= days; i++) {
        const day = new Date(today.getTime() - i * oneDay); // 往前推 i 天
        const start = new Date(day.getTime());
        start.setHours(0, 0, 0, 0);
        const end = new Date(day.getTime());
        end.setHours(23, 59, 59, 999);

        // 该用户这一天已有记录就跳过，避免覆盖真实数据
        const predicates = new relationalStore.RdbPredicates('health_data');
        predicates.equalTo('userId', userId);
        predicates.greaterThanOrEqualTo('timestamp', start.getTime());
        predicates.lessThanOrEqualTo('timestamp', end.getTime());
        const result = await this.rdbStore.query(predicates);
        const hasRow = result.goToFirstRow();
        result.close();
        if (hasRow) {
          continue;
        }

        // 随机生成比较合理的“当日总步数”：3000 ~ 10000
        const steps = 3000 + Math.floor(Math.random() * 7000);
        // 粗略估算当日步行消耗
        const calories = Math.round(steps * (0.035 + Math.random() * 0.01));
        const heartRate = 65 + Math.floor(Math.random() * 10);
        const bloodOxygen = 96 + Math.floor(Math.random() * 3);

        const data = new HealthData(heartRate, steps, calories, bloodOxygen, userId);
        // 固定在当天 23:00，方便按天汇总
        const ts = new Date(day.getTime());
        ts.setHours(23, 0, 0, 0);
        data.timestamp = ts.getTime();

        await this.insertHealthData(data);
      }
    } catch (e) {
      console.error('initMockHealthData error:', e);
    }
  }

  /**
   * 按天汇总最近 N 天的步数/热量
   * 每天取该日记录中的最大 steps / calories 作为当日总量
   */
  async getDailyStepsSummary(userId: number, days: number = 7): Promise<HealthData[]> {
    try {
      const oneDay = 24 * 60 * 60 * 1000;
      const end = new Date();
      end.setHours(23, 59, 59, 999);
      const start = new Date(end.getTime() - (days - 1) * oneDay);
      start.setHours(0, 0, 0, 0);

      const predicates = new relationalStore.RdbPredicates('health_data');
      predicates.equalTo('userId', userId);
      predicates.greaterThanOrEqualTo('timestamp', start.getTime());
      predicates.orderByAsc('timestamp');

      const result = await this.rdbStore!.query(predicates);

      const dayMap = new Map<string, HealthData>();
      const idxHr = result.getColumnIndex('heartRate');
      const idxSteps = result.getColumnIndex('steps');
      const idxCal = result.getColumnIndex('calories');
      const idxOxy = result.getColumnIndex('bloodOxygen');
      const idxUser = result.getColumnIndex('userId');
      const idxTs = result.getColumnIndex('timestamp');

      while (result.goToNextRow()) {
        const ts = result.getLong(idxTs);
        const dateStr = new Date(ts).toISOString().split('T')[0];

        const heartRate = result.getLong(idxHr);
        const steps = result.getLong(idxSteps);
        const calories = result.getLong(idxCal);
        const bloodOxygen = result.getLong(idxOxy);
        const uid = result.getLong(idxUser);

        const exist = dayMap.get(dateStr);
        if (!exist) {
          const d = new HealthData(heartRate, steps, calories, bloodOxygen, uid);
          d.timestamp = ts; // 用当天最后一条的时间戳
          dayMap.set(dateStr, d);
        } else {
          // 当天用“最大步数/卡路里”作为汇总值
          exist.steps = Math.max(exist.steps, steps);
          exist.calories = Math.max(exist.calories, calories);
          exist.heartRate = heartRate;
          exist.bloodOxygen = bloodOxygen;
          exist.timestamp = ts;
        }
      }
      result.close();

      const list = Array.from(dayMap.values());
      list.sort((a, b) => a.timestamp - b.timestamp); // 按日期升序
      return list;
    } catch (e) {
      console.error('getDailyStepsSummary error:', e);
      return [];
    }
  }

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
        avatar:user.avatar,
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

  // ==================== 用户名/邮箱更新 ====================
  /**
   * 修改用户名
   * @param oldName 原用户名（用于定位）
   * @param newName 新用户名
   */
  async updateUsername(oldName: string, newName: string): Promise<boolean> {
    if (!this.rdbStore || !oldName || !newName) return false;
    try {
      const predicates = new relationalStore.RdbPredicates('users');
      predicates.equalTo('username', oldName);          // 找到旧记录
      const value: relationalStore.ValuesBucket = {
        username: newName                                // 改成新名字
      };
      const rows = await this.rdbStore.update(value, predicates);
      return rows > 0;
    } catch (e) {
      console.error('updateUsername error:', e);
      return false;
    }
  }

  /**
   * 修改邮箱
   * @param username 当前登录用户名（定位用）
   * @param newEmail 新邮箱地址
   */
  async updateEmail(username: string, newEmail: string): Promise<boolean> {
    if (!this.rdbStore || !username || !newEmail) return false;
    try {
      const predicates = new relationalStore.RdbPredicates('users');
      predicates.equalTo('username', username);
      const value: relationalStore.ValuesBucket = {
        email: newEmail
      };
      const rows = await this.rdbStore.update(value, predicates);
      return rows > 0;
    } catch (e) {
      console.error('updateEmail error:', e);
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

  // ==========================================
  // Medical Records Operations
  // ==========================================

  async insertMedicalRecord(username: string, record: MedicalRecord): Promise<number> {
    if (!this.rdbStore) return -1;
    try {
      const value: relationalStore.ValuesBucket = {
        username: username, // 绑定用户
        title: record.title,
        date: record.date, // 假设 Model 里是 string 类型
        imageUri: record.imageUri,
        pdfUri: record.pdfUri,
        content: record.content,
        tags: JSON.stringify(record.tags), // 数组转字符串存储
        hospital: record.hospital
      };
      return await this.rdbStore.insert('medical_records', value);
    } catch (e) {
      console.error('insertMedicalRecord error:', e);
      return -1;
    }
  }

  /**
   * 获取某个用户的所有病历
   * @param username 用户名
   */
  async getMedicalRecords(username: string): Promise<MedicalRecord[]> {
    if (!this.rdbStore) return [];
    try {
      const predicates = new relationalStore.RdbPredicates('medical_records');
      predicates.equalTo('username', username); // 只查这个用户的
      predicates.orderByDesc('date'); // 按日期倒序

      const result = await this.rdbStore.query(predicates);
      const list: MedicalRecord[] = [];

      while (result.goToNextRow()) {
        // 从数据库读出数据
        const title = result.getString(result.getColumnIndex('title'));
        const date = result.getString(result.getColumnIndex('date'));
        const imageUri = result.getString(result.getColumnIndex('imageUri'));
        const pdfUri = result.getString(result.getColumnIndex('pdfUri'));
        const content = result.getString(result.getColumnIndex('content'));
        const tagsStr = result.getString(result.getColumnIndex('tags'));
        const hospital = result.getString(result.getColumnIndex('hospital'));
        const dbId = result.getLong(result.getColumnIndex('id'));

        // 还原 Tags
        let tags: string[] = [];
        try {
          tags = JSON.parse(tagsStr);
        } catch (e) {}

        // 构造对象
        const record = new MedicalRecord(title, date, imageUri, pdfUri, content, tags, hospital);
        record.id = dbId.toString(); // 建议 Model 里的 id 兼容数据库 ID

        list.push(record);
      }
      result.close();
      return list;
    } catch (e) {
      console.error('getMedicalRecords error:', e);
      return [];
    }
  }

  /**
   * 删除病历
   */
  async deleteMedicalRecord(id: string): Promise<boolean> {
    if (!this.rdbStore) return false;
    try {
      const predicates = new relationalStore.RdbPredicates('medical_records');
      predicates.equalTo('id', id); // 根据数据库 ID 删除
      const rows = await this.rdbStore.delete(predicates);
      return rows > 0;
    } catch (e) {
      console.error('deleteMedicalRecord error:', e);
      return false;
    }
  }

  /**
   * 更新病历
   */
  async updateMedicalRecord(username: string, record: MedicalRecord): Promise<boolean> {
    if (!this.rdbStore) return false;
    try {
      const predicates = new relationalStore.RdbPredicates('medical_records');
      predicates.equalTo('id', record.id);
      predicates.equalTo('username', username); // 双重保险，防止改了别人的数据

      const value: relationalStore.ValuesBucket = {
        title: record.title,
        date: record.date,
        imageUri: record.imageUri,
        pdfUri: record.pdfUri,
        content: record.content,
        tags: JSON.stringify(record.tags),
        hospital: record.hospital
      };

      const rows = await this.rdbStore.update(value, predicates);
      return rows > 0;
    } catch (e) {
      console.error('updateMedicalRecord error:', e);
      return false;
    }
  }

  // 新增身体数据的处理
  // 修改：参数由 userId: number 改为 userName: string
  async saveBodyInfo(userName: string, items: BodyInfoItem[]): Promise<void> {
    // 基础校验：确保数据库已打开且用户名不为空
    if (!this.rdbStore || !userName) return;

    try {
      this.rdbStore.beginTransaction();
      for (const item of items) {
        const value: relationalStore.ValuesBucket = {
          // 假设数据库表字段名仍叫 userName 或已改为 userName
          'userName': userName,
          'label': item.label,
          'value': item.value
        };
        console.info(`saveBodyInfo-尝试保存用户 ${userName} 的身体数据:${item.label}: ${item.value} `);
        // 使用 REPLACE 策略：同一用户、同一 label 的数据会被覆盖更新
        await this.rdbStore.insert('body_info', value, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      }
      this.rdbStore.commit();
      console.info(`成功保存用户 ${userName} 的身体数据`);
    } catch (e) {
      console.error('saveBodyInfo error:', e);
      this.rdbStore.rollBack();
    }
  }

  async checkColumns(): Promise<void> {
    if (!this.rdbStore) return;
    let predicates = new relationalStore.RdbPredicates('body_info');
    let result = await this.rdbStore.query(predicates);
    // 获取数据库真实的所有列名
    console.info('数据库真实列名: ' + result.columnNames.join(', '));
    result.close();
  }

  async reconstructBodyInfo(): Promise<void> {
    if (!this.rdbStore) return;
    await this.rdbStore.executeSql(DROP_BODY_INFO_TABLE);
    await this.rdbStore.executeSql(CREATE_BODY_INFO_TABLE);
    let predicates = new relationalStore.RdbPredicates('body_info');
    let result = await this.rdbStore.query(predicates);
    // 获取数据库真实的所有列名
    console.info('数据库真实列名: ' + result.columnNames.join(', '));
    result.close();
  }

  // 修改：参数由 userId: number 改为 userName: string
  async getBodyInfo(userName: string): Promise<BodyInfoItem[]> {
    if (!this.rdbStore || !userName) return [];
    console.info(`getBodyInfo-1111`)

    try {
      const predicates = new relationalStore.RdbPredicates('body_info');
      // 关键修改：第一个参数必须是数据库中的字段名 'userName'
      // 第二个参数是传入的变量 userName
      predicates.equalTo('userName', userName);
      const result = await this.rdbStore.query(predicates);
      const list: BodyInfoItem[] = [];

      console.info(`getBodyInfo-2222，${result.getColumnName(0)}`)
      interface BodyInfoItem {
        label: string;
        value: string;
      }
      while (result.goToNextRow()) {
        list.push({
          label: result.getString(result.getColumnIndex('label')),
          value: result.getString(result.getColumnIndex('value'))
        });
        console.info(`getBodyInfo-查询${userName}的数据,${result.getString(result.getColumnIndex('label'))}: ${result.getString(result.getColumnIndex('value'))}`);
      }
      console.info(`getBodyInfo-3333`)
      result.close();
      return list;
    } catch (e) {
      console.error('getBodyInfo error:', e);
      return [];
    }
  }
}

