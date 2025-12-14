/**
 * @file LoginVM.ets
 * @description 登录模块的 ViewModel + 业务逻辑
 * @created 2025-12-03 09:12:10
 */

import { Context } from '@kit.AbilityKit';
import { HealthDB } from '../../../database/HealthDB';
import { User } from '../../../common/model/User';
import { AuthUtil } from '../../../common/utils/AuthUtil';
import fs from '@ohos.file.fs'; // 文件系统 API
import { photoAccessHelper } from '@kit.MediaLibraryKit';

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
    await this.removeUserAvatar(context, username);

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

  async saveUserAvatar(context: Context, username: string, sourcePathOrUri: string): Promise<string | null> {
    try {
      console.log(`[saveUserAvatar] Starting for user: ${username}, source: ${sourcePathOrUri}`);

      await this.healthDB.initDB(context);

      // 确保头像目录存在
      const avatarDir = `${context.filesDir}/avatars/`;
      try {
        await fs.stat(avatarDir);
      } catch (e) {
        await fs.mkdir(avatarDir, true);
      }

      // 生成目标路径
      const destPath = `${avatarDir}${username}.jpg`;
      console.log(`[saveUserAvatar] Destination path: ${destPath}`);

      // 使用 PhotoViewPicker 返回的 URI 直接复制到私有目录
      // 先打开源文件
      const srcFile = await fs.open(sourcePathOrUri, fs.OpenMode.READ_ONLY);
      const stat = await fs.stat(sourcePathOrUri);

      // 打开目标文件
      const destFile = await fs.open(destPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);

      // 分块复制文件内容
      const bufferSize = 4096;
      let totalBytesRead = 0;

      while (totalBytesRead < stat.size) {
        const buffer = new ArrayBuffer(bufferSize);
        const bytesRead = await fs.read(srcFile.fd, buffer, { offset: 0, length: Math.min(bufferSize, stat.size - totalBytesRead) });

        if (bytesRead <= 0) break;

        const actualBuffer = buffer.slice(0, bytesRead);
        await fs.write(destFile.fd, actualBuffer, { offset: 0, length: bytesRead });
        totalBytesRead += bytesRead;
      }

      // 关闭文件句柄
      await fs.close(srcFile.fd);
      await fs.close(destFile.fd);

      console.log(`[saveUserAvatar] File copied successfully to: ${destPath}`);

      // 生成持久化 URI 并更新数据库
      const persistentUri = `file://${destPath}`;
      console.log(`[saveUserAvatar] Generated persistent URI: ${persistentUri}`);

      const success = await this.healthDB.setUserAvatar(username, persistentUri);
      console.log(`[saveUserAvatar] Database update result: ${success}, URI: ${persistentUri}`);

      if (!success) {
        console.error('[saveUserAvatar] Database update failed');
        try {
          await fs.unlink(destPath);
        } catch (e) {
          console.warn('[saveUserAvatar] Failed to clean up after DB failure:', e);
        }
        return null;
      }

      return persistentUri;
    } catch (e) {
      console.error(`[saveUserAvatar] Fatal error for ${username}:`, e);
      return null;
    }
  }

  // 删除用户头像（文件 + DB）
  async removeUserAvatar(context: Context, username: string): Promise<boolean> {
    try {
      await this.healthDB.initDB(context);

      const user = await this.healthDB.getUserByUsername(username);
      if (!user || !user.avatar || user.avatar === '') {
        return true; // 无头像，视为成功
      }

      if (user.avatar.startsWith('file://')) {
        const filePath = user.avatar.substring(7); // 移除 'file://'

        try {
          //  异步检查文件是否存在
          await fs.access(filePath);
          //  异步删除
          await fs.unlink(filePath);
          console.log(`[removeUserAvatar] Deleted avatar file: ${filePath}`);
        } catch (err) {
          // 文件不存在（ENOENT）是正常情况，其他错误需记录
          const errMsg = (err as Error).message;
          if (errMsg.indexOf('ENOENT') === -1) {
            console.warn(`[removeUserAvatar] Unexpected error deleting file:`, err);
            // 注意：这里不 return false，因为可能是并发删除导致文件已不存在
          }
          // 即使文件删失败（如已被删），仍继续清理数据库
        }
      }

      // 清空数据库字段
      return await this.healthDB.removeUserAvatar(username);
    } catch (e) {
      console.error(`[removeUserAvatar] Fatal error for ${username}:`, e);
      return false;
    }
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

