# 文档总索引

> **所有文档必须在此登记。** 新增文档未登记 = S4 门禁不通过。
> 这是保证"文档不散乱、相互可追溯"的机制。

---

## 按阶段归档

### S2 意图校准 ⭐

| 文档 | 一句话说明 | 关联 |
|---|---|---|
| [align/](align/) | 两轮讨论的 checklist 与记录 | → S3 PRD |
| `align/CHECKLIST-<任务>-R1.md` | 第一轮（复述）问题清单 | → ALIGN-R1 |
| `align/ALIGN-<任务>-R1.md` | 第一轮讨论记录与结论 | → R2 |
| `align/CHECKLIST-<任务>-R2.md` | 第二轮（深层）问题清单 | → ALIGN-R2 |
| `align/ALIGN-<任务>-R2.md` | 第二轮讨论记录与结论 | → 汇总 |
| `align/ALIGN-<任务>.md` | **意图校准结论（S3 的唯一依据）** | → S3 PRD |

### S3 构思

| 文档 | 一句话说明 | 关联 |
|---|---|---|
| [prd.md](prd.md) | 需求文档（六节，含非目标） | → S4 DESIGN |

### S4 设计

| 文档 | 一句话说明 | 关联 |
|---|---|---|
| [design/DESIGN.md](design/DESIGN.md) | 设计主文档（架构/数据流/接口） | ← PRD，→ demo/ADR |
| [design/STYLE.md](design/STYLE.md) | 样式与交互规范 | ← demo |
| `design/demo/*.html` | 可交互 HTML demo（每个界面一个） | ← PRD 关键界面清单 |
| [adr/](adr/) | 架构决策记录 | ← DESIGN |

### S5 验证

| 文档 | 一句话说明 | 关联 |
|---|---|---|
| [design/REVIEW-DESIGN.md](design/REVIEW-DESIGN.md) | 设计评审 12 项 + 意图复核 + 历史回灌 | ← DESIGN / demo / ALIGN |

### S6 实现

| 文档 | 一句话说明 | 关联 |
|---|---|---|
| `src/` `tests/` | 源码与测试（TDD，每功能点正常+边界） | ← DESIGN / demo |
| [incidents/](incidents/) | 故障与问题库（含**预防**措施） | ← 任意阶段踩坑 → S5 回灌 |
| [incidents/INC-0001-template.md](incidents/INC-0001-template.md) | INC 模板（现象/复现/根因/解决/预防/关联） | ← 触发条件见 `.ai/05-S6-implement.md` |

### S5 校验

| 文档 | 一句话说明 | 关联 |
|---|---|---|
| [reviews/](reviews/) | 代码评审记录（三轮） | ← DESIGN / incidents |
| [reviews/REVIEW-CODE-template.md](reviews/REVIEW-CODE-template.md) | 三轮评审模板（含 INC 对照表） | ← incidents 全量 |

### S7 归档

| 文档 | 一句话说明 | 关联 |
|---|---|---|
| [../STATE.md](../STATE.md) | 状态快照整体重写（≤40 行） | → 下一个会话 |
| [../CHANGELOG.md](../CHANGELOG.md) | 变更日志（语义化版本，可追溯） | → tag |
| [../archive/](../archive/) | 一次性脚本 / 大体积数据 / 旧交付说明 | ← S7 清理 |

### S8 交付

| 文档 | 一句话说明 | 关联 |
|---|---|---|
| [release/](release/) | 交付说明（用法/限制/下一步） | ← 全部 |
| [release/RELEASE-template.md](release/RELEASE-template.md) | 六节模板（已知限制与验证证据强制） | ← 冒烟验证 |
| `release/RELEASE-v<X.Y.Z>.md` | 具体版本交付说明 | → 用户签收 |

### 始终

| 文档 | 一句话说明 |
|---|---|
| [../STATE.md](../STATE.md) | 状态快照（40 行内） |
| [../AGENTS.md](../AGENTS.md) | agent 入口 |
| [../CHANGELOG.md](../CHANGELOG.md) | 变更日志 |

---

## 登记规则

**S7 归档时 `gate.sh` 会反查**：`docs/` 下任何未登记的 `.md` / `.html` 都会导致 S7 门禁 FAIL
（目录级登记也算，如 `align/`、`adr/`、`release/` 已概括整个目录）。

新增文档时，在本文件对应阶段下加一行：

```
| [路径](路径) | 一句话说明 | ← 上游 / → 下游 |
```

**禁止：** 把文档放在 `docs/` 之外的任意位置（除 `AGENTS.md`、`STATE.md`、`CHANGELOG.md`、`.ai/`、`archive/`）。

**可追溯性要求**（S7 检查）：每篇文档至少要有一条入链或出链，孤立文档等于死文档。

| 文档类型 | 必须被谁引用 |
|---|---|
| `ALIGN-*.md` | `docs/prd.md` |
| `ADR-*.md` | `docs/design/DESIGN.md` |
| `INC-*.md` | `docs/reviews/REVIEW-CODE-*.md` 或 `STATE.md` |
| `REVIEW-*.md` | `STATE.md` 门禁签字 |
