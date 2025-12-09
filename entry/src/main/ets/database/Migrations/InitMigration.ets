/**
 * @file InitMigration.ets
 * @description 数据库初始化迁移脚本
 * @created 2025-12-03 09:12:10
 */


export const CREATE_USER_TABLE = `
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    token TEXT,
    avatar TEXT,
    email TEXT,
    securityQuestion TEXT,
    securityAnswer TEXT
  );
`;