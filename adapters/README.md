# adapters — 跨 agent 适配壳

本目录存放各 agent 的**入口适配文件**。它们是**派生物**，由 `make sync` 从 `AGENTS.md` 与 `.ai/` 生成，**请勿手工编辑**。

## 为什么需要它

不同 agent 读的入口文件不同：

| agent | 读什么 |
|---|---|
| Claude Code | `CLAUDE.md`（本项目用软链指向 `AGENTS.md`）|
| Codex CLI / App | `AGENTS.md` |
| Cursor | `.cursor/rules/*.mdc`（带 frontmatter）|
| Trae CN | `.trae/rules/project_rules.md` |
| CodeBuddy CN / Reasonix / DeepSeek harness / Gemini CLI | `AGENTS.md` 或 `GEMINI.md` |

Aegis 的做法：**只维护一份** `AGENTS.md`，其余全部由它派生。

## 目录

| 路径 | 装到用户项目的什么位置 | 适配 agent |
|---|---|---|
| `cursor/rules.mdc` | `.cursor/rules/aegis.mdc` | Cursor |
| `trae/rules.md` | `.trae/rules/project_rules.md` | Trae CN |
| `codex/AGENTS.md` | 仓库根 `AGENTS.md`（内容已含，无需额外壳）| Codex |
| `claude-code/` | `CLAUDE.md` 软链（无额外文件）| Claude Code |
| `reasonix/` | `AGENTS.md` 直接读（无额外文件）| Reasonix |
| `deepseek/` | `AGENTS.md` 直接读（无额外文件）| DeepSeek harness |
| `generic/` | `AGENTS.md` 直接读（无额外文件）| 其它任意 agent |

空目录里的 `README.md` 说明该 agent 的接入方式，不做代码生成。

## 新增一个 agent 适配

1. 在 `adapters/<name>/` 下放该 agent 要求的入口文件名；
2. 在 `scripts/sync.sh` 的适配段里加一段 `write_if_changed`；
3. 在本表加一行；
4. `make sync && make check-sync` 验证。
