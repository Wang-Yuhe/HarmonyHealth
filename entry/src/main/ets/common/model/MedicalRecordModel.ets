export class MedicalRecord {
  id: string;
  title: string;          // 病历标题 (如：xx医院检查单)
  date: string;             // 就诊日期
  imageUri: string;       // 病历图片路径
  pdfUri: string;         // PDF 文件的路径
  content: string;        // 识别出的详细文本内容
  tags: string[];         // 分类标签 (如：内科, 血液检查)
  hospital: string;       // 医院名称

  constructor(title: string, date: string, imageUri: string, pdfUri: string, content: string, tags: string[], hospital: string) {
    this.id = Math.random().toString(36).slice(2); // 简单生成ID
    this.title = title;
    this.date = date;
    this.imageUri = imageUri;
    this.pdfUri = pdfUri || '';
    this.content = content;
    this.tags = tags;
    this.hospital = hospital;
  }
}