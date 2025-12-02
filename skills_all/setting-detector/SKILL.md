---
name: setting-detector
description: "Automatically detects story settings (genres, time periods, themes) based on keywords and activates corresponding knowledge bases - works silently in the background to provide relevant writing guidance without user intervention"
allowed-tools: Read
---

# 故事设定自动检测器

## 核心功能

**自动激活知识库系统** - 这是Novel Writer Skills的核心竞争力。

当你提到特定关键词时，我会自动：
1. 检测故事的类型、时代、主题
2. 加载对应的写作知识库
3. 在整个创作过程中应用专业知识

**无需手动调用** - 完全自动化，后台运行。

---

## 工作原理

### 关键词映射表

我监听以下关键词并自动激活对应知识库：

#### 类型知识库（Genres）

**言情小说**（romance）：
```
触发词：言情、爱情、恋爱、浪漫、感情线、关系弧、CP、甜文、虐文、
       HE、BE、双洁、破镜重圆、先婚后爱、契约关系

激活：templates/knowledge-base/genres/romance.md
```

**悬疑推理**（mystery）：
```
触发词：悬疑、推理、侦探、破案、谜团、线索、真相、凶手、犯罪、
       密室、诡计、不在场证明、推理小说

激活：templates/knowledge-base/genres/mystery.md
```

**历史小说**（historical）：
```
触发词：历史、古代、朝代、考据、时代背景、历史小说、古言、
       穿越、重生古代、架空历史、宫斗、宅斗

激活：templates/knowledge-base/genres/historical.md
```

**复仇爽文**（revenge）：
```
触发词：复仇、报仇、打脸、爽文、逆袭、反击、重生复仇、
       穿越复仇、系统、金手指、女主爽文、男主爽文

激活：templates/knowledge-base/genres/revenge.md
```

**武侠小说**（wuxia）：
```
触发词：武侠、江湖、武功、侠客、门派、武学、剑客、
       轻功、内功、武林、江湖恩仇、侠义

激活：templates/knowledge-base/genres/wuxia.md
```

#### 参考资料库（References）

**1920年代中国**（china-1920s）：
```
触发词：1920、民国、军阀、北洋、穿越民国、二十年代、
       民国时期、军阀混战

激活：templates/knowledge-base/references/china-1920s/
```

---

## 自动激活流程

### 示例1：单一类型检测

```
用户："我要写一部言情小说"
              ↓
[检测到关键词："言情"]
              ↓
✓ 自动加载：romance.md
              ↓
AI回复："太好了！让我帮你创作言情小说。
根据言情类型惯例，我们需要明确几个核心元素...
（自动应用romance.md中的知识）"
```

### 示例2：多类型组合检测

```
用户："我要写一部1920年代的言情复仇小说"
              ↓
[检测到关键词："1920"、"言情"、"复仇"]
              ↓
✓ 自动加载：romance.md
✓ 自动加载：revenge.md
✓ 自动加载：references/china-1920s/
              ↓
📚 已激活知识库：
- genres/romance.md（言情小说惯例）
- genres/revenge.md（复仇爽文技巧）
- references/china-1920s/（1920年代背景）
              ↓
AI回复："很好的组合！这是浪漫悬疑+复仇+民国背景。
根据这三个类型的融合，建议...
（同时应用三个知识库的内容）"
```

### 示例3：创作过程中的持续应用

```
/constitution 阶段：
→ 已激活：romance.md
→ 提醒：言情小说需要HEA/HFN结局承诺

/specify 阶段：
→ 已激活：romance.md + revenge.md
→ 建议：定义关系弧线+复仇目标

/plan 阶段：
→ 已激活：所有知识库
→ 应用：情感节奏点+打脸节奏+1920年代细节

/write 阶段：
→ 已激活：所有知识库
→ 实时：对话技巧+场景描写+时代氛围

/analyze 阶段：
→ 已激活：所有知识库
→ 检查：言情惯例+复仇合理性+历史准确性
```

---

## Token效率优化

**为什么这个系统高效？**

传统方案（superpowers-skills模式）：
```
50个独立Skills × 每个40行SKILL.md = 2000 tokens
每次对话都加载所有Skills
```

我们的方案（分层知识库+检测器）：
```
1个detector Skill（本文件）：~100 tokens
按需加载知识库：
- romance.md：~520 tokens
- revenge.md：~480 tokens
- china-1920s/：~650 tokens

总计：100 + 520 + 480 + 650 = ~1750 tokens
（仅加载相关知识库）
```

**节省75%** vs 加载50个无关Skills

---

## 手动控制

