# DeepSeek harness 适配

## 接入方式

DeepSeek harness 直接读仓库根目录 `AGENTS.md`，**不需要额外适配文件**。

## 注意事项

- 若 harness 支持"系统提示词"注入，把 `AGENTS.md` 的前 30 行（会话启动协议 + 六条铁律摘要）粘进去，效果更好。
- 若 harness 不支持工具调用（无法执行 `bash scripts/gate.sh`），则门禁退化为**人工核对**：由 agent 逐条念出检查项，用户确认。这仍然是有效的——门禁的内容比执行方式重要。

## 验证

首轮对话应能看到 agent 读取 `AGENTS.md` 与 `STATE.md`，并声明当前阶段。
