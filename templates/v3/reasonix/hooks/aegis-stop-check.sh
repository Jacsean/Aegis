#!/usr/bin/env bash
# Aegis 出口提醒（Reasonix Stop）
#
# 【重要限制】Reasonix 的 Stop 事件**不能阻断**（只有 PreToolUse 和 UserPromptSubmit 能）。
# 所以这个脚本只能输出提醒，不能强制模型补记录。
# 如果 Reasonix 后续支持 Stop 阻断，可把末尾改成 exit 2。

set -uo pipefail

payload="$(cat 2>/dev/null || true)"

[ -f "NOTES.md" ] || { echo "AEGIS 提醒：项目里没有 NOTES.md，这次的决策没被记录。"; exit 0; }

# 判断本轮是否更新过 NOTES.md（30 分钟内算本轮）
if find NOTES.md -mmin -30 2>/dev/null | grep -q .; then
  exit 0
fi

cat <<'EOF'
AEGIS 出口提醒：这次会话里 NOTES.md 没有更新。

如果这次产出的是**里程碑级结果**（一个功能做完 / 一个阶段结束），请补一条：
  用了什么 / 产出在哪 / 用户明确否定的 / 什么情况说明我错了

如果只是中间的问答，忽略这条提醒即可。
EOF

exit 0
