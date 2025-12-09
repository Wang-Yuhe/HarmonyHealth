/**
 * @file LoginVM.ets
 * @description 登录模块的 ViewModel + 业务逻辑
 * @created 2025-12-03 09:12:10
 */

import { Context } from '@kit.AbilityKit';
import { HealthDB } from '../../../database/HealthDB';
import { User } from '../../../common/model/User';
import { AuthUtil } from '../../../common/utils/AuthUtil';

export class LoginVM {
  private healthDB: HealthDB = new HealthDB();

  async login(context: Context, username: string, password: string): Promise<boolean> {
    await this.healthDB.initDB(context);
    const user = await this.healthDB.getUserByUsername(username);
    if (user && user.password === password) {
      await AuthUtil.saveLoginUser(context, user);
      return true;
    }
    return false;
  }

  async register(context: Context, username: string, password: string,
    email?: string, securityQuestion?: string, securityAnswer?: string): Promise<boolean> {
    await this.healthDB.initDB(context);
    const existingUser = await this.healthDB.getUserByUsername(username);
    if (existingUser) {
      return false;
    }
    const user = new User(username, password, email, securityQuestion, securityAnswer);
    const userId = await this.healthDB.insertUser(user);
    return userId > 0;
  }

  async deleteUser(context: Context, username: string, password: string): Promise<boolean> {
    await this.healthDB.initDB(context);
    return await this.healthDB.deleteUser(username, password);
  }

  async getUserByUsername(context: Context, username: string): Promise<User | null> {
    await this.healthDB.initDB(context);
    return await this.healthDB.getUserByUsername(username);
  }

  async resetPassword(context: Context, username: string,
    securityAnswer: string, newPassword: string): Promise<boolean> {
    await this.healthDB.initDB(context);
    const user = await this.healthDB.getUserByUsername(username);
    if (user && user.securityAnswer === securityAnswer) {
      return await this.healthDB.updatePassword(username, newPassword);
    }
    return false;
  }
}