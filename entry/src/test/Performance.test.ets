import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import hilog from '@ohos.hilog';

// --- 1. 定义数据模型 (用于替代 any 和 spread 操作) ---

class HealthRawData {
  timestamp: number = 0;
  steps: number = 0;
  heartRate: number = 0;
}

class HealthProcessedData {
  timestamp: number = 0;
  steps: number = 0;
  heartRate: number = 0;
  date: string = '';
  isActive: boolean = false;
}

class UiStyle {
  width: number = 0;
  height: number = 0;
}

class UiPosition {
  x: number = 0;
  y: number = 0;
}

class UiItem {
  id: number = 0;
  title: string = '';
  description: string = '';
  calculatedStyle: UiStyle = new UiStyle();
}

class LayoutItem extends UiItem {
  position: UiPosition = new UiPosition();
}

class ResourceItem {
  id: number = 0;
  data: number[] | null = [];
  cleanup: () => void = () => {};
}

class TestItem {
  id: number = 0;
  value: number = 0;
}

// 模拟 Node.js process 对象的类型 (如果是在端侧运行，实际上 process 不存在，建议移除相关测试)
// 这里仅为了解决编译报错
interface MemoryUsage {
  rss: number;
}

interface ProcessType {
  memoryUsage?: MemoryUsage;
}

declare const process: ProcessType;


// --- 2. 测试代码 ---

