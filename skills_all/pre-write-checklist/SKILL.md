---
name: pre-write-checklist
description: "Activates automatically before chapter writing to enforce the 9-item mandatory file reading checklist - prevents AI focus degradation in long-form fiction by ensuring all context is loaded before each writing session"
allowed-tools: Read, Grep
---

# 写作前强制检查清单

## 核心功能

**解决AI长篇失焦问题** - 这是Novel Writer Skills v1.0的核心创新。

### 问题根源

用户反馈：使用novel-writer创作，前30章质量很好，但30章后AI开始：
- 忘记前文设定
- 角色性格不一致
- 情节重复或矛盾
- 忽略创作宪法的原则

**根本原因**：长对话导致AI遗忘早期context，即使specification.md写得再详细也会被忘记。

### 解决方案

**每次写作前强制重读所有关键文件** → AI重新加载完整context → 保持一致性

---

## 9项强制检查清单

每次执行`/write`命令时，必须先完成此检查清单：

```markdown
📋 写作前检查清单（必须完成）：

✓ 1. memory/constitution.md - 创作宪法
✓ 2. memory/style-reference.md - 风格参考（如有）
✓ 3. stories/*/specification.md - 故事规格
✓ 4. stories/*/creative-plan.md - 创作计划
✓ 5. stories/*/tasks.md - 当前任务
✓ 6. spec/tracking/character-state.json - 角色状态
✓ 7. spec/tracking/relationships.json - 关系网络
✓ 8. spec/tracking/plot-tracker.json - 情节追踪（如有）
✓ 9. spec/tracking/validation-rules.json - 验证规则（如有）

📊 上下文加载状态：✅ 完成
```

---

## 工作原理

### 自动触发时机

1. **用户执行 `/write` 命令**
2. **本Skill自动激活**
3. **强制执行检查清单**
4. **输出确认报告**
5. **然后才开始写作**

### 执行流程

```
用户: /write 第10章

         ↓

[pre-write-checklist 自动激活]

         ↓

步骤1：读取 memory/constitution.md
步骤2：读取 memory/style-reference.md（如有）
步骤3：读取 stories/*/specification.md
步骤4：读取 stories/*/creative-plan.md
步骤5：读取 stories/*/tasks.md
步骤6：读取 spec/tracking/character-state.json
步骤7：读取 spec/tracking/relationships.json
步骤8：读取 spec/tracking/plot-tracker.json（如有）
步骤9：读取 spec/tracking/validation-rules.json（如有）

         ↓

输出确认：
📋 写作前检查清单（已完成）：
✓ 1-9 所有文件已读取
📊 上下文加载状态：✅ 完成

关键信息摘要：
- 创作原则：[从constitution提取]
- 当前任务：[从tasks.md提取]
- 主要角色：[从character-state提取]
- 情节进度：[从plot-tracker提取]

         ↓

开始写作第10章...
```

---

## 输出格式

### 标准输出（所有文件存在）

```markdown
📋 写作前检查清单（已完成）：

✓ 1. memory/constitution.md - 创作宪法
   → 核心原则：[列出2-3条关键原则]

✓ 2. memory/style-reference.md - 风格参考
   → 风格要点：[提取关键风格要求]

✓ 3. stories/xxx/specification.md - 故事规格
   → 故事类型：[言情/悬疑/历史等]
   → P0元素：[必须包含的元素]

✓ 4. stories/xxx/creative-plan.md - 创作计划
   → 当前阶段：[第X卷/第X章]
   → 本章目标：[情节/情感目标]

✓ 5. stories/xxx/tasks.md - 当前任务
   → 待写章节：[第X章]
   → 任务状态：[pending/in_progress]

✓ 6. spec/tracking/character-state.json - 角色状态
   → 主要角色：[列出角色名和当前状态]

✓ 7. spec/tracking/relationships.json - 关系网络
   → 核心关系：[主角与谁的关系变化]

✓ 8. spec/tracking/plot-tracker.json - 情节追踪
   → 活跃线索：[当前进行中的情节线]

✓ 9. spec/tracking/validation-rules.json - 验证规则
   → 自动修复：[启用/禁用]

📊 上下文加载状态：✅ 完成（加载9个文件，约XXXX tokens）

🎯 准备写作第X章...
```

### 部分文件缺失时

