/**
 * @file AskAIPage.ets
 * @description AI 咨询页面 - UI 优化版（AI头像改为小机器人 & 思考状态同步头像）
 */
import { myNavigator } from '../common/components/Navigator';
import common from '@ohos.app.ability.common';
import dataPreferences from '@ohos.data.preferences';
import { HealthAIService } from '../features/ai/service/HealthAIService';

interface ChatMessage {
  id: number;
  from: 'user' | 'ai';
  text: string;
}

@Entry
@Component
struct AskAIPage {
  @State historySnapshot: string = '[]'
  @State messages: ChatMessage[] = []
  @State inputText: string = ''
  @State isThinking: boolean = false

  // 获取 AppStorage 中存储的用户头像，实现与个人中心同步
  @StorageProp('avatar') currentUserAvatar: string = '';

  private nextId: number = 1
  private chatScroller: Scroller = new Scroller()
  private static readonly PREF_FILE: string = 'ask_ai_history'
  private static readonly HISTORY_KEY: string = 'history'
  private preferences?: dataPreferences.Preferences

  aboutToAppear() {
    this.restoreMessages()
  }

  build() {
    Stack() {
      // 背景色
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F7FA') // 更柔和的浅灰背景

      Column() {
        this.HeaderSection()

        Stack({ alignContent: Alignment.Top }) {
          Column() {
            Scroll(this.chatScroller) {
              Column({ space: 16 }) { // 增加气泡间距
                if (this.messages.length === 0) {
                  this.EmptyPlaceholder()
                } else {
                  // 顶部留白，避免被头部遮挡
                  Blank().height(10)

                  ForEach(this.messages, (msg: ChatMessage) => {
                    this.MessageBubble(msg)
                  }, (msg: ChatMessage) => msg.id.toString())
                }

                if (this.isThinking) {
                  this.TypingIndicator()
                }

                // 底部留白，防止被输入框遮挡
                Blank().height(20)
              }
              .width('100%')
              .padding({ left: 16, right: 16 })
            }
            .layoutWeight(1)
            .scrollBar(BarState.Auto)
            .edgeEffect(EdgeEffect.Spring) // 增加回弹效果
          }
          .width('100%')
          .height('100%')

          // 悬浮的新建对话按钮
          this.FloatingToolbar()
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor('#F5F7FA')

        this.InputArea()
      }
      .width('100%')
      .height('100%')
      // 避开底部导航栏高度
      .padding({ bottom: 60 })

      myNavigator()
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private HeaderSection() {
    Column() {
      Row() {
        Column({ space: 6 }) {
          Text('AI 智能问诊')
            .fontSize(26)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
          Text('您的 24 小时专属健康顾问')
            .fontSize(14)
            .fontColor('rgba(255,255,255,0.9)')
        }
        .alignItems(HorizontalAlign.Start)

        Blank().width(48).height(48)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({
      left: 24,
      right: 24,
      top: 50, // 避开状态栏
      bottom: 24
    })
    // 渐变背景
    .linearGradient({
      angle: 135,
      colors: [['#5C7CFF', 0.0], ['#4A65E0', 1.0]]
    })
    .shadow({ radius: 10, color: 'rgba(92, 124, 255, 0.3)', offsetY: 4 })
    .borderRadius({ bottomLeft: 24, bottomRight: 24 })
    .zIndex(10)
  }

  @Builder
  private FloatingToolbar() {
    Row() {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('+')
          .fontSize(24)
          .fontColor('#5C7CFF')
          .fontWeight(FontWeight.Medium)
          .offset({ y: -1 }) // 微调居中
      }
      .width(40)
      .height(40)
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 8, color: 'rgba(0,0,0,0.1)', offsetY: 2 })
      .onClick(() => this.startNewConversation())
    }
    .width('100%')
    .justifyContent(FlexAlign.End)
    .padding({ right: 20, top: 16 })
    .hitTestBehavior(HitTestMode.Transparent) // 让点击穿透空白区域
  }

  @Builder
  private EmptyPlaceholder() {
    Column({ space: 16 }) {
      Column() {
        Text('💬')
          .fontSize(40)
          .fontColor('#D1D6E6')
          .opacity(0.8)
      }
      .width(80)
      .height(80)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column({ space: 6 }) {
        Text('开启健康咨询')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
        Text('您可以描述症状、询问养生建议\n或解读体检报告')
          .fontSize(14)
          .fontColor('#999999')
          .textAlign(TextAlign.Center)
          .lineHeight(20)
      }
    }
    .width('100%')
    .margin({ top: 80 })
    .alignItems(HorizontalAlign.Center)
  }

  // 单条消息气泡
  @Builder
  private MessageBubble(msg: ChatMessage) {
    Row() {
      if (msg.from === 'ai') {
        // --- 修改点：AI 头像改为小机器人 ---
        Row() {
          Text('🤖')
            .fontSize(22) // 稍微放大 Emoji，使其充满圆形容器
        }
        .width(38)
        .height(38)
        .borderRadius(19) // 圆形
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .margin({ right: 8, top: 0 })
        .alignSelf(ItemAlign.Start)
        // 科技感渐变背景 (蓝紫色)
        .linearGradient({
          angle: 135,
          colors: [['#667EEA', 0.0], ['#764BA2', 1.0]]
        })
        .shadow({ radius: 6, color: 'rgba(118, 75, 162, 0.4)', offsetY: 2 })
      }

      Column() {
        // 解析 Markdown 加粗语法 (**text**)
        Text() {
          ForEach(msg.text.split(/(\*\*.*?\*\*)/g), (part: string) => {
            if (part.startsWith('**') && part.endsWith('**') && part.length >= 4) {
              Span(part.substring(2, part.length - 2))
                .fontWeight(FontWeight.Bold)
            } else {
              Span(part)
            }
          })
        }
        .fontSize(16)
        .lineHeight(24)
        .fontColor(msg.from === 'user' ? '#FFFFFF' : '#333333')
        .padding(14)
        .backgroundColor(msg.from === 'user' ? '#5C7CFF' : '#FFFFFF')
        .borderRadius(msg.from === 'user'
          ? {
            topLeft: 16,
            topRight: 4,
            bottomLeft: 16,
            bottomRight: 16
          }
          : {
            topLeft: 4,
            topRight: 16,
            bottomLeft: 16,
            bottomRight: 16
          })
        .shadow(msg.from === 'ai' ? { radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 2 } : undefined)
      }
      .constraintSize({ maxWidth: '70%' }) // 稍微减小气泡最大宽度，留出头像空间

      if (msg.from === 'user') {
        // 用户头像 - 动态绑定 AppStorage 中的头像
        Image(this.currentUserAvatar && this.currentUserAvatar.length > 0 ? this.currentUserAvatar : $r('app.media.profileIcon'))
          .width(38)
          .height(38)
          .borderRadius(19) // 圆形
          .backgroundColor('#E0E4F5') // 默认底色
          .margin({ left: 8, top: 0 })
          .objectFit(ImageFit.Cover)
          .alignSelf(ItemAlign.Start)
          .visibility(Visibility.Visible)
          .border({ width: 1, color: '#FFFFFF' }) // 增加白色描边，更精致
          .shadow({ radius: 4, color: 'rgba(0,0,0,0.1)', offsetY: 2 })
      }
    }
    .width('100%')
    .justifyContent(msg.from === 'user' ? FlexAlign.End : FlexAlign.Start)
    .alignItems(VerticalAlign.Top)
  }

  // 底部输入区域
  @Builder
  private InputArea() {
    Column() {
      Row({ space: 12 }) {
        TextInput({
          text: this.inputText,
          placeholder: '请输入您的健康问题...'
        })
          .type(InputType.Normal)
          .placeholderColor('#B0B5C7')
          .fontColor('#333333')
          .fontSize(16)
          .caretColor('#5C7CFF')
          .maxLines(4)
          .height(56) // 初始高度
          .padding({ left: 16, right: 16 })
          .backgroundColor('#FFFFFF')
          .borderRadius(28)
          .layoutWeight(1)
          .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetY: 1 })
          .enterKeyType(EnterKeyType.Send)
          .onSubmit(() => this.onSend())
          .onChange((value: string) => {
            this.inputText = value
          })

        // 发送按钮
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Text('↑')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .padding({ bottom: 2 })
        }
        .width(48)
        .height(48)
        .backgroundColor(this.inputText.trim().length > 0 ? '#5C7CFF' : '#D1D6E6')
        .shadow({
          radius: 6,
          color: this.inputText.trim().length > 0 ? 'rgba(92, 124, 255, 0.4)' : 'transparent',
          offsetY: 2
        })
        .onClick(() => this.onSend())
      }
      .alignItems(VerticalAlign.Bottom)
      .padding({
        left: 16,
        right: 16,
        top: 12,
        bottom: 12
      })
    }
    .backgroundColor('#F5F7FA')
  }

  private onSend() {
    const content = this.inputText.trim()
    if (content.length === 0 || this.isThinking) {
      return
    }
    const userMsg: ChatMessage = { id: this.nextId++, from: 'user', text: content }
    this.messages = [...this.messages, userMsg]
    this.persistMessages()
    this.inputText = ''
    this.scrollToLatest()

    this.fetchSmartReply(content)
  }

  private async fetchSmartReply(question: string) {
    this.isThinking = true

    try {
      let replyText = await HealthAIService.fetchOnlineAnswer(question)

      if (!replyText) {
        await new Promise<void>(resolve => setTimeout(resolve, 600))
        replyText = HealthAIService.buildAnswer(question)
      }

      const aiMsg: ChatMessage = {
        id: this.nextId++,
        from: 'ai',
        text: replyText || '抱歉，我暂时无法回答。'
      }
      this.messages = [...this.messages, aiMsg]
      this.persistMessages()
    } catch (err) {
      console.error('SmartReply Error:', JSON.stringify(err))
      const replyText = HealthAIService.buildAnswer(question)
      const aiMsg: ChatMessage = { id: this.nextId++, from: 'ai', text: replyText }
      this.messages = [...this.messages, aiMsg]
      this.persistMessages()
    } finally {
      this.isThinking = false
      this.scrollToLatest()
    }
  }

  // --- 修改点：思考状态指示器 (显示机器人头像) ---
  @Builder
  private TypingIndicator() {
    Row() {
      // 1. 显示机器人头像 (保持视觉统一)
      Row() {
        Text('🤖')
          .fontSize(22)
      }
      .width(38)
      .height(38)
      .borderRadius(19)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .margin({ right: 8 }) // 头像与气泡的间距
      .linearGradient({
        angle: 135,
        colors: [['#667EEA', 0.0], ['#764BA2', 1.0]]
      })
      .shadow({ radius: 6, color: 'rgba(118, 75, 162, 0.4)', offsetY: 2 })

      // 2. 思考中动画气泡
      Row({ space: 4 }) {
        Circle({ width: 6, height: 6 }).fill('#B0B5C7')
        Circle({ width: 6, height: 6 }).fill('#B0B5C7').opacity(0.7)
        Circle({ width: 6, height: 6 }).fill('#B0B5C7').opacity(0.4)
      }
      .height(36)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      .borderRadius({
        topLeft: 4,
        topRight: 18,
        bottomLeft: 18,
        bottomRight: 18
      })
      .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .margin({ top: 4, bottom: 4 })
  }

  private scrollToLatest() {
    setTimeout(() => {
      this.chatScroller.scrollTo({
        xOffset: 0,
        yOffset: 100000,
        animation: { duration: 300, curve: Curve.EaseOut }
      })
    }, 100)
  }

  private restoreMessages() {
    (async () => {
      try {
        const pref = await this.ensurePreferences()
        const stored = await pref.get(AskAIPage.HISTORY_KEY, '[]') as string
        const parsed = JSON.parse(stored) as ChatMessage[]
        if (Array.isArray(parsed)) {
          this.messages = parsed
          this.historySnapshot = stored
          this.nextId = parsed.reduce((max, item) => Math.max(max, item.id), 0) + 1
        } else {
          this.resetMemory()
        }
      } catch (err) {
        console.error('restoreMessages failed', JSON.stringify(err))
        this.resetMemory()
      }
    })()
  }

  private persistMessages() {
    const snapshot = JSON.stringify(this.messages)
    this.historySnapshot = snapshot
    ;
    (async () => {
      try {
        const pref = await this.ensurePreferences()
        await pref.put(AskAIPage.HISTORY_KEY, snapshot)
        await pref.flush()
      } catch (err) {
        console.error('persistMessages failed', JSON.stringify(err))
      }
    })()
  }

  private async ensurePreferences(): Promise<dataPreferences.Preferences> {
    if (this.preferences) {
      return this.preferences
    }
    const abilityContext = getContext(this) as common.UIAbilityContext
    this.preferences = await dataPreferences.getPreferences(abilityContext, AskAIPage.PREF_FILE)
    return this.preferences
  }

  private resetMemory() {
    this.messages = []
    this.nextId = 1
    this.historySnapshot = '[]'
  }

  private startNewConversation() {
    this.resetMemory()
    this.persistMessages()
    this.scrollToLatest()
  }
}