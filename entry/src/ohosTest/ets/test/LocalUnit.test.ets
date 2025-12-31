import { describe, it, expect } from '@ohos/hypium';

// --- 模拟 App 内部的核心算法类 ---

interface GeneratedObjectLiteralInterface_1 {
  km: number;
  kcal: number;
}

class HealthCalculator {
  /**
   * 计算卡路里和距离
   * 基于截图：11步，4kcal (大概 0.36 kcal/步? 或者基于体重计算)
   * 假设公式：
   * 距离(km) = 步数 * 0.7米 / 1000
   * 热量(kcal) = 步数 * 0.04 (简化估算)
   */
  static calculateActivityStats(steps: number) {
    const distanceKm = (steps * 0.7) / 1000;
    const calories = steps * 0.04;
    return ({
      km: parseFloat(distanceKm.toFixed(1)),
      kcal: Math.floor(calories)
    } as GeneratedObjectLiteralInterface_1);
  }

  /**
   * 睡眠评分算法 (基于截图逻辑推测)
   * 假设：总分100。
   * 深睡占比 >= 25% 得满分，每少 1% 扣 2 分。
   * 时长 >= 7小时 得满分。
   */
  static calculateSleepScore(durationHours: number, deepSleepPercent: number): number {
    let score = 100;

    // 扣分项1：时长不足
    if (durationHours < 7) {
      score -= (7 - durationHours) * 10;
    }

    // 扣分项2：深睡不足 (基准 25%)
    if (deepSleepPercent < 25) {
      score -= (25 - deepSleepPercent) * 2;
    }

    return Math.max(0, Math.floor(score));
  }
}

class DiseaseSearcher {
  /**
   * 疾病档案搜索逻辑 (对标截图中的搜索框)
   */
  static search(records: string[], keyword: string): string[] {
    if (!keyword) return records;
    return records.filter(r => r.includes(keyword));
  }
}

// --- 测试套件 ---

export default function localUnitTest() {
  describe('AppBusinessLogicTest', () => {

    // 对标截图：步数数据概览
    it('LU_001_StepConversion', 0, () => {
      // 场景：截图中走了 35458 步，总里程 24.8km
      // 我们验证算法是否接近这个比例
      const stats = HealthCalculator.calculateActivityStats(35458);

      // 验证距离 (误差允许范围内)
      expect(stats.km).assertLarger(20.0);
      expect(stats.km).assertLess(30.0);

      // 验证简单逻辑：0步应该0公里
      const zeroStats = HealthCalculator.calculateActivityStats(0);
      expect(zeroStats.km).assertEqual(0);
    });

    // 对标截图：睡眠质量分析
    it('LU_002_SleepScoring', 0, () => {
      // 场景：截图中时长 7.8h，深睡 25%，评分 98 (非常高)
      // 根据我们的模拟算法测试
      const scorePerfect = HealthCalculator.calculateSleepScore(7.8, 25);
      expect(scorePerfect).assertEqual(100);

      // 场景：熬夜，睡了4小时，深睡10%
      const scoreBad = HealthCalculator.calculateSleepScore(4, 10);
      // 扣分：时长扣30，深睡扣30 -> 40分
      expect(scoreBad).assertLess(60);
    });

    // 对标截图：疾病档案搜索
    it('LU_003_DiseaseSearchLogic', 0, () => {
      const db = ['急性肠胃炎 2023-10', '过敏性鼻炎 2024-01', '流感 2024-02'];

      // 搜索 "炎"
      const result = DiseaseSearcher.search(db, '炎');
      expect(result.length).assertEqual(2);
      expect(result).assertContain('急性肠胃炎 2023-10');

      // 搜索不存在的
      const resultEmpty = DiseaseSearcher.search(db, '骨折');
      expect(resultEmpty.length).assertEqual(0);
    });
  });
}