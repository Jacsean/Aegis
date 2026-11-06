# AEGIS 分工约定

> 生成时间：2026-11-06 13:55
> 本文件说明：这个项目里 Aegis 和已有能力怎么分工。**换 agent 接手时，先读这份再动手。**
> 重新生成：`bash scripts/gen-division.sh .`（会覆盖本文件）

---

## 一、Aegis 负责什么（底线，不可绕过）

| 环节 | 管什么 |
|---|---|
| 入口 | 判断「你要的是不是他需要的」，给出判断和依据 |
| 出口 | 记录（NOTES 更新）/ 来源标注 / 4 个问题逐条过 |

**Aegis 不管**：怎么做测试、怎么设计方案、怎么调试、用什么框架——那些是专业做法，由对应能力或你决定。

---

## 二、检测到的能力，分工如下

| 能力 | 它负责什么 | 怎么和 Aegis 相处 |
|---|---|---|
| `brainstorming` | 发散 2-3 个方案 + 权衡 | Aegis 先判断「你要的是不是他需要的」，它再发散 |
| `dispatching-parallel-agents` | 子智能体怎么派 | Aegis 不碰 |
| `executing-plans` | 计划怎么写、怎么执行 | Aegis 不碰 |
| `finishing-a-development-branch` | 分支怎么收尾 | Aegis 不碰 |
| `receiving-code-review` | 代码评审 | 它评代码质量，Aegis 不评价内容好坏 |
| `requesting-code-review` | 代码评审 | 它评代码质量，Aegis 不评价内容好坏 |
| `skill-creator` | 怎么做 skill | Aegis 不碰 |
| `subagent-driven-development` | 子智能体怎么派 | Aegis 不碰 |
| `systematic-debugging` | 怎么调试 | Aegis 不碰 |
| `test-driven-development` | 测试怎么做、怎么跑 | Aegis 不碰；除非 constraints.md 里要求「必须有测试」 |
| `using-git-worktrees` | 工作区怎么隔离 | Aegis 不碰 |
| `using-superpowers` | 让 agent 先找该用哪个 skill | 两个入口都注入；Aegis 在前（先判断要不要做），它在后 |
| `verification-before-completion` | 验证是否真的完成（跑测试、看输出） | 它查「做对没」，Aegis 查「记录没、来源标没、4 问题过没过」 |
| `writing-plans` | 计划怎么写、怎么执行 | Aegis 不碰 |
| `writing-skills` | 怎么做 skill | Aegis 不碰 |
| `find-skills` | 查找/安装外部 skill | 它负责装，Aegis 负责记账（装完进本文件，调用进 NOTES） |
| `knowledge-handbook` | 沉淀成可检索的手册 | NOTES.md 是源，知识库是提炼；NOTES 降级为索引层 |
| `maker-project-log` | 变更日志 / 项目归档 | Aegis 不碰 |
| `thinking-model-workflows` | 用 PDCA/OODA/FMEA 编排多智能体工作流 | 它管「多个 agent 怎么协同」，Aegis 管「一句话怎么理解」，维度不同 |

**汇总**：自有 1 项 · 串联 3 项 · 并列 5 项 · 让路 11 项

**另有 12 项未收录的能力**（按下面第三节的默认规则处理）：

```
frontend-design arduino-maker esp32-idf-dev habit-to-capability legacy-cpp-maintenance microsoft-foundry omron-cx-programmer-maintenance omron-plc-host-comm opencv-legacy-cpp raspberry-pi-dev stm32-hal-dev vc2010-mfc-toolchain
```

---

## 三、对任何未收录的能力，默认规则

1. Aegis **不管它怎么做**（那是它的专业）
2. 它的**产出要进 `NOTES.md`**（用了什么、产出在哪、留下什么）
3. 它的**结论要标来源**：`[检索]` / `[推荐]` / `[无参照]`
4. 一次任务**最多用 2 个**外接能力；超过说明任务太大，该拆

---

## 四、Aegis 明确做不到的事（提前说明，免得误判）

| 做不到 | 为什么 |
|---|---|
| 拦住「已加载到上下文的其他 skill 指令被执行」 | 那不是工具调用，是模型照着做，没有事件可挂 |
| 拦住「模型不调用任何工具、直接回答」 | 没有动作可拦 |
| 验证「结论内容对不对」 | 只能验证形式（有没有标来源），不能验证真假 |

**所以 Aegis 的定位是：审计 + 否决权，不是控制权。** 它能说「这不算完成」，不能说「你不能这么想」。
