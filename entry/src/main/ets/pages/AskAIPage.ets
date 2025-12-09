/**
 * @file AskAIPage.ets
 * @description AI 咨询页面
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
      Column() {
        this.HeaderSection()

        Column() {
          this.ChatToolbar()

          Scroll(this.chatScroller) {
            Column({ space: 12 }) {
              if (this.messages.length === 0) {
                this.EmptyPlaceholder()
              } else {
                ForEach(this.messages, (msg: ChatMessage) => {
                  this.MessageBubble(msg)
                }, (msg: ChatMessage) => msg.id.toString())
              }

              if (this.isThinking) {
                this.TypingIndicator()
              }
            }
            .width('100%')
          }
          .layoutWeight(1)
          .padding({
            left: 16,
            right: 16,
            top: 8,
            bottom: 12
          })
        }
        .layoutWeight(1)
        .backgroundColor('#FFFFFF')
        .borderRadius({ topLeft: 32, topRight: 32 })
        .margin({ top: -18 })
        .clip(true)

        this.InputArea()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#E8F1FF')

      myNavigator()
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private HeaderSection() {
    Row({ space: 0 }) {
      Column({ space: 4 }) {
        Text('AI 智能问诊')
          .fontSize(24)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
        Text('描述症状或提问，AI 将即时反馈建议')
          .fontSize(14)
          .fontColor('rgba(255,255,255,0.85)')
      }
      .layoutWeight(1)
      .padding({
        left: 24,
        right: 24,
        top: 56,
        bottom: 32
      })
      .backgroundColor('#5C7CFF')
      .borderRadius({ bottomLeft: 32, bottomRight: 32 })

      
    }
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .padding({
      top: 12,
      bottom: 12
    })
    .backgroundColor('transparent')
  }

  @Builder
  private ChatToolbar() {
    Row() {
      Button('+')
        .width(44)
        .height(44)
        .type(ButtonType.Circle)
        .fontSize(24)
        .fontColor('#FFFFFF')
        .backgroundColor('#3F6BFF')
        .shadow({ radius: 8, color: '#1A3F6BFF', offsetY: 2 })
        .onClick(() => this.startNewConversation())
    }
    .width('100%')
    .justifyContent(FlexAlign.End)
    .padding({
      left: 16,
      right: 16,
      top: 16,
      bottom: 4
    })
  }

  @Builder
  private EmptyPlaceholder() {
    Column({ space: 8 }) {
      Image($r('app.media.enter'))
        .width(80)
        .height(80)
        .opacity(0.65)
      Text('暂时没有对话')
        .fontSize(16)
        .fontColor('#7A7F8C')
      Text('试着输入你的症状或问题，点击 Enter 发送给 AI')
        .fontSize(13)
        .fontColor('#A0A5B5')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .margin({ top: 40 })
    .alignItems(HorizontalAlign.Center)
  }

  // 单条消息气泡
  @Builder
  private MessageBubble(msg: ChatMessage) {
    Row() {
      Column() {
        Text(msg.text)
          .fontSize(15)
          .lineHeight(21)
          .fontColor(msg.from === 'user' ? '#FFFFFF' : '#191C24')
          .padding({
            left: 14,
            right: 14,
            top: 10,
            bottom: 10
          })
          .backgroundColor(msg.from === 'user' ? '#5C7CFF' : '#F1F3FA')
          .borderRadius(msg.from === 'user'
            ? {
              topLeft: 18,
              topRight: 6,
              bottomLeft: 18,
              bottomRight: 18
            }
            : {
              topLeft: 6,
              topRight: 18,
              bottomLeft: 18,
              bottomRight: 18
            })
          .width('85%')
          .shadow({ radius: 6, color: '#1A000000', offsetY: 2 })
      }
    }
    .width('100%')
    .justifyContent(msg.from === 'user' ? FlexAlign.End : FlexAlign.Start)
    .margin({ top: 4, bottom: 4 })
  }

  // 底部输入区域
  @Builder
  private InputArea() {
    Column() {
      Row() {
        TextInput({
          text: this.inputText,
          placeholder: '请输入要咨询的问题…'
        })
          .type(InputType.Normal)
          .placeholderColor('#B0B5C7')
          .fontColor('#141927')
          .fontSize(15)
          .maxLines(3)
          .height(96)
          .padding({
            left: 16,
            right: 16,
            top: 14,
            bottom: 14
          })
          .backgroundColor('#FFFFFF')
          .borderRadius(24)
          .layoutWeight(1)
          .enterKeyType(EnterKeyType.Send)
          .onSubmit(() => this.onSend())
          .onChange((value: string) => {
            this.inputText = value
          })

        Button($r('app.string.Enter'))
          .width(52)
          .height(52)
          .margin({ left: 12 })
          .type(ButtonType.Circle)
          .backgroundColor(this.inputText.trim().length > 0 ? '#5C7CFF' : '#CBD2E6')
          .fontColor('#FFFFFF')
          .onClick(() => this.onSend())
      }
      .alignItems(VerticalAlign.Center)
      .padding({
        left: 16,
        right: 16,
        top: 12,
        bottom: 12
      })
      .backgroundColor('transparent')
    }
    .padding({ bottom: 82 })
  }

  // 点击 Enter 后，把输入内容加入聊天列表
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


    this.simulateAIReply(content)
  }

  // 使用本地 HealthAIService 模拟 AI 回复（保留“正在输入”效果）
  private simulateAIReply(question: string) {
    this.isThinking = true
    setTimeout(() => {
      const replyText = HealthAIService.buildAnswer(question)
      const aiMsg: ChatMessage = {
        id: this.nextId++,
        from: 'ai',
        text: replyText
      }
      this.messages = [...this.messages, aiMsg]
      this.persistMessages()
      this.isThinking = false
      this.scrollToLatest()
    }, 800) // 模拟思考时间
  }

  

  @Builder
  private TypingIndicator() {
    Row() {
      Text('AI 正在输入…')
        .fontSize(13)
        .fontColor('#7A7F8C')
        .padding({
          left: 12,
          right: 12,
          top: 6,
          bottom: 6
        })
        .backgroundColor('rgba(92,124,255,0.08)')
        .borderRadius(16)
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
  }

  private scrollToLatest() {
    setTimeout(() => {
      this.chatScroller.scrollTo({
        xOffset: 0,
        yOffset: 100000,
        animation: { duration: 180, curve: Curve.EaseOut }
      })
    }, 0)
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
    ;(async () => {
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