# 文档索引

> 本文件只做索引：**有什么、在哪、干什么用、是什么角色**。
> 找不到东西时先查这里。
>
> **角色三种**：`真相源`（改这里，别处跟着变）｜`历史`（只增不改，记当时怎么想）｜`派生物`（由真相源生成，别手改）。
>
> **读的顺序**：`AGENTS.md` → `STATE.md` → 本页 → `develop/CONCEPTS.md` 目录 → 最新一条 `develop/HANDOFF.md` 索引。

---

## develop · 开发过程文档

| 路径 | 内容 | 角色 |
|---|---|---|
| `develop/CONCEPTS.md` | 全局概念表（唯一概念定义处，五域梳理进行中）| **真相源** |
| `develop/HANDOFF.md` | 开发事件索引（一行一条，时间倒序）| 索引 |
| `develop/handoff/` | 开发事件记录（七要素，每个任务一条）| **历史** |
| `develop/handoff/H-0001-建立基线.md` | v1.0.0 基线怎么建的 | 历史 |
| `develop/handoff/H-0002-一次性HANDOFF.md` | 已废止：一次性交接文档的问题 | 历史 |
| `develop/handoff/H-0003-第七维参考同行.md` | 第七维为什么加、怎么加的 | 历史 |
| `develop/handoff/H-0004-五元素问题表述法.md` | 五元素为什么加、怎么加的 | 历史 |
| `develop/handoff/H-0005-定下handoff七要素.md` | 七要素的来源与取舍 | 历史 |

## public · 交付文档

| 路径 | 内容 | 角色 |
|---|---|---|
| `public/README.md` | 这个目录放什么（给项目使用者看的）| 交付 |

---

## 框架本体（不属于某个项目）

| 路径 | 内容 | 角色 |
|---|---|---|
| `.ai/` | 阶段规范（11 份）| **真相源** |
| `.ai/99-reference/` | schema（8 份）| **真相源** |
| `templates/docs/` | 文档模板（12 份）| 真相源 |
| `.skills/` | 阶段 skill（9 份）| **派生物**（`make sync`）|
| `scripts/` | gate / state / branch / sync | 真相源 |
| `adapters/` | 各 agent 的适配壳 | 派生物 |
