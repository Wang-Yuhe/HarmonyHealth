/**
 * @file LoginVM.ets
 * @description 登录模块的 ViewModel + 业务逻辑
 * @created 2025-12-03 09:12:10
 */

import { Context } from '@kit.AbilityKit';
import { HealthDB } from '../../../database/HealthDB';
import { User } from '../../../common/model/User';
import { AuthUtil } from '../../../common/utils/AuthUtil';
import { fileIo as fs, WriteOptions } from '@kit.CoreFileKit'
import { BusinessError } from '@kit.BasicServicesKit';



export class LoginVM {
  private healthDB: HealthDB = HealthDB.getInstance();



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
    email?: string, securityQuestion?: string, securityAnswer?: string,avatar?:string): Promise<boolean> {
    await this.healthDB.initDB(context);
    const existingUser = await this.healthDB.getUserByUsername(username);
    if (existingUser) {
      return false;
    }
    const user = new User(username, password, email, securityQuestion, securityAnswer,avatar);
    const userId = await this.healthDB.insertUser(user);
    return userId > 0;
  }

  async deleteUser(context: Context, username: string, password: string): Promise<boolean> {
    await this.healthDB.initDB(context);

    // 验证密码（确保是本人操作）
    const user = await this.healthDB.getUserByUsername(username);
    if (!user || user.password !== password) {
      return false;
    }

    // 先删除头像文件（安全清理）
    if(user.avatar){
      await this.deletePersistentAvatar(context,user.avatar);
    }


    // 再删除用户记录
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

  async setUserAvatar(
    context: Context,
    username: string,
    imageBuffer: ArrayBuffer
  ): Promise<void>{
    //预留给后面修改头像
  }

  async deletePersistentAvatar(context: Context, avatarUri: string): Promise<void> {
    if (!avatarUri || !avatarUri.startsWith('file://')) return ; // 没头像或不是文件路径

    const filePath = avatarUri.slice(7); // 去掉 file://

    fs.unlink(filePath).then(() => {
      console.info("remove file succeed");
      return;
    }).catch((err: BusinessError) => {
      console.error("remove file failed with error message: " + err.message + ", error code: " + err.code);
      return;
    });

  }

  async initializeDefaultUsers(context: Context): Promise<void> {
    // 确保 DB 已初始化（幂等，安全）
    await this.healthDB.initDB(context);

    //  先删除已存在的 admin 用户（确保重新创建）
    const existingAdmin = await this.healthDB.getUserByUsername('admin');
    if (existingAdmin) {
      console.log('[LoginVM] Admin user already exists, deleting first:', existingAdmin.avatar);
      await this.healthDB.deleteUser('admin','123456'); // 假设你有这个方法
    }

    console.log('[LoginVM] Creating default admin user...');

    // 检查 admin 是否已存在
    const adminExists = await this.healthDB.getUserByUsername('admin');
    if (adminExists) {
      return; // 已存在，跳过
    }

    console.log('[LoginVM] Creating default admin user...');

    // 1. 注册基础用户（不带头像）
    const registered = await this.register(
      context,
      'admin',
      '123456',
      'admin@example.com',
      '您的出生地是？',
      '北京',
      '' // 初始无头像
    );

    if (!registered) {
      console.error('[LoginVM] Failed to register default admin');
      return;
    }

  }

}

