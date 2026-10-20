---
name: aegis-p3-validate
description: Use when design artifacts exist and implementation has not started, or when about to write code without having reviewed the design against requirements and past incidents
---

# Aegis P3 Validate

## Overview

设计做完，**先自查再实现**。

核心原则：**在纸上改，成本是改代码的 1/10。**

本阶段只审查与判定，不改设计内容（发现问题就退回 P2 修）。

## When to Use

- DESIGN.md、demo、ADR 已完成，准备开始写代码
- 用户催"直接开始做"（此时更应先自查）

## 动作

### 1. 逐条过 12 项清单

全文见 `.ai/99-reference/design-review-checklist.md`。

**每项必须写三行**，不能只打勾：
- 查了什么
- 结论
- 发现问题怎么处理

### 2. 意图一致性复核（最容易发现问题的一步）

对照 `docs/align/ALIGN-<任务>.md`：

| 对照 | 检查 |
|---|---|
| 第 4 节「这次做什么」 | DESIGN 全覆盖了吗 |
| 第 5 节「这次不做什么」 | 有没有偷偷做了 |
| 第 5 节「绝对不要」 | 有没有踩红线 |
| 第 6 节「什么算搞砸」 | 这个设计会导致那些情形吗 |

### 3. 历史缺陷回灌

打开 `docs/incidents/`，逐条问「这个设计会不会让它再发生」，做成表：

| INC | 现象 | 会再犯 | 依据 |
|---|---|---|---|

「会再犯」的必须当场补设计或登记为已知限制。

### 4. 写 `docs/design/REVIEW-DESIGN.md`

### 5. 给结论（三选一）

- **通过** — 12 项全绿
- **修正后通过** — 1-2 项小问题，现场修完
- **退回 P2** — 3 项以上，或涉及架构/意图偏差

## 完成标准

- [ ] REVIEW-DESIGN.md 勾选条目 ≥ 12，每项有结论
- [ ] 有「意图一致性复核」一节，对照了 ALIGN 四节
- [ ] 有「历史缺陷回灌」一节
- [ ] 结论明确
- [ ] `bash scripts/gate.sh P3` PASS

## Common Mistakes

| 错误 | 纠正 |
|---|---|
| 只打勾不写结论 | 等于没查 |
| 只查技术，不查意图 | 技术全对但做的不是用户要的 |
| 不回灌历史故障 | 老毛病必然复发 |
| 发现问题但"先做再说" | 返工成本 ×10 |
| "已经写了很多，不忍推翻" | 沉没成本，已写的不是保留理由 |

## Red Flags — STOP

- "设计很清晰，不用审" → 清晰是感觉，清单是证据
- "等实现完一起测" → 那时改的成本是现在十倍
- "这个问题很小，先跳过" → 小问题在实现时会被放大
- "用户催得急" → 越急越要先确定方向没跑偏
