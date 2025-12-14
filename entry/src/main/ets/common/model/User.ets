/**
 * @file User.ets
 * @description 用户数据模型
 * @created 2025-12-03 09:12:10
 */

export class User {
  id: number = 0;
  username: string = '';
  password: string = ''; // 后续建议加密
  token?: string;
  // 新增元数据
  avatar:string = ''; // 头像路径
  email: string = '';
  securityQuestion: string = '';
  securityAnswer: string = '';

  constructor(username: string, password: string, email?: string,
    securityQuestion?: string, securityAnswer?: string,avatar?:string) {
    this.username = username;
    this.password = password;
    this.email = email || '';
    this.securityQuestion = securityQuestion || '';
    this.securityAnswer = securityAnswer || '';
    this.avatar=avatar||'';
  }
}