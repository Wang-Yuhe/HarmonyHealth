import { textRecognition } from '@kit.CoreVisionKit'; // OCR 能力
import { image } from '@kit.ImageKit'; // 图片处理
import fs from '@ohos.file.fs'; // 文件系统
import { pdfService } from '@kit.PDFKit';

export class OCRUtils {

  /**
   * 识别图片 (外部调用)
   */
  static async recognizeText(imageUri: string): Promise<string> {
    if (!imageUri) return "未选择图片";
    try {
      const pixelMap = await OCRUtils.getPixelMapByUri(imageUri);
      if (!pixelMap) return "图片解析失败";
      return await OCRUtils._recognizePixelMap(pixelMap);
    } catch (e) {
      console.error('图片识别失败:', e);
      return "识别出错";
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
      // 1. 不需要 fs.openSync 了，直接创建文档对象
      document = new pdfService.PdfDocument();

      // 2. 直接传入 pdfUri 字符串
      // API 文档要求：loadDocument(uri: string, password?: string)
      await document.loadDocument(pdfUri);

      const pageCount = document.getPageCount();
      if (pageCount === 0) return "PDF 文件为空";

      let fullResult = "";
      const maxPages = Math.min(pageCount, 5); // 限制页数防止卡顿

      for (let i = 0; i < maxPages; i++) {
        // 获取页面
        const page = document.getPage(i);

        // 创建位图
        const width = page.getWidth();
        const height = page.getHeight();

        // 注意：API 11+ 中 createPixelMap 的参数可能需要根据最新文档调整
        // 这里假设使用标准 ImageKit 创建方法
        // 1. 计算缓冲区大小
        // RGBA_8888 格式每个像素占用 4 个字节
        const bufferSize = width * height * 4;

        // 2. 创建一个空的 ArrayBuffer (全 0，即透明/黑色背景)
        const buffer = new ArrayBuffer(bufferSize);

        // 3. 传入 buffer 和 选项
        const pixelMap = await image.createPixelMap(buffer, {
          size: { width: width, height: height },
          pixelFormat: image.PixelMapFormat.RGBA_8888,
          editable: true // 允许 PDF 渲染写入
        });

        // 渲染页面
        await (page as ESObject).render(pixelMap);

        // OCR 识别
        const pageText = await OCRUtils._recognizePixelMap(pixelMap);
        fullResult += `【第 ${i + 1} 页】\n${pageText}\n\n`;

        // 释放内存
        await pixelMap.release();
      }

      return fullResult || "未识别到文字";

    } catch (e) {
      console.error('PDF 识别异常:', JSON.stringify(e));
      return `PDF 处理失败: ${e.message}`;
    } finally {
      // 3. 资源释放
      if (document) {
        // 这里的销毁方法取决于具体的 API 版本，有些版本不需要手动 destroy
        // 这是一个安全检查，如果你的 SDK 提示没有 destroy 方法，可以注释掉下面这行
        // document.destroy();
      }
      // 不需要 fs.closeSync(file)，因为我们压根没打开 file
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