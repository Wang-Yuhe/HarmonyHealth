import picker from '@ohos.file.picker';
import promptAction from '@ohos.promptAction';
import { CloudOCRUtils } from '../utils/CloudOCRUtils';
import { OCRUtils } from '../utils/OCRUtils';
import { ParsedInfo, RecordParser } from './RecordParser';

@Component
export struct MedicalRecordForm {
  // 使用 @Link 实现双向绑定，父页面修改这里也会变，这里修改父页面也会变
  @Link title: string;
  @Link content: string;
  @Link selectedImage: string;
  @Link hospital: string;
  @Link selectedDate: Date;
  @Link tags: string[];
  @Link pdfUri: string;
  @State isRecognizing: boolean = false;

  // 用于暂存弹窗显示的文字
  @State dialogTitle: string = '';
  @State dialogMessage: string = '';

  // 🔥 注册自定义弹窗控制器
  dialogController: CustomDialogController = new CustomDialogController({
    builder: WarningDialog({
      title: this.dialogTitle,
      message: this.dialogMessage
    }),
    autoCancel: true, // 点击空白处是否关闭
    alignment: DialogAlignment.Center
  });

  private showCustomAlert(title: string, msg: string) {
    // 1. 设置显示的文字
    this.dialogTitle = title;
    this.dialogMessage = msg;

    // 2. 打开自定义弹窗
    this.dialogController.open();
  }

  // 选择图片逻辑
  async selectImage() {
    try {
      let photoPicker = new picker.PhotoViewPicker();
      let result = await photoPicker.select({
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      });
      if (result.photoUris.length > 0) {
        this.selectedImage = result.photoUris[0];
        this.pdfUri = ''; // 互斥：选了图片就清空 PDF
        this.askForOCR('图片');
      }
    } catch (err) {
      // 捕获文件选择器本身的错误（如权限被拒）
      console.error('图片选择异常:', JSON.stringify(err));
      this.showCustomAlert('无法选择图片', '读取相册失败，请检查是否授予了相关权限。');
    }
  }
  // 选择 PDF 文件
  async selectPDF() {
    try {
      let docPicker = new picker.DocumentViewPicker();
      let result = await docPicker.select({
        maxSelectNumber: 1,
        defaultFilePathUri: ''
        // 注意：不同 API 版本 fileSuffixFilters 写法不同，通常 DocumentPicker 默认允许选所有文件
      });

      if (result.length > 0) {
        this.pdfUri = result[0];
        this.selectedImage = ''; // 互斥：选了 PDF 就清空图片
        this.askForOCR('PDF 文件');
      }
    } catch (err) {
      console.error('文件选择异常:', JSON.stringify(err));
      this.showCustomAlert('无法导入文档', '文件读取失败，请重试。');
    }
  }
  askForOCR(type: string) {
    promptAction.showDialog({
      title: '智能助手',
      message: `检测到您上传了 ${type}，是否智能识别内容？`,
      buttons: [{ text: '取消', color: '#666' }, { text: '识别', color: '#007DFF' }]
    }).then((resp) => {
      if (resp.index === 1) this.startOCR();
    });
  }

