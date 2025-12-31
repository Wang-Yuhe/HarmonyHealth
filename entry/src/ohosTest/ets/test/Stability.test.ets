import { describe, it, expect } from '@ohos/hypium';
import hilog from '@ohos.hilog';

const DOMAIN = 0x0000;
const TAG = 'StabilityTest';

// [修复点 1] 定义具体的函数类型别名，替代宽泛的 'Function'
type VoidCallback = () => void;

// 模拟全局事件总线
class EventBus {
  // [修复点 2] 使用具体的类型数组
  private listeners: VoidCallback[] = [];

  subscribe(callback: VoidCallback) {
    this.listeners.push(callback);
  }

  unsubscribe(callback: VoidCallback) {
    const index = this.listeners.indexOf(callback);
    if (index !== -1) {
      this.listeners.splice(index, 1);
    }
  }

  emit() {
    // [修复点 3] 修复报错：
    // 1. 显式标注参数类型 (cb: VoidCallback)
    // 2. 显式标注返回类型 : void
    // 3. 使用大括号 {} 包裹函数体，消除隐式返回的不确定性
    this.listeners.forEach((cb: VoidCallback): void => {
      cb();
    });
  }

  getListenerCount(): number {
    return this.listeners.length;
  }
}

export default function stabilityTest() {
  describe('StabilityTest', () => {

    it('STAB_003_EventListenerLeakCheck', 0, () => {
      // 场景：模拟页面反复打开关闭，检查是否正确注销了事件监听
      const globalBus = new EventBus();
      const CYCLES = 10000;

      hilog.info(DOMAIN, TAG, `Starting EventListener leak check (${CYCLES} cycles)`);

      for (let i = 0; i < CYCLES; i++) {
        // 1. 模拟组件挂载 (Component Mount)
        const onEvent: VoidCallback = () => { /* handle event */ };
        globalBus.subscribe(onEvent);

        // 2. 验证订阅成功
        // 在真实场景中，如果这里逻辑错误，内存就会无限增长

        // 3. 模拟组件卸载 (Component Unmount)
        globalBus.unsubscribe(onEvent);
      }

      // 4. 最终检查：所有监听器是否都已移除？
      // 如果 > 0，说明有泄漏
      const remaining = globalBus.getListenerCount();
      hilog.info(DOMAIN, TAG, `Remaining listeners: ${remaining}`);

      expect(remaining).assertEqual(0);
    });

    it('STAB_005_LongRunningServiceStability', 0, async () => {
      // 场景：模拟后台服务连续运行，处理心跳包
      const RUN_TIME_MS = 1000; // 运行 1 秒
      let beatsProcessed = 0;
      const startTime = Date.now();

      // 模拟心跳处理函数
      const processHeartbeat = async (): Promise<number> => {
        // 模拟少量 CPU 消耗
        let checksum = 0;
        for(let i=0; i<100; i++) checksum += i;
        return checksum;
      };

      // 持续运行直到超时
      while (Date.now() - startTime < RUN_TIME_MS) {
        await processHeartbeat();
        beatsProcessed++;

        // 模拟每 10ms 到达一个心跳
        await new Promise<void>(resolve => setTimeout(resolve, 10));
      }

      hilog.info(DOMAIN, TAG, `Service handled ${beatsProcessed} beats in ${RUN_TIME_MS}ms`);

      // 验证服务在长时间运行下是否保持响应
      expect(beatsProcessed).assertLarger(50); // 至少处理了50个心跳
    });
  });
}