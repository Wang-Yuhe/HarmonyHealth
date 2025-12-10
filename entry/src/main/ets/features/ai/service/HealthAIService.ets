import http from '@ohos.net.http';
// 引入 Explore 模块已有的配置文件
import configData from '../../explore/data/exploreConfig.json';

// 定义 HTTP 请求相关的接口
interface ChatMessage {
  role: string;
  content: string;
}

interface ChatRequestData {
  model: string;
  messages: ChatMessage[];
  temperature: number;
}

// 定义 API 响应接口
interface ChoiceMessage {
  content: string;
}

interface Choice {
  message: ChoiceMessage;
}

interface ChatResponse {
  choices: Choice[];
}

/**
 * @file HealthAIService.ets
 * @description 健康 AI 服务：支持联网请求 DeepSeek，支持离线关键词匹配兜底
 */
export class HealthAIService {
  /**
   * 尝试联网获取 AI 回答
   * @param question 用户的问题
   * @returns AI 回答文本，如果网络请求失败或配置无效则返回 null
   */
  static async fetchOnlineAnswer(question: string): Promise<string | null> {
    try {
      // 1. 检查配置是否存在
      if (!configData.apiUrl || !configData.apiKey || configData.apiKey === 'YOUR_API_KEY_HERE') {
        console.warn('HealthAIService: API Key not configured, falling back to offline.');
        return null;
      }

      // 2. 创建 HTTP 请求
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(configData.apiUrl, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${configData.apiKey}`
        },
        extraData: JSON.stringify({
          model: configData.model,
          messages: [
            {
              role: "system",
              content: "你是一个专业的健康咨询助手。请根据用户的描述提供健康建议、风险评估和生活指导。回答请保持条理清晰，语气亲切，不要使用Markdown格式。如果情况严重，请务必提醒用户线下就医。"
            } as ChatMessage,
            { role: "user", content: question } as ChatMessage
          ],
          temperature: 0.7
        } as ChatRequestData),
        expectDataType: http.HttpDataType.STRING,
        readTimeout: 20000, // 设置 20 秒超时
        connectTimeout: 20000
      });
      // 3. 解析响应
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as ChatResponse;
        if (result.choices && result.choices.length > 0 && result.choices[0].message) {
          return result.choices[0].message.content;
        }
      } else {
        console.error(`HealthAIService: HTTP Error ${response.responseCode}`);
      }
    } catch (error) {
      console.error('HealthAIService Online Fetch Error:', JSON.stringify(error));
    }
    return null;
  }

  /**
   * (离线兜底) 根据用户的健康问题描述，提取关键词并生成一段尽量全面的健康建议
   */
  static buildAnswer(question: string): string {
    // 预处理：去掉空格、统一成小写，便于匹配口语表达
    const text = question.replace(/\s+/g, '').toLowerCase()
    const points: string[] = []
    const advice: string[] = []
    const warn: string[] = []
    const tags: string[] = [] // 记录识别到的关键信息标签

    // 1. 常见症状类（多种口语表达）
    // 头痛 / 头晕
    if (/(头痛|头疼|脑袋痛|脑壳痛|偏头痛|头晕|晕乎乎|晕眩|发懵|晕 dizzy|headache|dizzy)/.test(text)) {
      tags.push('头痛 / 头晕 / 偏头痛')
      points.push('· 检测到和【头痛/头晕】相关的描述。常见原因包括用眼过度、睡眠不足、紧张焦虑、颈椎问题等，也可能与血压、脑血管疾病有关。')
      advice.push('保持规律作息，避免熬夜，建议每天 7–8 小时优质睡眠。')
      advice.push('长时间看手机或电脑时，每 40–50 分钟起身活动，做颈部和肩部拉伸。')
      advice.push('可以适当做眼保健操或远眺放松眼睛，减轻视疲劳。')
      warn.push('若头痛突然明显加重，或伴有呕吐、意识模糊、肢体无力、说话困难等症状，请立即就医。')
    }

    // 咳嗽 / 嗓子不舒服 / 感冒
    if (/(咳嗽|咳个不停|老咳嗽|咳两声|咳痰|有痰|痰多|嗓子痛|嗓子疼|嗓子不舒服|嗓子像刀割一样|喉咙痛|喉咙不舒服|咽痛|感冒|像感冒|感冒了|流鼻涕|流涕|鼻塞|打喷嚏|喷嚏不停|喉咙干痒)/.test(text)) {
      tags.push('上呼吸道症状 / 感冒样症状')
      points.push('· 检测到和【呼吸道症状】相关的描述，例如咳嗽、咽痛、鼻塞或感冒样表现。')
      advice.push('多喝温水，避免冷饮及辛辣、油腻食物，保持室内通风和适宜湿度。')
      advice.push('注意休息，尽量避免熬夜和剧烈运动，可以适当喝一些温热的清淡汤水缓解不适。')
      advice.push('若咳嗽影响休息，可在医生指导下使用止咳或化痰药物，不建议自行大量服用复方感冒药物。')
      warn.push('若出现持续高热（≥38.5℃）、呼吸困难、胸痛、咯血或症状超过一周仍无明显好转，需尽快就医。')
    }

    // 发烧
    if (/(发烧|发热|低烧|高烧|烧到|体温|烧了一整天)/.test(text)) {
      tags.push('发热 / 体温异常')
      points.push('· 你提到了【发热/体温异常】，多提示体内存在感染或炎症反应。')
      advice.push('注意休息，多饮水，可用温水擦浴等方式帮助物理降温，避免使用酒精擦拭皮肤。')
      advice.push('体温不算太高且精神状态尚可时，可以先多观察、多补水。')
      warn.push('若持续高烧不退，或伴有皮疹、剧烈头痛、意识改变、抽搐等情况，请立即前往正规医院就诊。')
    }

    // 消化道 / 肚子疼 / 拉肚子
    if (/(胃痛|胃疼|肚子痛|肚子疼|肚子隐隐作痛|肚子不舒服|肚子绞痛|胃不舒服|胃胀|胃胀气|肚子胀|反酸|烧心|恶心|想吐|呕吐|腹泻|拉肚子|拉稀|拉稀拉水|水样便|腹痛|便秘|大便干|大便干燥|拉不出|排不出来)/.test(text)) {
      tags.push('消化道不适 / 腹痛 / 腹泻 / 便秘')
      points.push('· 描述中提到了【消化道不适】，与饮食结构、肠胃功能和情绪状态都可能有关。')
      advice.push('饮食上建议清淡易消化，少油少辣，避免生冷、烧烤、油炸等刺激性食物。')
      advice.push('可以少量多餐，进食速度放慢，细嚼慢咽，睡前 2–3 小时内避免大量进食。')
      advice.push('腹泻时要注意补水和电解质，便秘则要增加膳食纤维和适量运动。')
      warn.push('如出现黑便、血便、呕血、持续剧烈腹痛、反复呕吐或明显消瘦等情况，应尽快到消化科就诊。')
    }

    // 睡眠问题
    if (/(失眠|睡不着|睡不着觉|怎么都睡不着|难入睡|入睡困难|早醒|多梦|噩梦|老做梦|睡眠质量差|睡得不好|容易醒|半夜醒来|整晚睡不好)/.test(text)) {
      tags.push('睡眠问题 / 失眠 / 多梦')
      points.push('· 描述中有【睡眠问题】，长期睡眠不足会影响免疫力、情绪和心血管健康。')
      advice.push('睡前 1 小时尽量不用手机和电脑，避免强光与刺激性内容，营造昏暗安静的睡眠环境。')
      advice.push('保持相对固定的作息时间，可以配合温水泡脚、轻度拉伸或深呼吸训练帮助放松。')
      advice.push('白天增加适度运动有助于改善睡眠，但要避免睡前剧烈运动与大量进食或咖啡因摄入。')
      warn.push('如果长期失眠已经影响工作与生活，或合并明显焦虑抑郁情绪，建议及时咨询精神科或睡眠专科医生。')
    }

    // 2. 慢病相关：血压 / 血糖 / 心脏
    // 血压
    if (/(高血压|低血压|血压高|血压低|量血压|测血压|血压有点高|血压不太稳)/.test(text)) {
      tags.push('血压异常 / 高血压 / 低血压')
      points.push('· 检测到【血压问题】相关描述，高血压若长期控制不佳，会增加脑卒中、心梗等心脑血管事件风险。')
      advice.push('建议在固定时间（如早晨起床后、睡前）测量血压并做记录，便于观察长期趋势。')
      advice.push('饮食尽量清淡，控制盐摄入（每天不超过约 5g），多吃蔬菜水果，减少油炸、高盐和加工食品。')
      advice.push('坚持适度有氧运动，如快走、骑行等，在医生评估安全的前提下进行。')
      warn.push('若出现剧烈头痛、视物模糊、胸闷、意识改变或单侧肢体无力等情况，应高度警惕，立即就医。')
    }

    // 血糖 / 糖代谢
    if (/(血糖|糖尿病|血糖高|血糖偏高|血糖偏低|餐后困|饭后困|吃完就困|口渴多饮|老是渴|多尿|夜尿多)/.test(text)) {
      tags.push('血糖异常 / 糖代谢问题')
      points.push('· 检测到和【血糖/糖代谢】相关的描述，需关注是否存在糖代谢异常或糖尿病风险。')
      advice.push('合理控制主食量，减少含糖饮料与甜食，多选择全谷物、蔬菜等高纤维食物。')
      advice.push('保持规律三餐，避免暴饮暴食以及长期不吃早餐，尽量做到定时定量。')
      advice.push('结合医生建议，定期监测空腹血糖、餐后血糖以及糖化血红蛋白。')
      warn.push('如出现体重短期明显下降、极度乏力、伤口久不愈合、反复皮肤感染等情况，建议尽快进行血糖等相关检查。')
    }

    // 心脏 / 胸闷胸痛 / 心慌
    if (/(胸闷|胸口闷|胸口不舒服|闷得慌|胸痛|心口痛|心口不舒服|心慌|心慌慌|心悸|心跳快|心跳很快|心跳特别快|心率不齐|心脏不舒服)/.test(text)) {
      tags.push('胸闷 / 胸痛 / 心慌 / 心脏不适')
      points.push('· 你提到了【胸闷/胸痛/心慌】等心脏相关不适，需要特别重视。')
      advice.push('建议记录不适出现的时间、持续时长、诱因（如运动、情绪波动、进食后）以及是否向肩背、下颌、左臂放射。')
      advice.push('如已有心血管基础疾病，应在医生指导下按时服药，不随意增减剂量或自行停药。')
      advice.push('保持规律生活、控制情绪波动、戒烟限酒，对心血管健康也非常重要。')
      warn.push('若出现压榨样或撕裂样胸痛、伴大汗淋漓、呼吸困难、恶心、左臂或下颌放射痛，应高度怀疑急症，立即拨打急救电话。')
    }

    // 3. 生活方式：饮食 / 运动 / 情绪压力
    // 饮食 & 胃口
    if (/(饮食|吃得多|吃多了|暴饮暴食|吃得少|吃不下|吃不下饭|没胃口|没什么胃口|食欲差|胃口不好)/.test(text)) {
      tags.push('饮食习惯 / 食欲变化')
      points.push('· 描述中提到了【饮食或食欲变化】，这可能与胃肠道功能、代谢状况或情绪压力相关。')
      advice.push('建议尽量规律三餐，避免长期不吃早餐或频繁宵夜。')
      advice.push('减少高油、高盐、高糖食物，多选择蔬菜、水果、优质蛋白和全谷物。')
      warn.push('若近期体重突然明显增加或下降、伴随乏力、心悸、出汗异常等，建议进行进一步体检评估。')
    }

    // 运动 / 久坐
    if (/(运动|锻炼|跑步|慢跑|快走|走路|健身|撸铁|举铁|游泳|打球|久坐|坐太久|缺乏运动)/.test(text)) {
      tags.push('运动习惯 / 久坐')
      points.push('· 你的描述中涉及【运动/久坐】情况，适度规律运动对心肺功能、情绪管理和代谢健康都非常重要。')
      advice.push('对于多数成年人，建议每周至少 150 分钟中等强度有氧运动，如快走、慢跑、骑行、游泳等。')
      advice.push('长期久坐人群，每工作 1 小时至少起身活动 5 分钟，做简单的颈肩和下肢伸展。')
    }

    // 情绪 / 压力 / 心情
    if (/(焦虑|焦虑症|压力大|压力山大|抑郁|抑郁症|心情差|心情不好|情绪|情绪波动|烦躁|烦躁不安|紧张|紧绷|心里慌|心里堵得慌|提不起劲|没劲|懒洋洋)/.test(text)) {
      tags.push('情绪压力 / 焦虑 / 情绪低落')
      points.push('· 你提到了【情绪/压力】方面的问题，长期心理压力会明显影响睡眠、食欲和身体多处症状。')
      advice.push('可以尝试深呼吸训练、冥想、瑜伽或听轻音乐，每天给自己 10–20 分钟的放松时间。')
      advice.push('建立稳定的作息和生活节奏，适当运动能明显改善情绪状态。')
      advice.push('适当和信任的家人或朋友交流，必要时可寻求专业心理咨询或精神科医生帮助。')
      warn.push('如持续出现明显情绪低落、兴趣减退、对生活失去动力，甚至出现轻生念头，请务必尽快寻求专业帮助，不要一个人硬扛。')
    }

    // 4. 其他常见场景扩展
    // 经期 / 妇科相关
    if (/(月经|大姨妈|来姨妈|例假|经期|痛经|经痛|小肚子疼|小肚子痛|下腹坠痛|白带|妇科)/.test(text)) {
      tags.push('月经 / 经期不适 / 妇科相关')
      points.push('· 检测到和【月经/妇科】相关的描述，很多女性在经期会出现小腹隐痛、乏力、情绪波动等情况。')
      advice.push('经期注意保暖，避免受凉和大量寒凉食物，可适当饮用温热饮品。')
      advice.push('建议记录月经周期、经量、颜色和伴随症状，便于长期观察和就诊时提供信息。')
      warn.push('如经量明显增多或减少、周期紊乱、出血时间明显延长、经间期出血或疼痛剧烈影响日常生活，应尽快到妇科就诊。')
    }

    // 皮肤 / 过敏 / 皮疹
    if (/(皮疹|起疹子|身上起小红点|起小红疙瘩|湿疹|皮肤痒|身上痒|全身痒|荨麻疹|风团|过敏|过敏了|对什么过敏)/.test(text)) {
      tags.push('皮肤瘙痒 / 皮疹 / 过敏')
      points.push('· 你提到了【皮肤瘙痒/皮疹/过敏】相关问题，可能与饮食、环境接触物、药物或体质有关。')
      advice.push('尽量回忆近期是否更换了洗护用品、衣物材质、宠物接触或进食了特殊食物。')
      advice.push('注意皮肤保湿，避免过度搔抓，以免抓破皮肤引起感染。')
      warn.push('若出现面部或咽喉肿胀、呼吸困难、胸闷、全身大片风团等严重过敏反应，应立即就医或拨打急救电话。')
    }

    // 眼睛 / 视力
    if (/(眼睛干|眼干|眼涩|眼睛酸|眼睛疼|眼眶痛|视力模糊|看不清|看东西糊|重影|飞蚊|飞蚊症|闪光感)/.test(text)) {
      tags.push('眼部不适 / 视力变化')
      points.push('· 描述中有【眼睛不适/视力变化】相关内容，长期用眼过度或眼底疾病都有可能引起。')
      advice.push('建议减少长时间近距离用眼，每 30–40 分钟让眼睛休息 5–10 分钟，多眺望远处。')
      advice.push('注意工作环境光线柔和，避免强光直射或在完全黑暗环境中长时间看屏幕。')
      warn.push('若视力突然明显下降、视物变形或视野缺损，或出现闪光感、黑影飘动明显增多，应立即到眼科就诊。')
    }

    // 腰背 / 颈肩 / 关节
    if (/(腰痛|腰疼|后背痛|背痛|背疼|背酸|颈椎|脖子痛|脖子疼|肩膀疼|肩周|肩周炎|关节痛|膝盖痛|膝盖疼|关节酸痛|肌肉酸痛)/.test(text)) {
      tags.push('腰背痛 / 颈肩痛 / 关节酸痛')
      points.push('· 你提到了【腰背/颈肩/关节】不适，常与久坐、姿势不良、劳损或退行性改变有关。')
      advice.push('注意工作和学习时的坐姿与站姿，避免长时间保持同一姿势。')
      advice.push('可以在不疼痛的范围内做一些轻柔伸展或肌肉力量训练，逐步增强支撑力量。')
      warn.push('如疼痛持续加重、夜间痛明显影响睡眠，或合并发热、关节红肿、下肢麻木无力等情况，应及时到骨科或风湿免疫科就诊。')
    }

    // 体重 / 代谢
    if (/(胖了|变胖|长胖|发胖|减肥|想减肥|瘦了|体重下降|体重减轻|体重增加|肥胖)/.test(text)) {
      tags.push('体重变化 / 体重管理 / 代谢问题')
      points.push('· 描述中涉及【体重变化/体重管理】问题，和饮食、运动、代谢和内分泌状态都有关系。')
      advice.push('体重管理建议以长期均衡饮食和持续运动为主，不建议极端节食或快速减肥方式。')
      advice.push('可以尝试记录一周的饮食与运动情况，寻找可调整的地方，如减少含糖饮料、甜品与高油食物。')
      warn.push('如在未刻意减肥的情况下体重短期明显下降，尤其伴有乏力、出汗、心悸等，应尽快就医排查内分泌或恶性疾病等可能。')
    }

    // 体检/化验异常（不具体解释指标，只给就诊建议）
    if (/(体检|检查报告|化验单|血脂|胆固醇|尿酸|肝功能|转氨酶|肾功能|肌酐|心电图|b超|彩超|超声)/.test(text)) {
      tags.push('体检异常 / 检查报告解读')
      points.push('· 你提到了【体检/检查报告】相关问题，单个指标的轻度高低往往需要结合年龄、症状和其他检查综合评估。')
      advice.push('建议保留完整的体检或检查报告，在就诊时向医生出示，以便进行系统解读。')
      advice.push('平时可以从饮食结构、运动习惯、睡眠和情绪管理多方面入手，综合改善健康状况。')
      warn.push('若医生已经提示某些指标明显异常，请不要忽视，按时复查或进一步完善相关检查。')
    }

    // 5. 如果一个关键词都没命中，给一个通用分析
    if (points.length === 0) {
      return '我已经收到了你的健康描述。\n\n' +
        '目前从文字中还无法准确判断属于哪一类具体问题，建议你：\n' +
        '1. 尽量补充症状的部位、性质（隐痛/刺痛/胀痛/酸痛等）、持续时间以及明显诱因（运动、情绪、进食后等）。\n' +
        '2. 同时说明是否伴随发热、体重变化、睡眠情况、既往慢性病史以及正在使用的药物。\n' +
        '\n【重要提示】以上内容仅为健康科普信息，不能替代线下就诊。如症状明显、不适持续存在或迅速加重，请尽快就医，由专业医生进行面对面评估。'
    }

    // 6. 根据命中的条目和警示信息，给一个“风险等级”总结
    const uniqTags = Array.from(new Set(tags))
    let riskLevel = '轻度风险'
    let riskDesc = '当前根据文字内容，暂未显示大量紧急危险信号，但仍建议你持续关注自身状态，留意症状变化。'

    if (warn.length >= 3 || /胸痛|呕血|黑便|抽搐|意识改变/.test(points.join(''))) {
      riskLevel = '偏高风险（需尽快线下就诊评估）'
      riskDesc = '描述中提示可能存在较高风险的情况，尤其是胸痛、意识改变、出血等表现，强烈建议尽快前往正规医院进行面对面评估。'
    } else if (warn.length >= 1) {
      riskLevel = '中度风险'
      riskDesc = '文字中包含一些需要警惕的信号，若症状持续存在或逐渐加重，应尽早安排线下面诊，排除严重问题。'
    }

    // 7. 综合生成一段较完整的回答
    let result = `【整体风险评估】\n风险等级：${riskLevel}\n${riskDesc}\n\n`

    if (uniqTags.length > 0) {
      result += '【识别到的关键信息】\n'
      uniqTags.forEach(tag => {
        result += `- ${tag}\n`
      })
      result += '\n'
    }

    result += '【症状分析】\n'
    result += points.join('\n') + '\n'

    if (advice.length > 0) {
      result += '\n【日常调养建议】\n'
      advice.forEach((a, idx) => {
        result += `${idx + 1}. ${a}\n`
      })
    }

    if (warn.length > 0) {
      result += '\n【需要警惕的情况】\n'
      warn.forEach((w, idx) => {
        result += `${idx + 1}. ${w}\n`
      })
    }

    result += '\n【温馨提示】以上内容仅供参考，用于帮助你更好地理解和梳理自身情况，不能替代专业医生的面诊与检查。如有严重不适或不确定的地方，建议尽快到正规医院就诊。'

    return result
  }
}