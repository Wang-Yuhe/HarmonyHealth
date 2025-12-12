import http from '@ohos.net.http';
import fs from '@ohos.file.fs';
import util from '@ohos.util';

// 定义每一行文字的结构
interface OCRResultItem {
  words: string;
}

// 定义 OCR 接口返回的整体结构
interface BaiduOCRResponse {
  access_token: string | PromiseLike<string>;
  words_result?: OCRResultItem[]; // 这是一个数组
  words_result_num?: number;
  error_code?: number;
  error_msg?: string;
}

export class CloudOCRUtils {
  private static readonly API_KEY = 'KZyIqdDjtIULqBa0Y9Q5ZTF1';
  private static readonly SECRET_KEY = 'mZash5BI3ZSffjcI2oLXw93zF85TOPP7';

  /**
   * 核心入口：识别图片
   */
  static async recognizeImage(imageUri: string): Promise<string> {
    try {
      // 1. 获取 Access Token
      const token = await CloudOCRUtils.getAccessToken();
      if (!token) return "网络连接失败或 Key 配置错误";

      // 2. 读取图片文件并转为 Base64
      const base64Img = await CloudOCRUtils.imageToBase64(imageUri);

      // 3. 发送请求给百度
      const result = await CloudOCRUtils.sendOCRRequest(token, base64Img);
      return result;
    } catch (e) {
      console.error('云端识别出错:', JSON.stringify(e));
      return "云端识别失败，请检查网络";
    }
  }

  /**
   * 云端 PDF 识别
   */
  static async recognizePdf(pdfUri: string): Promise<string> {
    try {
      // 1. 获取 Token
      const token = await CloudOCRUtils.getAccessToken();
      if (!token) return "Token 获取失败";

      // 2. 读取 PDF 文件转 Base64
      // 注意：这里复用之前的 fileToBase64 方法即可，逻辑一样
      const base64Pdf = await CloudOCRUtils.fileToBase64(pdfUri);

      // 3. 发送请求 (参数不同)
      return await CloudOCRUtils.sendPdfRequest(token, base64Pdf);

    } catch (e) {
      console.error('云端PDF识别出错:', JSON.stringify(e));
      return "云端 PDF 识别失败，文件可能过大";
    }
  }
  /**
   *  PDF 请求给百度
   */
  private static async sendPdfRequest(token: string, base64Pdf: string): Promise<string> {
    const url = `https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic?access_token=${token}`;

    const req = http.createHttp();

    // ⚠️ 百度规定：PDF文件参数名为 pdf_file，不是 image
    const body = `pdf_file=${encodeURIComponent(base64Pdf)}`;

    const response = await req.request(url, {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/x-www-form-urlencoded' },
      extraData: body
    });

    if (response.responseCode === 200) {
      // 使用你定义的 JsonUtils 解析
      // 注意：你需要确保你的 JsonUtils 已经 import 进来
      const resObj = JSON.parse(response.result as string) as BaiduOCRResponse;

      if (resObj.words_result) {
        let text = "";
        for (let item of resObj.words_result) {
          text += item.words + "\n";
        }
        return text || "PDF 中未识别到文字";
      }

      if (resObj.error_msg) {
        return `百度报错: ${resObj.error_msg}`;
      }
    }
    return "云端接口返回异常";
  }
  /**
   * 步骤1：获取百度 Access Token
   */
  private static async getAccessToken(): Promise<string> {
    const url = `https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=${CloudOCRUtils.API_KEY}&client_secret=${CloudOCRUtils.SECRET_KEY}`;

    const req = http.createHttp();
    const response = await req.request(url, { method: http.RequestMethod.POST });

    if (response.responseCode === 200) {
      const result = JSON.parse(response.result as string) as BaiduOCRResponse;
      return result.access_token;
    }
    return "";
  }

  /**
   * 步骤2：调用通用文字识别 API
   */
  private static async sendOCRRequest(token: string, base64Img: string): Promise<string> {
    const url = `https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic?access_token=${token}`;

    const req = http.createHttp();
    // 百度要求 Content-Type 为 application/x-www-form-urlencoded
    // image 参数需要 URL Encode
    const body = `image=${encodeURIComponent(base64Img)}`;

    const response = await req.request(url, {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/x-www-form-urlencoded' },
      extraData: body
    });
    console.info('百度OCR HTTP状态码:', response.responseCode);
    console.info('百度OCR 返回结果:', response.result);
    if (response.responseCode === 200) {
      const resObj = JSON.parse(response.result as string) as BaiduOCRResponse;

      // 检查是否有错误码
      if (resObj.error_code) {
        console.error(`百度OCR报错: Code=${resObj.error_code}, Msg=${resObj.error_msg}`);
        return `识别失败: ${resObj.error_msg}`;
      }
      // 解析百度返回的 JSON
      if (resObj.words_result) {
        let text = "";
        // 拼接每一行文字
        for (let item of resObj.words_result) {
          text += item.words + "\n";
        }
        return text || "未识别到文字";
      }
    }
    return "识别接口返回异常";
  }

  /**
   * 辅助：读取文件转 Base64
   */
  private static async imageToBase64(uri: string): Promise<string> {
    let file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
    let stat = fs.statSync(file.fd);
    let buffer = new ArrayBuffer(stat.size);
    fs.readSync(file.fd, buffer);
    fs.closeSync(file);

    // 使用工具类转 Base64
    let helper = new util.Base64Helper();
    // 将 ArrayBuffer 转为 Uint8Array 再转 Base64
    let u8Arr = new Uint8Array(buffer);
    let base64 = helper.encodeToStringSync(u8Arr);
    return base64;
  }
  private static async fileToBase64(uri: string): Promise<string> {
    try {
      let file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      let stat = fs.statSync(file.fd);

      // 限制大小：百度普通接口通常限制 4MB 左右，太大会报错
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
      console.error('文件转Base64失败:', e);
      return "";
    }
  }
}