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
| `develop/handoff/H-0006-项目暂停-概念命名未对齐.md` | 为什么暂停、恢复条件 | 历史 |
| `develop/handoff/H-0007-概念定义应为基石环节.md` | 概念定义环节待设计（只记录） | 历史 |
| `develop/handoff/H-0008-结构信息两维度定案.md` | 三级结构 + 信息两维度的定案过程 | 历史 |
| `develop/handoff/H-0009-用共识替代元概念.md` | 为什么弃用「元概念」、改用「共识」 | 历史 |
| `develop/handoff/H-0010-概念排查依据v0.1.md` | 查概念用的缺陷分类与依据（v0.2） | 历史 |
| `develop/handoff/H-0011-B轨道试点组织域.md` | B 轨道试点：组织域查出 5 处缺口 | 历史 |
| `develop/handoff/H-0012-A轨道首轮地点与分支.md` | 「地点」「分支」两词原定义错在哪 | 历史 |
| `develop/handoff/H-0013-A轨道二轮文档记录域.md` | ③文档记录域四词定案，删「节点」 | 历史 |
| `develop/handoff/H-0014-B域骨架与元概念结案.md` | ②骨架域五词 + 元概念结案 | 历史 |
| `develop/handoff/H-0015-概念表接通v1.4.0.md` | 概念表如何接入启动协议与门禁 | 历史 |
| `develop/handoff/H-0016-文档一致性补齐.md` | INDEX 漏登记与旧字段的修法与根因 | 历史 |

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