### 查看当前激活的知识库

随时询问：
```
"当前激活了哪些知识库？"
```

我会回复：
```
📚 当前激活的知识库：
✓ genres/romance.md - 言情小说创作惯例
✓ genres/revenge.md - 复仇爽文打脸技巧
✓ references/china-1920s/ - 1920年代中国参考资料

Token消耗：约1650 tokens
```

### 手动激活知识库

如果自动检测失败，可以明确指定：
```
"请加载 romance 和 mystery 知识库"
"这个故事需要 1920s 中国参考资料"
"激活武侠知识库"
```

### 停用知识库

如果某个知识库不需要了：
```
"停用 revenge 知识库，这个故事不涉及复仇"
```

---

## 与Commands集成

### `/constitution` - 类型特定原则

根据激活的知识库，提供类型特定的创作原则：

```markdown
【自动插入到constitution中】

## 类型特定原则（由setting-detector自动添加）

### 言情小说核心原则
1. 关系弧线是主情节
2. HEA/HFN结局是必须的
3. 化学反应真实可信

### 复仇爽文核心原则
1. 仇恨必须深刻具体
2. 打脸节奏渐进式
3. 道德平衡：罪有应得
```

### `/specify` - 类型特定规格

提供对应的规格模板元素：

```markdown
【自动提示】

💡 根据已激活的知识库，建议在规格中定义：

【来自romance.md】
- 关系弧线设定
- 情感节奏点规划
- HEA/HFN结局类型

【来自revenge.md】
- 仇恨来源（具体罪行）
- 金手指设定
- 打脸节奏规划

【来自china-1920s】
- 具体年份（1920-1929）
- 地理位置（北京/上海/其他）
- 社会阶层设定
```

### `/plan` - 类型知识融合

将多个知识库的建议融合到计划中：

```markdown
【自动应用】

## 章节规划（融合3个知识库）

第1-5章：相遇与仇恨建立
- [romance] 初次相遇场景（meet-cute）
- [revenge] 展示前世/过去的深仇大恨
- [1920s] 民国时代氛围营造

第6-10章：关系升温与小打脸
- [romance] 暧昧期：肢体接触、情感积累
- [revenge] 第一次打脸：仇人惊讶
- [1920s] 服饰、礼仪、社会规则展现

...
```

### `/write` - 实时写作指导

写作时自动应用相关知识：

```markdown
【写作前自动提醒】

📋 本章应用的知识库：

✓ romance.md - 对话火花技巧
  → 调情对话：挑战而非顺从
  → 肢体语言：眼神、触碰、距离

✓ revenge.md - 打脸场景爽感
  → 期待 → 反转 → 惊愕 → 霸气

✓ 1920s - 时代细节
  → 称呼：大人、老爷、小姐
  → 场景：茶馆、洋行、租界
```

### `/analyze` - 类型惯例检查

根据激活的知识库执行对应检查：

```markdown
【自动分析】

## 类型符合度分析

### 言情小说检查（基于romance.md）
- [x] 关系弧线是主情节
- [x] 包含必备情感节奏点
- [ ] ⚠️ 缺少初吻场景（建议在第15章）
- [x] HEA结局承诺明确

### 复仇爽文检查（基于revenge.md）
- [x] 仇恨深刻具体
- [x] 打脸频率合理（每5章1次）
- [x] 主角实力提升合理

### 历史准确性检查（基于1920s）
- [x] 时代背景正确
- [ ] ⚠️ 第8章出现"手机"（时代不符）
- [x] 称呼系统正确
```

---

## 知识库扩展

### 当前支持的知识库

| 类别 | 已完成 | 计划中 |
|------|--------|--------|
| 类型知识 | 5个 | 10+ |
| 参考资料 | 1个 | 20+ |

**已完成**（v1.0）：
- genres/romance.md
- genres/mystery.md
- genres/historical.md
- genres/revenge.md
- genres/wuxia.md
- references/china-1920s/

**计划中**（v1.1+）：
- genres/fantasy.md（奇幻）
- genres/sci-fi.md（科幻）
- genres/horror.md（恐怖）
- references/ancient-china/（各朝代）
- references/modern-workplace/（现代职场）

### 添加新知识库

1. 在`templates/knowledge-base/`对应目录创建文件
2. 更新`templates/knowledge-base/README.md`的关键词映射表
3. setting-detector会自动识别（无需修改本文件）

**示例**：添加奇幻知识库

