---
name: aegis-p5-verify
description: Use when implementation is complete and about to be declared finished, or when code has not yet been checked against requirements, quality standards, and the incident history
---

# Aegis P5 Verify

## Overview

交付前最后一关。**三轮独立 review，Critical 清零才放行。**

核心原则：**一轮 review 只能看见一个视角。需求、工程、历史，必须分开看。**

## When to Use

- 实现完成，准备宣称"做完了"
- 准备合并分支或交付
- 用户问"好了吗"

## 三轮

### 第一轮：规格符合性（对不对）

**只看"做的是不是要的"，不看代码写得好不好。**

- 逐条对照 PRD 验收标准，做表：标准 / 实现位置 / 符合 / 证据
- 对照 ALIGN：「这次不做什么」有没有做，「绝对不要」有没有踩

### 第二轮：代码质量（好不好）

**只看"写得好不好"，不看功能对不对。**

命名、死代码、硬编码、调试残留、空 catch、依赖注入、
性能隐患、注释、未确认依赖、测试覆盖（正常+边界）。

### 第三轮：历史缺陷回灌（会不会再犯）⭐

**这是最关键的一轮，也是最容易漏的一轮。**

打开 `docs/incidents/`，**逐条**问「本次会不会让它再发生」，做成表：

| INC | 现象 | 会再犯 | 依据 |
|---|---|---|---|

「会再犯=是」→ **必须修**，不能只记录。
条目数必须等于 incidents 数量，一条不落。

## 铁律：三轮独立视角

同一轮既写又审 = 自证，不算。

单人项目最低要求：**三轮全部记录完再统一修**，不能边审边改
（否则后两轮审的是改后的代码，结论不一致）。

## 放行规则

- Critical = 0
- Major 已修或已登记
- Minor 可登记后放行

## 完成标准

- [ ] `docs/reviews/REVIEW-CODE-<今日>.md` 存在
- [ ] 三轮都有记录
- [ ] 第一轮有 PRD 逐条对照表
- [ ] 第三轮有完整 INC 对照表
- [ ] Critical = 0
- [ ] 用户签字
- [ ] `bash scripts/gate.sh P5` PASS

## 给用户的验收摘要

不要贴代码，只给结论 + 证据：

```
规格符合：8 条标准，7 通过，1 部分实现
代码质量：Critical 0，Major 2 已修，Minor 3 已登记
历史回灌：检查 12 条，1 条有重犯风险，已修

测试输出：<paste 42 passed>

是否可以进入归档？
```

## Common Mistakes

| 错误 | 纠正 |
|---|---|
| 三轮合成一轮 | 视角混淆，漏检严重 |
| 跳过第三轮 | 历史缺陷必然复发 |
| INC 对照表写"无风险"了事 | 每条都要写依据 |
| 边审边改 | 三轮结论不一致 |
| Critical 不为 0 就放行 | 带病交付 |
| 只跑测试不看测试内容 | 测试本身可能错 |

## Red Flags — STOP

- "测试都过了，不用审了" → 测试过 ≠ 需求对
- "代码挺整洁的" → 整洁是感觉，清单是证据
- "上次的问题我记得，不会犯" → 记得 ≠ 检查过
- "历史问题跟这次无关" → 逐条确认过才叫无关
