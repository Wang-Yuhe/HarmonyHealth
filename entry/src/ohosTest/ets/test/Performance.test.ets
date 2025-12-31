import { describe, it, expect, beforeAll } from '@ohos/hypium';
import hilog from '@ohos.hilog';

const DOMAIN = 0x0000;
const TAG = 'PerformanceTest';

class ComplexData {
  id: number = 0;
  info: string = '';
  details: Record<string, string> = {};
}

export default function performanceTest() {
  describe('PerformanceTest', () => {

    // 预热
    beforeAll(() => {
      const temp = JSON.stringify({ test: "warmup" });
      JSON.parse(temp);
    });

    it('PT_003_HeavyJsonProcessing', 0, () => {
      // 模拟：解析大型 API 响应 (例如 1MB 的 JSON 数据)
      const DATA_SIZE = 5000;
      hilog.info(DOMAIN, TAG, `Generating complex object with ${DATA_SIZE} items`);

      // 1. 构建一个深层嵌套的大对象
      const rawList: ComplexData[] = [];
      for (let i = 0; i < DATA_SIZE; i++) {
        let item = new ComplexData();
        item.id = i;
        item.info = `Description for item ${i} with extensive text content to increase memory footprint.`;
        item.details = { "key1": "value1", "key2": "value2" };
        rawList.push(item);
      }

      const startTime = Date.now();

      // 2. 模拟最耗时的操作：序列化与反序列化 (模拟网络传输+解析)
      // 这是 JS/ArkTS 中非常消耗 CPU 的操作
      const jsonString = JSON.stringify(rawList);
      const parsedData = JSON.parse(jsonString) as ComplexData[];

      // 3. 模拟数据转换
      const resultTokens = parsedData.map((item) => {
        return item.info.substring(0, 10).toUpperCase();
      });

      const duration = Date.now() - startTime;

      hilog.info(DOMAIN, TAG, `JSON Processing ${DATA_SIZE} items took ${duration}ms`);

      expect(parsedData.length).assertEqual(DATA_SIZE);
      expect(resultTokens.length).assertEqual(DATA_SIZE);
      expect(duration).assertLess(3000);
    });

    it('PT_007_AsyncThroughput', 0, async () => {
      // 模拟：高并发网络请求吞吐量
      const REQUEST_COUNT = 200;
      let completed = 0;

      const startTime = Date.now();

      const tasks: Promise<string>[] = [];
      for (let i = 0; i < REQUEST_COUNT; i++) {
        // 模拟不均匀的 API 响应时间 (10ms - 60ms)
        const p = new Promise<string>((resolve) => {
          const delay = Math.floor(Math.random() * 50) + 10;
          setTimeout(() => {
            completed++;
            resolve(`Response ${i}`);
          }, delay);
        });
        tasks.push(p);
      }

      await Promise.all(tasks);
      const duration = Date.now() - startTime;

      hilog.info(DOMAIN, TAG, `Processed ${REQUEST_COUNT} async requests in ${duration}ms`);

      // 验证吞吐量是否符合预期 (所有任务应并行执行，总耗时应接近最慢的单个任务，而不是累加)
      expect(completed).assertEqual(REQUEST_COUNT);
      expect(duration).assertLess(500); // 即使有200个任务，因为是并发，总耗时不应太长
    });
  });
}