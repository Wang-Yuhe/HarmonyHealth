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
    userId INTEGER NOT NULL,
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
    userId INTEGER NOT NULL,
    date TEXT NOT NULL,
    totalMinutes INTEGER,
    deepSleepMinutes INTEGER,
    lightSleepMinutes INTEGER,
    awakeMinutes INTEGER,
    UNIQUE(userId, date)
  );
`;

export const CREATE_MEDICAL_TABLE = `
  CREATE TABLE IF NOT EXISTS medical_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL,
    title TEXT,
    date TEXT,
    imageUri TEXT,
    pdfUri TEXT,
    content TEXT,
    tags TEXT,
    hospital TEXT
  );
`;

export const CREATE_BODY_INFO_TABLE = `
  CREATE TABLE IF NOT EXISTS body_info (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    userId INTEGER,
    label TEXT,
    value TEXT,
    UNIQUE(userId, label)
  )
`;