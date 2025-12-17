import router from '@ohos.router';
import { MedicalRecordForm } from '../common/components/MedicalRecordForm';
import { MedicalRecord } from '../common/model/MedicalRecordModel';
import promptAction from '@ohos.promptAction';
import { HealthDB } from '../database/HealthDB';
@Entry
@Component
struct AddRecordPage {
  // 定义状态变量
  @State title: string = '';
  @State content: string = '';
  @State selectedImage: string = '';
  @State pdfUri: string = '';
  @State hospital: string = '';
  @State selectedDate: Date = new Date();
  // 默认给一个标签，避免空字符串
  @State tags: string[] = ['门诊'];
  // 1. 获取当前登录用户 (用于数据库绑定)
  @StorageProp('currentUser') currentUser: string = '';
  // 2. 移除 @StorageLink('MedicalRecords')，不再操作内存数组，完全依赖数据库
  async saveNewRecord() {
    // 基础校验
    if (!this.title) {
      promptAction.showToast({ message: '请输入病历标题' });
      return;
    }
    // 登录校验
    let targetUser = this.currentUser;
    if (!targetUser) {
      targetUser = 'admin';
      console.warn('未检测到登录用户，自动使用测试账号: admin');
    }

    try {
      // 转换日期
      const dateStr = this.selectedDate.toISOString();

      // 构建对象
      const newRecord = new MedicalRecord(
        this.title,
        dateStr,
        this.selectedImage,
        this.pdfUri,
        this.content,
        this.tags,
        this.hospital
      );

      // 3. 写入数据库
      const rowId = await HealthDB.getInstance().insertMedicalRecord(this.currentUser, newRecord);

      if (rowId > 0) {
        console.info('新增病历成功, RowID:', rowId);
        promptAction.showToast({ message: '保存成功' });
        // 保存成功后返回，列表页会自动刷新
        router.back();
      } else {
        console.error('数据库插入失败');
        promptAction.showToast({ message: '保存失败，请重试' });
      }

    } catch (e) {
      console.error('保存异常:', e);
      promptAction.showToast({ message: '系统错误' });
    }
  }
  build() {
    Column() {
      // 标题栏
      Row() {
        Image($r('app.media.backButton')) // 确保你有这个图标资源
          .width(24)
          .onClick(() => router.back())
        Text('录入新病历')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })

        Blank()

        Button('保存')
          .onClick(() => this.saveNewRecord())
      }
      .padding(16)
      .width('100%')
      .backgroundColor(Color.White)

      // 引入公共表单，使用 $ 符号传递引用
      MedicalRecordForm({
        title: $title,
        content: $content,
        selectedImage: $selectedImage,
        pdfUri: $pdfUri,
        hospital: $hospital,
        selectedDate: $selectedDate,
        tags: $tags
      })
        .layoutWeight(1)
    }
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}