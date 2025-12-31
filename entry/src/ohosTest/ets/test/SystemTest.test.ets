import { describe, it, expect, beforeEach } from '@ohos/hypium';
import hilog from '@ohos.hilog';

const DOMAIN = 0x0000;
const TAG = 'SystemTest';

// --- 模拟 AI 服务 ---
interface GeneratedTypeLiteralInterface_1 {
  risk: string;
  advice: string;
}

class MockAIService {
  async askDoctor(symptom: string): Promise<GeneratedTypeLiteralInterface_1> {
    // 模拟网络延迟
    await new Promise<void>(resolve => setTimeout(resolve, 50));

    if (symptom.includes('头痛')) {
      return {
        risk: '中度风险',
        advice: '建议休息，监测血压，必要时就医。'
      };
    }
    return { risk: '低风险', advice: '多喝热水' };
  }
}

// --- 模拟实时监测管理器 ---
class RealTimeMonitor {
  intervalId: number = -1;
  isRunning: boolean = false;
  latestHeartRate: number = 0;

  toggleSwitch(isOn: boolean) {
    this.isRunning = isOn;
    if (isOn) {
      // 模拟每 10ms 更新一次数据 (加速版)
      this.intervalId = setInterval(() => {
        this.latestHeartRate = 70 + Math.floor(Math.random() * 10); // 70-80 bpm
      }, 10);
    } else {
      clearInterval(this.intervalId);
    }
  }
}

export default function systemTest() {
  describe('SystemFlowTest', () => {

    // 对标截图：AI 智能问诊流程
    it('ST_001_AIConsultationFlow', 0, async () => {
      const ai = new MockAIService();
      const userQuestion = "最近总是头痛，伴有头晕";

      hilog.info(DOMAIN, TAG, 'Step 1: 用户发送问题');
      const response = await ai.askDoctor(userQuestion);

      hilog.info(DOMAIN, TAG, 'Step 2: 收到 AI 回复');
      // 验证是否包含截图中的关键词
      expect(response.risk).assertEqual('中度风险');
      expect(response.advice).assertContain('就医');
    });

    // 对标截图：实时健康监测开关
    it('ST_002_RealTimeMonitorToggle', 0, async () => {
      const monitor = new RealTimeMonitor();

      // 1. 初始状态关闭
      expect(monitor.isRunning).assertFalse();
      expect(monitor.latestHeartRate).assertEqual(0);

      // 2. 用户点击开关 (对应截图中的 "监测设置" Toggle)
      monitor.toggleSwitch(true);
      expect(monitor.isRunning).assertTrue();

      // 3. 等待数据刷新 (模拟 3秒刷新间隔，这里缩短为 50ms)
      await new Promise<void>(resolve => setTimeout(resolve, 50));

      // 4. 验证是否有数据产生 (截图显示 74 bpm)
      expect(monitor.latestHeartRate).assertLarger(0);
      hilog.info(DOMAIN, TAG, `监测到心率: ${monitor.latestHeartRate}`);

      // 5. 关闭开关
      monitor.toggleSwitch(false);
      expect(monitor.isRunning).assertFalse();
    });
  });
}