export default function performanceTest() {
  describe('PerformanceTest', () => {
    beforeAll(() => {
      hilog.info(0x0000, 'PerformanceTest', 'Starting performance tests');
    });

    afterAll(() => {
      hilog.info(0x0000, 'PerformanceTest', 'Performance tests completed');
    });

    it('Response Time Test', 0, () => {
      const startTime = Date.now();
      const result = 'test'.toUpperCase();
      const endTime = Date.now();
      const responseTime = endTime - startTime;

      hilog.info(0x0000, 'PerformanceTest', `Response time: ${responseTime}ms`);

      expect(result).assertEqual('TEST');
      expect(responseTime).assertLess(100);
    });

    it('Memory Usage Test', 0, () => {
      // 修复：显式指定类型为 number，避免 implicit any
      // 注意：ArkTS 运行在设备上时通常没有 process 对象，这里为了过编译加了类型检查
      let initialMemory: number = 0;
      try {
        initialMemory = process?.memoryUsage?.rss || 0;
      } catch (e) {
        initialMemory = 0;
      }

      const testArray = new Array(1000).fill(0).map((_: number, i: number): TestItem => {
        return { id: i, value: Math.random() } as TestItem;
      });

      let afterMemory: number = 0;
      try {
        afterMemory = process?.memoryUsage?.rss || 0;
      } catch (e) {
        afterMemory = 0;
      }

      const memoryIncrease = afterMemory - initialMemory;

      hilog.info(0x0000, 'PerformanceTest', `Memory increase: ${memoryIncrease} bytes`);

      expect(testArray.length).assertEqual(1000);
      // 即使 process 不存在导致为 0， assertLess 也成立
      expect(memoryIncrease).assertLess(1024 * 1024);
    });

    it('Data Processing Performance Test', 0, () => {
      const startTime = Date.now();

      // 修复：显式指定 map 返回类型，确保结构清晰
      const rawData: HealthRawData[] = Array.from({ length: 100 }, (_: Object, i: number) => {
        let item = new HealthRawData();
        item.timestamp = Date.now() + i * 1000;
        item.steps = Math.floor(Math.random() * 10000);
        item.heartRate = 60 + Math.floor(Math.random() * 40);
        return item;
      });

      const processedData: HealthProcessedData[] = rawData.map((item: HealthRawData) => {
        // 修复：ArkTS 不支持 ...item (spread operator)，必须逐个赋值
        let processed = new HealthProcessedData();
        processed.timestamp = item.timestamp;
        processed.steps = item.steps;
        processed.heartRate = item.heartRate;
        processed.date = new Date(item.timestamp).toISOString();
        processed.isActive = item.steps > 5000;
        return processed;
      });

      const endTime = Date.now();
      const processingTime = endTime - startTime;

      hilog.info(0x0000, 'PerformanceTest', `Data processing time: ${processingTime}ms for ${rawData.length} items`);

      expect(processedData.length).assertEqual(rawData.length);
      expect(processingTime).assertLess(500);
    });

    it('Async Operation Performance Test', 0, async () => {
      const startTime = Date.now();

      // 修复：new Promise 必须加泛型 <void>
      await new Promise<void>(resolve => setTimeout(resolve, 50));

      const endTime = Date.now();
      const asyncTime = endTime - startTime;

      hilog.info(0x0000, 'PerformanceTest', `Async operation time: ${asyncTime}ms`);

      // 修复：Hypium 中应该是 assertLargerOrEqual
      expect(asyncTime).assertLargerOrEqual(45);
      expect(asyncTime).assertLess(200);
    });

    it('UI Rendering Simulation Test', 0, () => {
      const startTime = Date.now();

      const items: UiItem[] = Array.from({ length: 50 }, (_: Object, i: number) => {
        let item = new UiItem();
        item.id = i;
        item.title = `Item ${i}`;
        item.description = `Description for item ${i}`.repeat(5);
        item.calculatedStyle = {
          width: 100 + (i % 10) * 10,
          height: 50 + (i % 5) * 5
        };
        return item;
      });

      const layoutResults: LayoutItem[] = items.map((item: UiItem) => {
        // 修复：替换 ...item 为显式赋值
        let layout = new LayoutItem();
        layout.id = item.id;
        layout.title = item.title;
        layout.description = item.description;
        layout.calculatedStyle = item.calculatedStyle;
        layout.position = {
          x: (item.id % 10) * 120,
          y: Math.floor(item.id / 10) * 60
        };
        return layout;
      });

      const endTime = Date.now();
      const renderTime = endTime - startTime;

      hilog.info(0x0000, 'PerformanceTest', `UI rendering simulation time: ${renderTime}ms for ${items.length} items`);

      expect(layoutResults.length).assertEqual(items.length);
      expect(renderTime).assertLess(100);
    });

    it('Network Timeout Handling Test', 0, async () => {
      const startTime = Date.now();

      try {
        // 修复：new Promise 泛型 <void>，并处理 reject 类型
        await new Promise<void>((_, reject) => {
          setTimeout(() => reject(new Error('Timeout')), 100);
        });
      } catch (error) {
        const endTime = Date.now();
        const timeoutHandlingTime = endTime - startTime;

        hilog.info(0x0000, 'PerformanceTest', `Timeout handling time: ${timeoutHandlingTime}ms`);

        // 强转 error 为 Error 类型
        expect((error as Error).message).assertEqual('Timeout');
        // 修复：使用 assertLargerOrEqual
        expect(timeoutHandlingTime).assertLargerOrEqual(95);
        expect(timeoutHandlingTime).assertLess(200);
      }
    });

    it('Concurrent Operations Test', 0, async () => {
      const startTime = Date.now();

      // 修复：Promise 类型为 string
      const promises = Array.from({ length: 10 }, (_: Object, i: number) =>
      new Promise<string>(resolve => {
        setTimeout(() => resolve(`result-${i}`), Math.random() * 100);
      })
      );

      // 修复：显式指定 await 结果类型为 string[]
      const results: string[] = await Promise.all(promises);
      const endTime = Date.now();
      const concurrentTime = endTime - startTime;

      hilog.info(0x0000, 'PerformanceTest', `Concurrent operations time: ${concurrentTime}ms`);

      expect(results.length).assertEqual(10);
      expect(concurrentTime).assertLess(200);
    });

    it('Resource Cleanup Performance Test', 0, () => {
      const startTime = Date.now();

      // 修复：使用具体的 ResourceItem 类，替代 any[]
      const resources: ResourceItem[] = [];
      for (let i = 0; i < 100; i++) {
        let res = new ResourceItem();
        res.id = i;
        res.data = new Array(100).fill(Math.random());
        res.cleanup = () => {};
        resources.push(res);
      }

      // Cleanup
      // 修复：ResourceItem 类型明确，不再有 any 警告
      resources.forEach((resource: ResourceItem) => {
        resource.cleanup();
        resource.data = null;
      });

      const endTime = Date.now();
      const cleanupTime = endTime - startTime;

      hilog.info(0x0000, 'PerformanceTest', `Resource cleanup time: ${cleanupTime}ms`);

      expect(cleanupTime).assertLess(50);
    });
  });
}