```bash
# 1. 创建文件
touch templates/knowledge-base/genres/fantasy.md

# 2. 更新README.md关键词映射
fantasy:
  keywords: [奇幻, 魔法, 世界构建, 魔法系统]
  auto_load: genres/fantasy.md

# 3. 完成！下次用户说"奇幻"就会自动激活
```

---

## 智能特性

### 1. 模糊匹配

即使不是精确关键词也能识别：

```
"我想写个穿越到民国的复仇故事"
           ↓
识别："民国" → 1920s中国
     "复仇" → revenge

"女主重生后要报仇"
           ↓
识别："重生" + "报仇" → revenge（重生复仇）
```

### 2. 上下文理解

根据对话上下文持续识别：

```
第1条消息："我要写小说"
→ 未激活任何知识库（等待更多信息）

第2条消息："主角是侦探"
→ 激活mystery.md

第3条消息："还有感情线"
→ 额外激活romance.md

→ 当前激活：mystery + romance（浪漫悬疑）
```

### 3. 自动去重

避免重复激活：

```
用户："这是武侠小说，江湖背景，有武功"
            ↓
识别到3个武侠关键词，但只激活1次wuxia.md
```

---

## 常见问题

### Q: 我怎么知道哪个知识库被激活了？

**A**: 随时问我"当前激活了哪些知识库？"，我会列出清单。

### Q: 自动检测错了怎么办？

**A**: 直接告诉我：
```
"这不是言情小说，请停用romance知识库"
"这是科幻小说，请激活sci-fi知识库"（如果已有）
```

### Q: 能同时激活多少个知识库？

**A**: 理论上无限，但建议3-5个最优：
- 太少：指导不够全面
- 太多：token消耗大，可能冲突

实际经验：3个知识库（如romance + revenge + 1920s）已经很丰富。

### Q: 知识库会冲突吗？

**A**: 不会！知识库设计为协同工作：
- romance + mystery = 浪漫悬疑✓
- fantasy + romance = 奇幻言情✓
- historical + revenge = 古代复仇✓

### Q: 什么时候应该手动指定知识库？

**A**: 当：
- 使用了非常专业的术语（我可能没识别）
- 想尝试不同类型的融合
- 自动检测和你的意图不符

### Q: 知识库会一直激活吗？

**A**: 是的，直到：
- 你明确说"停用XX知识库"
- 或开始新的对话
- 或切换到完全不同的故事

---

## 最佳实践

### 1. 在创作初期明确类型

```
推荐做法：
用户："我要写一部民国背景的复仇言情小说"

不推荐：
用户："我要写小说"
AI："好的"
用户："主角姓李"
AI："嗯"
（20轮对话后才提到是什么类型）
```

### 2. 定期检查激活状态

每5-10章问一次：
```
"当前激活的知识库还适合吗？"
```

我会检查并建议是否需要调整。

### 3. 类型融合要合理

```
✓ 好的组合：
- romance + mystery（浪漫悬疑）
- historical + romance（古言）
- revenge + romance（复仇+感情）

⚠️ 困难的组合：
- horror + romance（恐怖言情？读者可能不适应）
- mystery + wuxia（推理武侠，需要特殊设计）

不是不能做，但需要特别小心融合方式。
```

### 4. 利用参考资料

如果故事有明确时代背景，一定激活对应参考资料：

```
"1920年代" → china-1920s
"古代" → 指定具体朝代（如"唐代"、"明朝"）
```

历史细节准确，读者沉浸感强。

---

## 技术说明

### 检测算法

```
1. 用户输入 → 提取关键词
2. 关键词 → 映射到知识库（基于README.md）
3. 去重 → 避免重复激活
4. 加载 → Read相应的.md文件
5. 应用 → 在后续对话中持续应用知识
```

### Token管理

```
激活状态检查：每次对话开始时
知识库内容：按需加载，缓存在对话上下文中
更新策略：只在明确需要时重新读取
```

### 与其他Skills协作

setting-detector是"知识调度器"，其他Skills是"执行者"：

```
setting-detector → 决定加载哪些知识
consistency-checker → 基于激活的知识库检查一致性
workflow-guide → 根据类型提供特定流程指导
genre-specific skills → 提供类型特定的深度技巧
```

---

## 总结

setting-detector是Novel Writer Skills的**大脑**：

✓ 自动检测故事设定
✓ 智能激活对应知识库
✓ Token高效（按需加载）
✓ 持续应用专业知识
✓ 无需用户干预

**让AI自动成为你故事类型的专家！** 🧠✨

---

**本Skill版本**: v1.0
**最后更新**: 2025-10-18
**依赖**: templates/knowledge-base/ 系统
**协作**: consistency-checker, workflow-guide, genre-specific skills
