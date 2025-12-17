import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import fs from '@ohos.file.fs';

// ==========================================
// 1. 定义完整的接口结构 (关键！)
// ==========================================

// 坐标信息 (百度返回的 location)
interface LocationInfo {
  top: number;
  left: number;
  width: number;
  height: number;
}

// OCR 结果项 (包含文字和坐标)
interface OCRResultItem {
  words: string;
  location?: LocationInfo; // 加上 ? 防止某些特殊情况没有坐标
}

// 百度 API 响应结构
interface GeneralOCRResponse {
  words_result?: OCRResultItem[];
  words_result_num?: number;
  error_code?: number;
  error_msg?: string;
}

interface BaiduTokenResponse {
  access_token: string;
}

export class CloudOCRUtils {
  private static readonly API_KEY = 'Qbkvfdg8ukceY7BjweBjrbt6';
  private static readonly SECRET_KEY = 'HkN7DDAn2oM33WsziSGJpjXR1aGYCn4p';

  /**
   * 图片识别入口
   */
  static async recognizeTable(imageUri: string): Promise<string> {
    try {
      const token = await CloudOCRUtils.getAccessToken();
      if (!token) return "ERROR:Token 获取失败";
      const base64Img = await CloudOCRUtils.imageToBase64(imageUri);
      return await CloudOCRUtils.sendAccurateRequest(token, base64Img);
    } catch (e) {
      console.error('图片识别异常:', JSON.stringify(e));
      return "ERROR:识别异常";
    }
  }

  /**
   * PDF 识别入口 (支持多页)
   */
  static async recognizePdf(pdfUri: string): Promise<string> {
    try {
      const token = await CloudOCRUtils.getAccessToken();
      if (!token) return "ERROR:Token 获取失败";

      const base64Pdf = await CloudOCRUtils.fileToBase64(pdfUri);
      let fullResult = "";
      const MAX_PAGES = 5;

      for (let page = 1; page <= MAX_PAGES; page++) {
        const pageResult = await CloudOCRUtils.sendAccurateRequest(token, base64Pdf, true, page);

        if (pageResult.includes("百度报错") || pageResult.includes("接口请求失败")) {
          if (page === 1) return pageResult;
          break;
        }
        fullResult += `\n【第 ${page} 页】\n------------------\n` + pageResult + "\n";
      }
      return fullResult || "ERROR:PDF 未识别到内容";
    } catch (e) {
      console.error('PDF识别异常:', JSON.stringify(e));
      return "ERROR:PDF 识别失败";
    }
  }

