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

export const CREATE_HEALTH_TABLE = `
  CREATE TABLE IF NOT EXISTS health_data (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp INTEGER NOT NULL,
    heartRate INTEGER,
    steps INTEGER,
    calories INTEGER,
    bloodOxygen INTEGER
  );
`;

export const CREATE_SLEEP_TABLE = `
  CREATE TABLE IF NOT EXISTS sleep_data (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL UNIQUE,
    totalMinutes INTEGER,
    deepSleepMinutes INTEGER,
    lightSleepMinutes INTEGER,
    awakeMinutes INTEGER
  );
`;