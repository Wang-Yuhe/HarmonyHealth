import router from '@ohos.router';
import { MedicalRecordForm } from '../common/components/MedicalRecordForm';
import { MedicalRecord } from '../common/model/MedicalRecordModel';
import promptAction from '@ohos.promptAction';

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
  // 删除病历的逻辑
  deleteRecord() {
    // 1. 弹出确认框，防止手滑误删
    promptAction.showDialog({
      title: '删除确认',
      message: '确定要永久删除这条病历记录吗？此操作无法撤销。',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确认删除', color: '#FF0000' } // 红色警示
      ]
    }).then((resp) => {
      // resp.index === 1 表示点击了第二个按钮（确认删除）
      if (resp.index === 1) {
        this.performDelete();
      }
    });
  }
  // 执行真正的删除操作
  performDelete() {
    const index = this.records.findIndex(item => item.id === this.recordId);

    if (index !== -1) {
      // 2. 从数组中移除该元素
      this.records.splice(index, 1);

      // 3. 强制刷新数组引用
      // 这一步能保证返回列表页时，列表会自动刷新
      this.records = [...this.records];

      promptAction.showToast({ message: '已删除' });

      // 4. 返回列表页
      router.back();
    } else {
      promptAction.showToast({ message: '删除失败：未找到记录' });
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
      // --- 中间表单区域 (使用 Column 包裹，确保按钮在底部) ---
      Column() {
        // 复用表单组件 (注意设置 layoutWeight 让它占据中间剩余空间)
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
          .margin({ top: 10, bottom: 20 }) // 上下留白
          .onClick(() => this.deleteRecord()) // 绑定删除事件
      }
      .layoutWeight(1) // 让整个内容区撑开
      .width('100%')
    }
    .height('100%')
    .backgroundColor('#F1F3F5')
    }
  }