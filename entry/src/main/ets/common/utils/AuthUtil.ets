/**
 * @file AuthUtil.ets
 * @description 认证辅助工具类
 * @created 2025-12-03 09:12:10
 */

import { Context } from '@kit.AbilityKit';
import dataPreferences from '@ohos.data.preferences';
import { User } from '../model/User';

const PREF_NAME = 'auth_pref';
const KEY_LOGIN_USER = 'login_user';

export class AuthUtil {
  static async saveLoginUser(context: Context, user: User): Promise<void> {
    try {
      const pref = await dataPreferences.getPreferences(context, PREF_NAME);
      await pref.put(KEY_LOGIN_USER, JSON.stringify(user));
      await pref.flush();
    } catch (e) {
      console.error('saveLoginUser err:', e);
    }
  }

  static async getLoginUser(context: Context): Promise<User | null> {
    try {
      const pref = await dataPreferences.getPreferences(context, PREF_NAME);
      const str = await pref.get(KEY_LOGIN_USER, '');
      return str ? JSON.parse(str as string) as User : null;
    } catch (e) {
      console.error('getLoginUser err:', e);
      return null;
    }
  }

  static async clearLoginUser(context: Context): Promise<void> {
    try {
      const pref = await dataPreferences.getPreferences(context, PREF_NAME);
      await pref.delete(KEY_LOGIN_USER);
      await pref.flush();
    } catch (e) {
      console.error('clearLoginUser err:', e);
    }
  }
}