  async startOCR() {
    this.isRecognizing = true;
    this.content = ""; // 先清空

    try {
      let text = '';

      if (this.selectedImage) {
        text = await CloudOCRUtils.recognizeTable(this.selectedImage);
      } else if (this.pdfUri) {
        text = await CloudOCRUtils.recognizePdf(this.pdfUri);
      } else {
        this.showCustomAlert('提示', '请先上传文件');
        return;
      }

      // 🔥🔥🔥【关键修改】只拦截带 "ERROR:" 前缀的系统错误
      // 这样无论病历内容里有多少个“异常”或“失败”，都不会误触发弹窗了
      if (text.startsWith('ERROR:')) {
        // 去掉前缀再显示给用户，体验更好
        const showMsg = text.replace('ERROR:', '').trim();
        this.showCustomAlert('识别中断', showMsg);
      } else {
        // 成功！
        this.content = text;
        promptAction.showToast({ message: '智能提取成功' });

        // 智能填充
        const info = RecordParser.parse(text);
        if (info.title) this.title = info.title;
        if (info.hospital) this.hospital = info.hospital;
        if (info.date) this.selectedDate = info.date;
      }

    } catch(e) {
      this.showCustomAlert('系统异常', e.message);
    } finally {
      this.isRecognizing = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 15 }) {
        // 1. 文件上传区域 (整合了 图片 和 PDF)
        Column() {
          // 情况 A: 已选择图片
          if (this.selectedImage) {
            Image(this.selectedImage)
              .width('100%').height(200).objectFit(ImageFit.Contain)
              .onClick(() => this.selectImage()) // 点击更换

            Text('点击图片可更换').fontSize(12).fontColor('#999').margin({top: 5})
          }
          // 情况 B: 已选择 PDF
          else if (this.pdfUri) {
            Column() {
              // 这里可以用一个 PDF 的小图标，如果没有就用 Text 代替
              Text('📄 PDF 文档').fontSize(40)
              Text(this.pdfUri.split('/').pop()) // 显示文件名
                .fontSize(14).margin({ top: 10 }).fontColor('#333')
                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%').height(150)
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#FFF4E6') // 淡橙色背景区分
            .onClick(() => this.selectPDF()) // 点击更换

            Text('点击文档可更换').fontSize(12).fontColor('#999').margin({top: 5})
          }
          // 情况 C: 未选择
          else {
            Row({ space: 20 }) {
              // 拍照/选图按钮
              Column() {
                Text('📷').fontSize(30)
                Text('照片/拍照').fontSize(12).fontColor('#666').margin({top:5})
              }
              .onClick(() => this.selectImage())
              .layoutWeight(1).height(100).backgroundColor('#F1F3F5')
              .justifyContent(FlexAlign.Center).borderRadius(8)

              // 选 PDF 按钮
              Column() {
                Text('📂').fontSize(30)
                Text('导入 PDF').fontSize(12).fontColor('#666').margin({top:5})
              }
              .onClick(() => this.selectPDF())
              .layoutWeight(1).height(100).backgroundColor('#F1F3F5')
              .justifyContent(FlexAlign.Center).borderRadius(8)
            }
          }

          // OCR 按钮 (只要有任意文件选中就显示)
          if (this.selectedImage || this.pdfUri) {
            Button(this.isRecognizing ? 'AI 识别中...' : '智能内容提取')
              .margin({ top: 15 }).width('100%')
              .backgroundColor(this.isRecognizing ? '#CCCCCC' : '#007DFF')
              .onClick(() => this.startOCR())
          }
        }
        .padding(15).backgroundColor(Color.White).borderRadius(12)

        // 2. 表单区域
        Column({ space: 10 }) {
          Text('基本信息').fontWeight(FontWeight.Bold)
          TextInput({ placeholder: '标题', text: this.title })
            .onChange((val) => this.title = val)
          TextInput({ placeholder: '医院', text: this.hospital })
            .onChange((val) => this.hospital = val)

          Row() {
            Text('日期：').fontSize(16)
            Text(this.selectedDate.toISOString().split('T')[0]).fontColor('#007DFF')
              .onClick(() => {
                DatePickerDialog.show({
                  selected: this.selectedDate,
                  onAccept: (val) => this.selectedDate.setFullYear(val.year, val.month, val.day)
                })
              })
          }.width('100%').padding({ top: 5 })
        }.padding(15).backgroundColor(Color.White).borderRadius(12)

        // 3. 详情与标签
        Column({ space: 10 }) {
          Text('详细内容').fontWeight(FontWeight.Bold)

          TextArea({ placeholder: '识别结果...', text: this.content })
            .height(300) // 高度设高一点，方便看表格
            .backgroundColor('#F9F9F9')
            .onChange((val) => this.content = val)
            // 🔥🔥🔥【关键修改】设置等宽字体
            .fontFamily('monospace')
            .fontSize(9) // 稍微改小字体，防止表格太宽换行
        }.padding(15).backgroundColor(Color.White).borderRadius(12)
      }.padding(16)
    }
  }
}
// --- 自定义警告弹窗组件 ---
@CustomDialog
struct WarningDialog {
  controller: CustomDialogController;
  title: string = '';
  message: string = '';

  // 🔥 1. 定义 X 轴偏移量状态
  @State offsetX: number = 0;

  // 🔥 2. 在弹窗显示时触发动画
  aboutToAppear() {
    // 延迟 50ms 确保弹窗已渲染，然后开始抖动
    setTimeout(() => {
      this.startShake();
    }, 50);
  }

  // 🔥 3. 定义抖动动画逻辑
  startShake() {
    // 使用 keyframeAnimateTo 定义一组连续动作
    this.getUIContext().keyframeAnimateTo({ iterations: 1 }, [
      // 第一阶段：快速向左
      { duration: 50, event: () => { this.offsetX = -10 } },
      // 第二阶段：快速向右
      { duration: 50, event: () => { this.offsetX = 10 } },
      // 第三阶段：幅度减小向左
      { duration: 50, event: () => { this.offsetX = -5 } },
      // 第四阶段：幅度减小向右
      { duration: 50, event: () => { this.offsetX = 5 } },
      // 第五阶段：回正
      { duration: 50, event: () => { this.offsetX = 0 } },
    ]);
  }

  build() {
    Column() {
      // 1. 顶部图标
      Text('⚠️')
        .fontSize(40)
        .margin({ top: 20, bottom: 10 })

      // 2. 标题
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .margin({ bottom: 8 })

      // 3. 内容
      Text(this.message)
        .fontSize(16)
        .fontColor('#FF4D4F')
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .lineHeight(24)
        .margin({ bottom: 20, left: 15, right: 15 })

      // 4. 底部按钮
      Button('知道了')
        .width('80%')
        .height(40)
        .backgroundColor('#F5F5F5')
        .fontColor('#666')
        .onClick(() => {
          this.controller.close();
        })
        .margin({ bottom: 20 })
    }
    .backgroundColor(Color.White)
    .borderRadius(16)
    .width('80%')
    // 🔥 4. 将偏移量绑定到组件的 translate 属性上
    .translate({ x: this.offsetX })
  }
}