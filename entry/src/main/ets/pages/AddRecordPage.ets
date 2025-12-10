import router from '@ohos.router';
import { MedicalRecordForm } from '../common/components/MedicalRecordForm';
import { MedicalRecord } from '../common/model/MedicalRecordModel';

@Entry
@Component
struct AddRecordPage {
  // 定义空状态
  @State title: string = '';
  @State content: string = '';
  @State selectedImage: string = '';
  @State pdfUri: string = '';
  @State hospital: string = '';
  @State selectedDate: Date = new Date();
  @State tags: string[] = [''];
  @StorageLink('MedicalRecords') records: MedicalRecord[] = [];
  saveNewRecord() {
    if (!this.title) return;
    const dateStr = this.selectedDate.toISOString();
    const newRecord = new MedicalRecord(
      this.title, dateStr, this.selectedImage,this.pdfUri,
      this.content, this.tags, this.hospital
    );
    // 更新全局数组
    this.records = [...this.records, newRecord];
    console.info('新增病历成功:', JSON.stringify(newRecord));

    router.back();
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Image($r('app.media.backButton')).width(24).onClick(() => router.back())
        Text('录入新病历').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 16 })
        Blank()
        Button('保存').onClick(() => this.saveNewRecord())
      }.padding(16).width('100%').backgroundColor(Color.White)

      // 引入公共表单，使用 $ 符号传递引用
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