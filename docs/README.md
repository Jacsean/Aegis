# 文档索引

> 本文件只做索引：**有什么、在哪、干什么用、是什么角色**。找不到东西先查这里。
>
> **角色三种**：`真相源`（改这里，别处跟着变）｜`历史`（只增不改）｜`派生物`（由真相源生成，别手改）。
> **状态行**：设计文档头部必带 `> 状态：定稿｜暂定｜已作废→指向`。标「已作废」的禁止引用。
>
> **读的顺序**：`AGENTS.md` → `STATE.md` → 本页 → `reference/concepts.md` 目录 → 当前阶段阶段卡。

---

## 一、随交付（使用者在交付包里能看到）

| 路径 | 内容 | 角色 |
|---|---|---|
| `reference/concepts.md` | 全局概念表（唯一概念定义处，改词只改这里） | **真相源** |
| `guides/README.md` | 面向使用者的说明入口 | 交付 |
| `release/RELEASE-*.md` | 每个版本的发布说明 | 交付 |
| `adr/ADR-*.md` | 架构决策记录（一份决策一个文件） | 交付 |
| `incidents/INC-*.md` | 故障记录（含「预防」必填） | 交付 |

**新项目才有的（本框架仓库自身暂无，由 `templates/docs/` 提供）**

| 路径 | 内容 |
|---|---|
| `prd.md` | 需求（S3） |
| `design/DESIGN.md` `design/STYLE.md` `design/demo/` `design/REVIEW-DESIGN.md` | 设计主文档、样式规范、HTML demo、设计评审（S4/S5） |

---

## 二、设计者维度（**交付包中不存在**）

> 以下目录在 `deliver.sh` 打包时被剔除。它们记录的是「框架自己怎么被造出来」，
> 使用者的工作树里不该出现。

| 路径 | 内容 |
|---|---|
| `internal/reasonix/` | v3 重构的过程记录（安装清单、概念草案、实测发现） |
| `internal/handoff/` | 开发事件记录（每任务一份，七要素） |
| `internal/handoff.md` | 开发事件索引 |
| `internal/archive/` | 一次性脚本 / 大体积数据 / 旧交付说明 |
| `internal/legacy/` | 旧版本（八阶段）遗留文档 |
| `internal/design/` | 框架自身的内部设计草案 |
| `internal/reviews/` | 代码评审记录 |
| `internal/path-map.md` | 路径映射表（旧路径 → 新路径） |
| `rfc/` | 提案与讨论（S2 两轮讨论稿 ALIGN / CHECKLIST） |

---

## 三、框架本体（使用者的全部操作对象）

| 路径 | 内容 | 角色 |
|---|---|---|
| `AGENTS.md` | 入口：启动协议 + 七条铁律 + 阶段表 | **真相源** |
| `.ai/` | 阶段规范（00-core + 09 场景决断 + 10~17 八阶段 + 90-preferences） | **真相源** |
| `.ai/99-reference/` | schema（按需加载） | **真相源** |
| `templates/docs/` | 文档模板（新项目开工时复制） | 真相源 |
| `.skills/` | 阶段 skill | **派生物**（`make sync`） |
| `adapters/` | 各 agent 的适配壳 | 派生物 |
| `scripts/` | gate / state / branch / sync / deliver / check-no-legacy / install-v3 / gen-division | 真相源 |
| `examples/` | 各制品的填写示例 | 真相源 |

---

## 四、根目录固定文件（行业约定）

| 文件 | 依据 |
|---|---|
| `README.md` | 项目说明 |
| `CHANGELOG.md` | Keep a Changelog |
| `CONTRIBUTING.md` | GitHub 社区标准 |
| `VERSION` | 版本号 |
| `STATE.md` | 状态快照（Aegis 特有，≤40 行） |