```markdown
📋 写作前检查清单（部分完成）：

✓ 1. memory/constitution.md - 创作宪法
✓ 2. ⚠️ memory/style-reference.md - 不存在（可选文件，跳过）
✓ 3. stories/xxx/specification.md - 故事规格
✓ 4. stories/xxx/creative-plan.md - 创作计划
✓ 5. stories/xxx/tasks.md - 当前任务
✓ 6. spec/tracking/character-state.json - 角色状态
✓ 7. spec/tracking/relationships.json - 关系网络
✓ 8. ⚠️ spec/tracking/plot-tracker.json - 不存在（可选文件，跳过）
✓ 9. ⚠️ spec/tracking/validation-rules.json - 不存在（可选文件，跳过）

📊 上下文加载状态：✅ 完成（加载6个必须文件 + 0个可选文件）

💡 建议：运行 `/track-init` 初始化完整追踪系统
```

### 关键文件缺失时（阻止写作）

```markdown
📋 写作前检查清单（失败）：

✓ 1. memory/constitution.md - 创作宪法
✓ 2. memory/style-reference.md - 风格参考
❌ 3. stories/xxx/specification.md - **文件不存在**
❌ 4. stories/xxx/creative-plan.md - **文件不存在**
❌ 5. stories/xxx/tasks.md - **文件不存在**

⛔ 错误：缺少必需文件，无法继续写作

必须先完成：
1. 运行 `/constitution` 创建创作宪法
2. 运行 `/specify` 定义故事规格
3. 运行 `/plan` 制定创作计划
4. 运行 `/tasks` 分解任务清单

然后才能执行 `/write`

这是seven-step methodology的推荐流程。
```

---

## 与Commands集成

### `/write` 命令

**必须先执行检查清单，才能写作**：

```yaml
执行顺序：
1. pre-write-checklist（本Skill）→ 读取所有文件
2. 输出确认报告
3. 检查setting-detector → 是否需要激活知识库
4. 开始实际写作
```

### `/analyze` 命令

分析时也建议执行检查清单：

```yaml
分析前先确保context完整：
1. pre-write-checklist → 重新加载所有文件
2. 基于最新状态执行分析
```

### `/track` 命令

追踪更新后触发检查清单：

```yaml
更新流程：
1. 用户修改tracking文件
2. 运行 `/track` 更新
3. pre-write-checklist → 重新读取验证
```

---

## 文件重要性分类

### 必须文件（缺失则阻止写作）

```
1. memory/constitution.md - 创作原则
3. stories/*/specification.md - 故事规格
4. stories/*/creative-plan.md - 创作计划
5. stories/*/tasks.md - 当前任务
6. spec/tracking/character-state.json - 角色状态
7. spec/tracking/relationships.json - 关系网络
```

**逻辑**：没有这些文件，AI不知道：
- 要遵循什么原则
- 故事是关于什么的
- 当前写到哪里了
- 角色是谁、什么状态

### 可选文件（缺失时警告但允许继续）

```
2. memory/style-reference.md - 风格参考
8. spec/tracking/plot-tracker.json - 情节追踪
9. spec/tracking/validation-rules.json - 验证规则
```

**逻辑**：这些文件增强质量，但不是最低要求：
- style-reference：某些用户不用/book-internalize
- plot-tracker：简单故事可能不需要
- validation-rules：非必需的自动化

---

## 防失焦机制

### 问题场景

```
第1章写作：
- AI记得所有设定
- 质量很好

第10章写作：
- 对话已经很长
- AI开始遗忘第1章的设定

第30章写作：
- 完全忘记早期设定
- 角色性格走样
- 情节自相矛盾
```

### 解决机制

```
每次写作前：
- 强制重读所有核心文件
- 重新加载完整context
- 像写第1章一样对待第30章

结果：
- 第30章质量 ≈ 第1章质量
- 一致性保持
- 不再失焦
```

### 效果对比

| 对比维度 | 无检查清单 | 有检查清单 |
|---------|----------|----------|
| 第1-10章 | ✓ 质量好 | ✓ 质量好 |
| 第11-30章 | ⚠️ 开始不稳定 | ✓ 保持稳定 |
| 第31-50章 | ❌ 明显失焦 | ✓ 依然稳定 |
| 第51+章 | ❌ 严重失焦 | ✓ 长期稳定 |

---

## 配置选项

### 调整严格度

**默认：严格模式**（推荐）
```
"使用严格检查清单模式"
→ 缺少必需文件则阻止写作
```

**宽松模式**（不推荐）
```
"使用宽松检查清单模式"
→ 允许跳过部分文件（不推荐，可能失焦）
```

### 自定义检查项

如果你有额外的重要文件：

```
"检查清单请额外包含：
- spec/knowledge/worldbuilding/magic-system.md
- spec/knowledge/characters/protagonist-profile.md"
```

---

## 性能优化

### Token消耗

