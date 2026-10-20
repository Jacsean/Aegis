---
name: aegis-p4-implement
description: Use when writing or changing code after design approval, when a bug or unexpected behavior is being investigated, or when a fix took several attempts
---

# Aegis P4 Implement

## Overview

按已通过的设计写代码，**边做边把踩过的坑记下来**。

核心原则：**没看到测试失败，就不知道测试在测什么。**

## When to Use

- 设计已通过 P3，开始写代码
- 修 bug、调试异常行为
- 重构既有代码

## 动作

### 1. 环境确认

Python 一律 `.venv/bin/python`，不用系统 Python，不依赖 activate。

### 2. TDD 循环

```
写失败测试 → 真的看到它失败 → 写最小实现 → 看到它通过 → 重构
```

每个功能点：1 正常用例 + 1 边界用例。修 bug 先写能复现的失败测试。

### 3. 前端以 demo 为准

样式从 `docs/design/STYLE.md` 取，不临时决定。
5 种状态（正常/空/加载/错误/交互反馈）必须全实现。

### 4. incident 强制记录

满足任一条件必须建 `docs/incidents/INC-xxx.md`：
- 调试超 15 分钟
- 试错 2 次以上
- 发现设计没考虑到
- 用户指出的问题
- 环境导致非预期行为

**「预防」一节必填**（加测试 / 加 gate 检查 / 改规范 / 补设计），没写不算闭环。

### 5. 偏离设计要回写

不要偷偷改。在 DESIGN.md 对应节标注「实现时调整为…，原因…」。
涉及架构 → 加 ADR；涉及范围 → 回 P1 或 P0.5。

## 完成标准

- [ ] 测试全绿且**贴出输出**
- [ ] 无 TODO 遗留（或已登记）
- [ ] 无调试残留
- [ ] 前端 5 态齐全
- [ ] 偏离处已回写 DESIGN.md
- [ ] `bash scripts/gate.sh P4` PASS

## 必须停下来问的情况

- 设计不可行要改架构
- 需要引入新依赖
- 需求有歧义，两种实现都说得通
- 想删除或重写已有代码

## Common Mistakes

| 错误 | 纠正 |
|---|---|
| 没看到测试失败就写实现 | 必须真的看到 RED |
| 调试完不记 incident | 超 15 分钟就记 |
| incident 不写预防 | 只是日记，无累积 |
| 偷偷改设计 | 文档与代码背离 |
| 前端只做正常态 | 5 态全做 |
| 一个提交改十个文件 | 小步提交 |

## Red Flags — STOP

- "这个太简单不用写测试" → 简单代码一样会坏
- "我手动试过了" → 手动试过不等于有测试
- "先写完再补测试" → 顺序反了，测试会写成"验证我写的代码"而不是"验证应该做什么"
- "这个小问题不值得记" → 同一坑第三次踩时就不这么想了
- "设计有问题但我先绕着写" → 绕的代价后期更大
