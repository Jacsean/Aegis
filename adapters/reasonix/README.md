# Reasonix 适配

## 接入方式

Reasonix 直接读仓库根目录 `AGENTS.md`，**不需要额外适配文件**。

Aegis 的入口设计正是为了这个：`AGENTS.md` 是唯一入口，会话开始时按其中「会话启动协议」逐步加载 `.ai/` 下按需文件。

## 需要确认的一点

Reasonix 若支持自定义 rules/skills 目录，把本仓库的 `.skills/` 加进去即可获得 9 个阶段 skill；
若不支持，则跳过 skills，仅靠 `AGENTS.md` + `.ai/` 也能完整运行（skills 只是按需加载的快捷方式，不是必需项）。

## 验证

在 Reasonix 中打开本仓库，首轮对话应能看到 agent 主动读取 `AGENTS.md` 与 `STATE.md`。
