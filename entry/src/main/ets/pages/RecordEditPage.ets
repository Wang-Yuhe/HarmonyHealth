import router from '@ohos.router';
import { MedicalRecordForm } from '../common/components/MedicalRecordForm';
import { MedicalRecord } from '../common/model/MedicalRecordModel';


interface PageParams {
  record: MedicalRecord;
}

@Entry
@Component
struct RecordDetailPage {
  // 状态变量
  @State recordId: string = '';
  @State title: string = '';
  @State content: string = '';
  @State selectedImage: string = '';
  @State pdfUri: string = '';
  @State hospital: string = '';
  @State selectedDate: Date = new Date();
  @State tags: string[] = [];
  @StorageLink('MedicalRecords') records: MedicalRecord[] = [];
  aboutToAppear() {
    const params = router.getParams() as PageParams;
    if (params && params.record) {
      const rec = params.record as MedicalRecord;
      this.recordId = rec.id;
      this.title = rec.title;
      this.content = rec.content;
      this.selectedImage = rec.imageUri;
      this.pdfUri = rec.pdfUri || '';
      this.hospital = rec.hospital;
      this.selectedDate = new Date(rec.date);
      this.tags = rec.tags;
    }
  }

  updateRecord() {
    // 找到当前病历在数组中的索引
    const index = this.records.findIndex(item => item.id === this.recordId);

    if (index !== -1) {
      // 构建更新后的对象
      // 注意：这里需要创建一个新对象来替换旧的
      const dateStr = this.selectedDate.toISOString();
      const updatedRecord = new MedicalRecord(
        this.title,
        dateStr,
        this.selectedImage,
        this.pdfUri,
        this.content,
        this.tags,
        this.hospital
      );
      // 保持 ID 不变
      updatedRecord.id = this.recordId;

      // 替换数组中的元素
      this.records[index] = updatedRecord;
      this.records = [...this.records];
      console.info('更新成功');
      router.back();
    } else {
      console.error('未找到该病历');
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Image($r('app.media.backButton')).width(24).onClick(() => router.back())
        Text('病历详情').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 16 })
        Blank()
        Button('更新').onClick(() => this.updateRecord())
      }.padding(16).width('100%').backgroundColor(Color.White)

      // 复用同一个表单组件
      MedicalRecordForm({
        title: $title,
        content: $content,
        selectedImage: $selectedImage,
        pdfUri: $pdfUri,
        hospital: $hospital,
        selectedDate: $selectedDate,
        tags: $tags
      }).layoutWeight(1)
    }
    .height('100%').backgroundColor('#F1F3F5')
  }
}