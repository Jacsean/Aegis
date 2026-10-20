---
name: aegis-p2-design
description: Use when a confirmed PRD exists and design work begins, or when front-end visual style, layout, or interaction flow has not been shown to the user as a viewable artifact
---

# Aegis P2 Design

## Overview

把确认过的需求变成**可看、可点、可评审**的方案。
**核心：前端先出 HTML demo，用户看过并确认后，才允许写业务代码。**

核心原则：**用户看不见的设计 = 没有设计。**

## When to Use

- PRD 已确认，进入设计阶段
- 要写前端代码，但还没给用户看过任何可视化产物
- 用户说"直接开始写页面"（此时应拦下，先出 demo）

## 动作

### 1. 架构设计 → `docs/design/DESIGN.md`

七节：模块划分 / 依赖方向 / 数据流图 / 关键接口 / 状态管理 / 错误路径 / 扩展点。

### 2. 前端：先出 HTML demo（本 skill 的核心）

**规则：**

- PRD「关键界面清单」里每个界面，一个 demo 文件
- 路径 `docs/design/demo/01-<名>.html`，编号递增
- **自包含单文件**：CSS/JS 内联，不引 CDN、不需构建、用户双击即开
- 必须有**真实交互**（可悬停、可点击、有状态切换），不是静态图

**每个 demo 必须覆盖 5 种状态：**

| 状态 | 说明 |
|---|---|
| 正常态 | 默认展示 |
| 空状态 | 无数据时 |
| 加载态 | loading 反馈 |
| 错误态 | 出错提示 |
| 交互反馈 | 悬停/点击/禁用 |

> 只有正常态的 demo 是假 demo。5 态是"交互流程确认"的实质内容。

**推荐做法**：在 demo 内加一行切换按钮，让用户能点着看 5 种状态，比写 5 个文件更好用。

### 3. 写 `docs/design/STYLE.md`

色彩 / 字体 / 间距 / 圆角阴影 / 组件规格 / 交互反馈规则 / 响应式断点。
**demo 先行，规范从 demo 提炼** —— 看着 demo 才好说"这个色深一点"。

### 4. 写 ADR

每个重大决策一篇，`docs/adr/ADR-000N-*.md`，「后果」必须写负面代价。

### 5. 请用户看 demo 并确认（不可跳过）

不要问"满意吗"。要问具体的：

```
design/demo/ 下共 N 个文件，请打开查看：
- 01-xxx.html（可点顶部按钮切换 5 种状态）

请确认：
1. 整体视觉风格（配色/字号/疏密）是否符合预期？
2. 每页元素是否齐全、位置是否合理？
3. 交互流程是否顺畅？
4. 空/加载/错误三态是否可接受？

需调整直接说，我改 demo 后再确认。
```

## 完成标准

- [ ] DESIGN.md 七节齐全，含图
- [ ] 依赖单向无环，错误路径已设计
- [ ] 前端：每个关键界面有 demo 文件
- [ ] 前端：每个 demo 覆盖 5 态，浏览器可直接打开
- [ ] STYLE.md 覆盖色彩/字体/间距/组件/交互
- [ ] 每个重大决策有 ADR 且写了负面后果
- [ ] 文档全部登记 INDEX
- [ ] `bash scripts/gate.sh P2` 输出 PASS
- [ ] 用户已打开 demo 并给出确认

## Common Mistakes

| 错误 | 纠正 |
|---|---|
| 不给 demo 直接写代码 | 铁律二硬禁止，风格全靠猜 |
| demo 只有正常态 | 必须 5 态 |
| demo 引 CDN 或需构建 | 用户打不开 = 没 demo |
| demo 是静态截图 | 必须可交互 |
| 先写 STYLE.md 再出 demo | 抽象讨论效率低，demo 先行 |
| 用户说"你看着办" | 给 2-3 个具体方案让选，不给开放式 |

## Red Flags — STOP

- "风格我按主流的来就行" → 主流有几十种，必须确认
- "demo 写完代码再补" → 顺序反了，成本 ×10
- "用户没时间看 demo" → 那就更不能写代码
- "这个界面很简单不用 demo" → 简单的界面同样有风格选择

## 与通用框架的关系

Superpowers 的 `writing-plans` 可参考其计划颗粒度，
但**它不产出可视化设计** —— 这正是本 skill 的核心补充。
