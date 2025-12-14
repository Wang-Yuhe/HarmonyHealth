import picker from '@ohos.file.picker';
import promptAction from '@ohos.promptAction';
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
      console.error('图片选择失败', err);
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
      console.error('文件选择失败', err);
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
    try {
      let text = '';

      // 分支逻辑：判断是图片还是 PDF
      if (this.selectedImage) {
        text = await OCRUtils.recognizeText(this.selectedImage);
      } else if (this.pdfUri) {
        text = await OCRUtils.recognizePdf(this.pdfUri);
      } else {
        promptAction.showToast({ message: '请先上传文件' });
        return;
      }

      this.content = text;
      const info: ParsedInfo = RecordParser.parse(text);
      // 只有当输入框是空的时候才自动填，防止覆盖用户已经手写的
      if (info.hospital && !this.hospital) {
        this.hospital = info.hospital;
      }

      if (info.title && !this.title) {
        this.title = info.title;
      }

      if (info.date) {
        this.selectedDate = info.date;
      }

      promptAction.showToast({ message: '识别成功并已自动填写！' });
    } catch(e) {
      promptAction.showToast({ message: '识别失败' });
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
          TextArea({ placeholder: '病历详情...', text: this.content })
            .height(150)
            .onChange((val) => this.content = val)

          Text('标签: ' + this.tags.join(', ')).fontSize(14).fontColor('#666')
        }.padding(15).backgroundColor(Color.White).borderRadius(12)
      }.padding(16)
    }
  }
}