  /**
   * 发送请求 (高精度接口)
   */
  private static async sendAccurateRequest(token: string, base64Data: string, isPdf: boolean = false, pageNum: number = 1): Promise<string> {
    const url = `https://aip.baidubce.com/rest/2.0/ocr/v1/accurate_basic?access_token=${token}`;
    const req = http.createHttp();

    // paragraph=true: 尝试按段落整理，减少碎片
    // vertexes_location=true: (可选) 获取更详细坐标，普通 location 就够用了
    let body = `detect_direction=true&vertexes_location=true&`;
    if (isPdf) {
      body += `pdf_file=${encodeURIComponent(base64Data)}&pdf_file_num=${pageNum}`;
    } else {
      body += `image=${encodeURIComponent(base64Data)}`;
    }

    try {
      const response = await req.request(url, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/x-www-form-urlencoded' },
        extraData: body,
        connectTimeout: 30000,
        readTimeout: 30000
      });

      if (response.responseCode === 200) {
        const res = JSON.parse(response.result as string) as GeneralOCRResponse;

        if (res.error_code) {
          return `ERROR:百度报错: ${res.error_msg} (Code: ${res.error_code})`;
        }

        if (res.words_result) {
          // 🔥 打印日志，确认是否拿到了数据
          console.info(`[OCR Debug] 拿到 ${res.words_result.length} 行文字`);

          // 调用排版算法
          return CloudOCRUtils.formatSmartLayout(res.words_result);
        }
      }
      return `ERROR:接口请求失败: ${response.responseCode}`;
    } catch (e) {
      console.error('网络请求出错:', JSON.stringify(e));
      return "ERROR:网络请求出错";
    }
  }

  /**
   * 🔥🔥🔥【核心排版算法】(修复版)
   * 包含“自动降级”逻辑，防止白屏
   */
  private static formatSmartLayout(items: OCRResultItem[]): string {
    if (!items || items.length === 0) return "";

    // 1. 定义行高容差 (像素)
    // 如果两个文字块的高度差小于这个值 (比如 15px)，就认为它们在同一行
    const Y_TOLERANCE = 15;

    // 2. 先按 Top (Y轴) 从上到下粗略排序
    // 注意：加上 ?. 和 || 0 防止崩溃
    items.sort((a, b) => (a.location?.top || 0) - (b.location?.top || 0));

    // 3. 开始分组 (把同一行的归到一起)
    let rows: OCRResultItem[][] = [];
    let currentRow: OCRResultItem[] = [];
    let currentY = -999;

    for (let item of items) {
      const currentTop = item.location?.top || 0;

      // 如果是第一个，或者与当前行的高度差超过了容差 -> 开启新的一行
      if (currentY === -999 || Math.abs(currentTop - currentY) > Y_TOLERANCE) {
        if (currentRow.length > 0) {
          rows.push(currentRow);
        }
        currentRow = [item];
        currentY = currentTop; // 更新当前行的基准高度
      } else {
        // 否则，认为是同一行，加入当前行
        currentRow.push(item);
      }
    }
    // 加入最后一行
    if (currentRow.length > 0) rows.push(currentRow);

    // 4. 拼接最终文本
    let finalString = "";

    for (let row of rows) {
      // 4.1 行内排序：按 Left (X轴) 从左到右排，防止左右颠倒
      row.sort((a, b) => (a.location?.left || 0) - (b.location?.left || 0));

      let lineText = "";

      // 4.2 智能拼接行内元素
      for (let i = 0; i < row.length; i++) {
        const item = row[i];
        let words = item.words.trim();

        // (可选) 细节优化：给中文和数字之间加空格
        words = words.replace(/([\u4e00-\u9fa5])([0-9a-zA-Z])/g, '$1 $2');
        words = words.replace(/([0-9a-zA-Z])([\u4e00-\u9fa5])/g, '$1 $2');

        if (i > 0) {
          // 计算当前块和前一个块的距离
          const prev = row[i-1];
          const prevRight = (prev.location?.left || 0) + (prev.location?.width || 0);
          const currentLeft = item.location?.left || 0;
          const distance = currentLeft - prevRight;

          // 如果距离比较远，加多几个空格模拟排版
          const spaces = distance > 50 ? "    " : "  ";

          // 如果这一行看起来像表格数据（包含数字），可以用竖线分隔
          //if (/\d/.test(words)) {
          //  lineText += " | " + words;
          //} else {
            lineText += spaces + words;
          //}
        } else {
          // 第一个元素
          lineText += words;
        }
      }

      // 🔥 强制换行：处理完一行 visual row 后，加上 \n
      finalString += lineText + "\n";

      // 4.3 识别到表头，加个分割线装装样子
      if (lineText.includes("项目") && lineText.includes("结果")) {
        finalString += "----------------------------------------\n";
      }
    }

    return finalString;
  }

  // ================= 辅助方法 =================
  private static async getAccessToken(): Promise<string> {
    const url = `https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=${CloudOCRUtils.API_KEY}&client_secret=${CloudOCRUtils.SECRET_KEY}`;
    const req = http.createHttp();
    const response = await req.request(url, { method: http.RequestMethod.POST });
    if (response.responseCode === 200) {
      const result = JSON.parse(response.result as string) as BaiduTokenResponse;
      return result.access_token;
    }
    return "";
  }

  private static async imageToBase64(uri: string): Promise<string> {
    try {
      let file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      let stat = fs.statSync(file.fd);
      let buffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);
      let helper = new util.Base64Helper();
      let u8Arr = new Uint8Array(buffer);
      return helper.encodeToStringSync(u8Arr);
    } catch (e) {
      return "";
    }
  }

  private static async fileToBase64(uri: string): Promise<string> {
    try {
      let file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      let stat = fs.statSync(file.fd);
      if (stat.size > 4 * 1024 * 1024) {
        fs.closeSync(file);
        throw new Error("文件过大");
      }
      let buffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);
      let helper = new util.Base64Helper();
      let u8Arr = new Uint8Array(buffer);
      return helper.encodeToStringSync(u8Arr);
    } catch (e) {
      return "";
    }
  }
}