import router from '@ohos.router';
import { MedicalRecordForm } from '../common/components/MedicalRecordForm';
import { MedicalRecord } from '../common/model/MedicalRecordModel';
import promptAction from '@ohos.promptAction';
import { HealthDB } from '../database/HealthDB';
interface PageParams {
  record: MedicalRecord;
}
@Entry
@Component
struct RecordEditPage {
  // 状态变量
  @State recordId: string = '';
  @State title: string = '';
  @State content: string = '';
  @State selectedImage: string = '';
  @State pdfUri: string = '';
  @State hospital: string = '';
  @State selectedDate: Date = new Date();
  @State tags: string[] = [];
  // 1. 获取当前登录用户名 (不再直接链接 MedicalRecords 数组)
  @StorageProp('currentUser') currentUser: string = '';
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
      // 兼容处理：确保日期正确转换
      this.selectedDate = new Date(rec.date);
      this.tags = rec.tags;
    }
  }
  // 2. 更新逻辑改为调用数据库
  async updateRecord() {
    let targetUser = this.currentUser || 'admin'; // 兜底
    try {
      const dateStr = this.selectedDate.toISOString();

      // 构建更新对象
      const updatedRecord = new MedicalRecord(
        this.title,
        dateStr,
        this.selectedImage,
        this.pdfUri,
        this.content,
        this.tags,
        this.hospital
      );
      // 重要：ID 必须保持不变，数据库据此查找记录
      updatedRecord.id = this.recordId;

      // 调用数据库更新方法
      const success = await HealthDB.getInstance().updateMedicalRecord(targetUser, updatedRecord);

      if (success) {
        promptAction.showToast({ message: '更新成功' });
        router.back(); // 返回列表页，列表页会自动从数据库重新加载
      } else {
        promptAction.showToast({ message: '更新失败' });
      }
    } catch (e) {
      console.error('更新病历异常:', e);
      promptAction.showToast({ message: '系统错误' });
    }
  }
  // 删除确认弹窗 (保持不变)
  deleteRecord() {
    promptAction.showDialog({
      title: '删除确认',
      message: '确定要永久删除这条病历记录吗？此操作无法撤销。',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确认删除', color: '#FF0000' }
      ]
    }).then((resp) => {
      if (resp.index === 1) {
        this.performDelete();
      }
    });
  }
  // 3. 删除逻辑改为调用数据库
  async performDelete() {
    try {
      // 调用数据库删除方法
      const success = await HealthDB.getInstance().deleteMedicalRecord(this.recordId);
      if (success) {
        promptAction.showToast({ message: '已删除' });
        router.back(); // 返回列表页
      } else {
        promptAction.showToast({ message: '删除失败' });
      }
    } catch (e) {
      console.error('删除病历异常:', e);
      promptAction.showToast({ message: '系统错误' });
    }
  }
  build() {
    Column() {
      // 标题栏
      Row() {
        Image($r('app.media.backButton')).width(24).onClick(() => router.back())
        Text('病历详情').fontSize(9).fontWeight(FontWeight.Bold).margin({ left: 16 }).fontFamily('monospace')
        Blank()
        // 更新按钮
        Button('更新')
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#007DFF')
          .height(32)
          .onClick(() => this.updateRecord())
      }
      .padding(16).width('100%').backgroundColor(Color.White)
      // --- 中间表单区域 ---
      Column() {
        // 复用表单组件
        MedicalRecordForm({
          title: $title,
          content: $content,
          selectedImage: $selectedImage,
          pdfUri: $pdfUri,
          hospital: $hospital,
          selectedDate: $selectedDate,
          tags: $tags
        })
          .layoutWeight(1) // 占满剩余空间

        // --- 底部删除按钮 ---
        Button('删除此病历')
          .width('90%')
          .height(45)
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#FF4D4F') // 红色背景
          .margin({ top: 10, bottom: 20 })
          .onClick(() => this.deleteRecord())
      }
      .layoutWeight(1)
      .width('100%')
    }
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}