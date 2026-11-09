# STATE

> 状态快照。换会话先读这个，再读 `docs/README.md`。

- **Aegis 框架** · **当前：v3.0.0 已定版（本地）** · 分支：main

## 已完成

- **v3.0.0 定版**：tag `v3.0.0`（2026-11-06），交付包 `../out/aegis-git-v3.0.0.tar.gz`
- **三层挂载在 Reasonix 上实测**：
  - 入口注入（SessionStart + AGENTS.md 自动加载）—— 模型复述注入原文
  - 调用拦截（PreToolUse：缺 NOTES 拦写文件、main 上拦 commit/merge/push）
  - 出口把关（Stop 只能提醒，平台不允许阻断）
- **4 个维度全部实测有效**：认知 / 事实 / 语义 / 时间（详见 `docs/internal/reasonix/FINDINGS.md`）
- **跨会话接续实测通过**：新上下文只收到「接着做」，主动读 NOTES、没重提被否定的方案
- **目录按行业约定统一**（Diátaxis + ADR + SRE）：`docs/{guides,reference,explanation,adr,incidents,release,rfc,internal}`
- **修复 13 条实测缺陷**，最严重的是 hook 的 `match` 用锚定正则导致整层从未触发

## 进行中

- **推送未完成**：`origin` 指向 `/workspace/aegis`，在 Windows 上解析成
  `C:/Program Files/Git/workspace/aegis`，不可达。需要换一个真实远端。

## 待验证（v3.0.0 之后）

| # | 事项 | 为什么还没做 |
|:--:|---|---|
| 1 | **NOTES 自写质量** | 已测「读 NOTES 能否接上」，未测「能否自己写清楚」 |
| 2 | 真实项目验证 | 只跑过贪吃蛇 + 一次评估任务 |
| 3 | Stop 层替代方案 | 试试 `UserPromptSubmit` 能否补上阻断能力 |

## 已知限制

- **只实现 Reasonix 一个平台**：Claude Code / Trae 的 hook 格式已知但未实现
- **Stop 不能阻断**：平台只允许 PreToolUse / UserPromptSubmit 返回 exit 2
- **4 个维度查不了「判断是否正确」**：它们查的是「言行是否一致」（这条是能力边界，不是缺陷）
- **定位仍是「替代」而非「叠加」**：评估报告建议改成叠加层，尚未动

## 门禁

- S1：PASS（`bash scripts/gate.sh`）