```
每次写作的额外token成本：

9个文件读取：
- constitution.md：~200 tokens
- specification.md：~500 tokens
- creative-plan.md：~300 tokens
- tasks.md：~150 tokens
- character-state.json：~200 tokens
- relationships.json：~150 tokens
- 其他：~200 tokens

总计：约1700 tokens/次写作

收益：
- 避免失焦导致的重写（节省数万tokens）
- 保持质量一致（用户满意度）
- 长篇项目的可持续性
```

**ROI极高**：1700 tokens换来长期稳定质量。

### 缓存策略

```
同一写作会话中：
第1次写作：读取所有文件（1700 tokens）
第2次写作（1小时内）：检查文件是否修改
- 未修改：使用缓存（0 tokens）
- 已修改：重新读取（部分tokens）
```

---

## 常见问题

### Q: 每次写作都要读这么多文件，会不会很慢？

**A**: 不会。
- 文件读取很快（毫秒级）
- token消耗合理（~1700 tokens）
- 换来的是长期质量保证

**对比**：
- 不用检查清单：第30章质量差 → 用户要求重写10章 → 浪费数万tokens
- 用检查清单：每章+1700 tokens → 50章也只+85000 tokens → 但质量稳定

### Q: 我能跳过检查清单吗？

**A**: 技术上可以，但**强烈不推荐**。

```
"跳过检查清单，直接写作"
→ AI会警告："不推荐，可能导致失焦"
→ 但会尊重你的选择
```

**后果自负**：30章后失焦了别说我没提醒你😊

### Q: 某些文件我确实没有怎么办？

**A**: 分两种情况：

**必需文件缺失**（constitution、specification等）：
→ 阻止写作，提示先运行对应命令创建

**可选文件缺失**（style-reference、plot-tracker）：
→ 警告但允许继续，建议后续创建

### Q: 检查清单和setting-detector的关系？

**A**: 互补工作：

```
pre-write-checklist：
- 加载项目特定文件（你的故事数据）

setting-detector：
- 加载通用知识库（类型惯例、写作技巧）

两者结合 = 完整context：
你的故事设定 + 类型专业知识
```

### Q: 100章的长篇小说也要每次都读吗？

**A**: 是的，而且**更需要**。

```
长篇小说的挑战：
- 设定更复杂
- 角色更多
- 情节线更多
- AI更容易忘记

检查清单的作用：
- 确保第100章和第1章质量一致
- 防止角色性格突变
- 防止情节自相矛盾

这是长篇小说质量保证的基石。
```

---

## 最佳实践

### 1. 保持文件更新

检查清单只能确保AI读取文件，但文件内容要准确：

```
✓ 角色状态变化 → 更新 character-state.json
✓ 关系变化 → 更新 relationships.json
✓ 新情节线 → 更新 plot-tracker.json
```

### 2. 定期运行 `/track`

```
建议频率：每5-10章运行一次 `/track`
作用：
- 更新tracking文件
- 验证一致性
- 发现潜在问题
```

### 3. 重要变更后手动触发

```
如果你手动修改了关键文件：
"请重新执行检查清单，重新加载所有文件"

确保AI看到最新状态。
```

### 4. 与consistency-checker配合

```
pre-write-checklist（写前）：
- 加载所有context
- 准备写作

consistency-checker（写中/写后）：
- 监控一致性
- 发现矛盾
```

双重保障 = 最高质量。

---

## 技术实现

### 文件读取顺序

```
优先级排序（重要的先读）：
1. constitution（最高原则）
2. specification（故事核心）
3. creative-plan（技术方案）
4. tasks（当前任务）
5. character-state（角色数据）
6. relationships（关系数据）
7. plot-tracker（情节追踪）
8. validation-rules（验证规则）
9. style-reference（风格参考）
```

### 错误处理

```
文件不存在：
→ 必需文件：阻止写作，提示创建
→ 可选文件：警告，允许继续

文件格式错误：
→ JSON解析失败：显示错误，建议修复
→ Markdown格式问题：尽力读取，标记问题

文件过大：
→ 超过10000行：警告（可能影响性能）
→ 建议拆分文件
```

---

## 总结

pre-write-checklist是Novel Writer Skills v1.0的**核心创新**：

✓ 解决AI长篇失焦问题
✓ 强制重读关键文件
✓ 确保context完整性
✓ 保持质量长期稳定
✓ 适合专业作者长篇创作

**30章后不再失焦 = 长期竞争力** 🎯

---

**本Skill版本**: v1.0
**最后更新**: 2025-10-18
**核心问题**: 解决30章后AI失焦
**配合**: write.md, setting-detector, consistency-checker
