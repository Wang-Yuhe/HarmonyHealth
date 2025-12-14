export interface ParsedInfo {
  title?: string;
  hospital?: string;
  date?: Date;
}

export class RecordParser {

  /**
   * 从 OCR 文本中智能提取关键信息
   */
  static parse(text: string): ParsedInfo {
    const info: ParsedInfo = {};

    if (!text) return info;

    // 按行分割，方便逐行分析
    // 同时也按空格分割，因为 OCR 有时会把 "医院 标题" 识别在一行
    const lines = text.split(/[\n\s]+/);

    // ==========================================
    // 1. 提取医院名称
    // 策略：查找以 "医院"、"中心"、"卫生院" 结尾的词
    // ==========================================
    const hospitalRegex = /^[\u4e00-\u9fa5()（）]+(医院|卫生院|社康中心|体检中心|医疗中心)$/;

    for (let line of lines) {
      // 移除干扰字符
      const cleanLine = line.trim();
      if (hospitalRegex.test(cleanLine)) {
        info.hospital = cleanLine;
        break; // 找到一个就停止，通常第一个就是
      }
    }

    // ==========================================
    // 2. 提取标题
    // 策略：查找以 "报告"、"病历"、"检查单" 结尾的词
    // ==========================================
    const titleRegex = /^[\u4e00-\u9fa5]+(报告|病历|检查单|化验单|诊断书|体检表)$/;

    for (let line of lines) {
      const cleanLine = line.trim();
      // 排除掉包含 "医院" 的行（防止把医院名当成标题）
      if (titleRegex.test(cleanLine) && !cleanLine.includes("医院")) {
        info.title = cleanLine;
        break;
      }
    }

    // 兜底策略：如果没找到明确标题，尝试在第一行或第二行找包含 "糖尿病"、"检查" 等关键词的
    if (!info.title) {
      for (let i = 0; i < Math.min(lines.length, 5); i++) {
        if (lines[i].includes("体检") || lines[i].includes("报告")) {
          info.title = lines[i];
          break;
        }
      }
    }

    // ==========================================
    // 3. 提取日期 (额外福利)
    // 策略：匹配 YYYY年MM月DD日 或 YYYY-MM-DD
    // ==========================================
    const dateRegex = /(\d{4})年(\d{1,2})月(\d{1,2})日/;
    const dateMatch = text.match(dateRegex);

    if (dateMatch) {
      const year = parseInt(dateMatch[1]);
      const month = parseInt(dateMatch[2]) - 1; // JS月份从0开始
      const day = parseInt(dateMatch[3]);
      info.date = new Date(year, month, day);
    }

    return info;
  }
}