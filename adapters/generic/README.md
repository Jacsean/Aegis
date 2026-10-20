# 通用适配（其它任意 agent）

## 接入判断

按 agent 支持的能力分三档：

| agent 能力 | 需要的文件 | 效果 |
|---|---|---|
| 只读一个约定文件（`AGENTS.md` / `README.md` / 自定义）| 指向 `AGENTS.md` 或直接用它 | 完整流程可用（阶段 + 制品 + 讨论机制）|
| 支持 rules 目录（Cursor / Trae 类）| 用 `adapters/cursor/` 或 `adapters/trae/` | 加一条常驻规则，确保会话开始即加载 |
| 支持 skills 目录 | 加入 `.skills/` | 另加按需加载 9 个阶段 skill，省 token |

## 最小可用集

只要满足两条，就能用 Aegis：

1. agent 每轮会话开始时能读到 `AGENTS.md` 与 `STATE.md`；
2. agent 能执行 shell（跑 `scripts/gate.sh`）；不能执行则由 agent 口述检查项、人工确认。

## 不要做的事

- 不要把 `.ai/` 的内容整篇粘进系统提示词——那是 29000 tokens，且违反「按需加载」。
- 不要在两个地方维护同一规则（`AGENTS.md` 与某 agent 的 rules 里各写一遍），必然漂移。
