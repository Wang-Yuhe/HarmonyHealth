import { textRecognition } from '@kit.CoreVisionKit'; // OCR 能力
import { image } from '@kit.ImageKit'; // 图片处理
import fs from '@ohos.file.fs'; // 文件系统
import { CloudOCRUtils } from './CloudOCRUtils';
import { pdfService } from '@kit.PDFKit';

export class OCRUtils {

  /**
   * 识别图片 (外部调用)
   */
  static async recognizeText(imageUri: string): Promise<string> {
    if (!imageUri) return "未选择图片";

    try {
      // 🟢 1. 第一尝试：本地 CoreVisionKit 识别 (真机超快，不费流量)
      const pixelMap = await OCRUtils.getPixelMapByUri(imageUri);

      if (pixelMap) {
        // 调用本地识别逻辑
        const localResult = await OCRUtils._recognizePixelMap(pixelMap);

        // 如果识别到了内容，直接返回，流程结束
        if (localResult && localResult.length > 0) {
          return localResult;
        }
      }

      // 如果 pixelMap 为空，或者本地识别结果为空字符串（模拟器常见情况），
      // 手动抛出一个错误，强行跳转到 catch 块
      throw new Error("本地 OCR 引擎未返回结果");

    } catch (e) {
      // 🟡 2. 降级处理：捕获本地失败异常，转为云端识别 (模拟器兜底)
      console.warn(`本地识别不可用: ${JSON.stringify(e)}`);
      console.info('正在切换至百度云识别...');

      try {
        // 调用云端接口
        const cloudResult = await CloudOCRUtils.recognizeTable(imageUri);
        return cloudResult;
      } catch (cloudError) {
        // 🔴 3. 终极兜底：云端也挂了
        console.error('云端识别失败:', JSON.stringify(cloudError));
        return "识别失败：本地引擎不可用且云端连接超时";
      }
    }
  }

  /**
   * 真实实现：识别 PDF (外部调用)
   * 思路：打开PDF -> 遍历所有页 -> 每页转为图片 -> OCR识别 -> 拼接结果
   */
  // entry/src/main/ets/common/OCRUtils.ets

  static async recognizePdf(pdfUri: string): Promise<string> {
    if (!pdfUri) return "未选择 PDF 文件";

    let document: pdfService.PdfDocument | undefined;

    try {
      // 🔍 1.【环境检查】模拟器没有 pdfService，直接抛出错误进入 catch 走云端
      if (!canIUse("SystemCapability.OfficeService.PDFService.Core")) {
        throw new Error("当前设备不支持 PDF 能力 (可能是模拟器)");
      }

      // 🔍 2.【本地识别流程】(真机走这里)
      document = new pdfService.PdfDocument();
      await document.loadDocument(pdfUri);

      const pageCount = document.getPageCount();
      if (pageCount === 0) return "PDF 文件为空";

      let fullResult = "";
      const maxPages = Math.min(pageCount, 5);

      for (let i = 0; i < maxPages; i++) {
        const page = document.getPage(i);
        const width = page.getWidth();
        const height = page.getHeight();

        // 创建 buffer
        const bufferSize = width * height * 4;
        const buffer = new ArrayBuffer(bufferSize);

        // 创建 PixelMap
        const pixelMap = await image.createPixelMap(buffer, {
          size: { width: width, height: height },
          pixelFormat: image.PixelMapFormat.RGBA_8888,
          editable: true
        });

        // 渲染页面 (使用 ESObject 绕过类型检查)
        await (page as ESObject).render(pixelMap);

        // OCR 识别
        const pageText = await OCRUtils._recognizePixelMap(pixelMap);
        fullResult += `【第 ${i + 1} 页】\n${pageText}\n\n`;

        await pixelMap.release();
      }

      return fullResult || "未识别到文字";

    } catch (e) {
      // =======================================================
      // 🔥 3.【降级处理】本地失败（或模拟器），自动切换云端
      // =======================================================
      console.warn(`本地 PDF 识别不可用: ${JSON.stringify(e)}`);
      console.info('正在切换至云端 PDF 识别...');

      try {
        // 调用 CloudOCRUtils 发送给百度云
        const cloudResult = await CloudOCRUtils.recognizePdf(pdfUri);

        // 如果云端返回包含“失败”或“报错”的字样，说明云端也不行
        if (cloudResult.includes("失败") || cloudResult.includes("异常")) {
          // 这里可以返回一个 mock 数据兜底，或者直接返回错误信息
          return cloudResult;
        }

        return cloudResult;

      } catch (cloudError) {
        console.error('云端识别也挂了:', JSON.stringify(cloudError));
        return `PDF 识别彻底失败: 请检查网络或真机环境。`;
      }

    } finally {
      // 资源释放
      if (document) {
        // document.destroy();
      }
    }
  }

  /**
   * 🔒 私有核心方法：传入 PixelMap，返回识别文字
   * (图片和 PDF 最终都走这里)
   */
  private static async _recognizePixelMap(pixelMap: image.PixelMap): Promise<string> {
    try {
      const visionInfo: textRecognition.VisionInfo = {
        pixelMap: pixelMap
      };

      // 调用 CoreVisionKit
      const response = await textRecognition.recognizeText(visionInfo);

      // 简单处理：如果识别结果为空
      if (!response.value) return "";

      return response.value;
    } catch (e) {
      console.warn('CoreVisionKit 调用失败:', e);
      return "";
    }
  }

  /**
   * 辅助：URI 转 PixelMap
   */
  private static async getPixelMapByUri(uri: string): Promise<image.PixelMap | undefined> {
    let file: fs.File | undefined;
    try {
      file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      const imageSource = image.createImageSource(file.fd);
      return await imageSource.createPixelMap();
    } catch (err) {
      return undefined;
    } finally {
      if (file) fs.closeSync(file);
    }
  }
}