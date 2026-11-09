#!/usr/bin/env bash
# Aegis 拦截：写文件前检查 NOTES.md 是否存在（Reasonix PreToolUse，可阻断）
# exit 2 = 阻断，stderr 会回灌给模型

set -uo pipefail

# Reasonix 从 stdin 传一行 JSON：{"event":"PreToolUse","cwd":"...","toolName":"write","toolArgs":{...}}
payload="$(cat 2>/dev/null || true)"

# 从 payload 里粗略取目标路径（不依赖 jq）
target="$(printf '%s' "$payload" | grep -oE '"(path|file_path|target)"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')"

# 写 NOTES.md 本身不拦（那正是我们要它做的）
case "$target" in
  *NOTES.md|*NOTES-ARCHIVE.md) exit 0 ;;
esac

# NOTES.md 不存在 → 阻断，要求先建
if [ ! -f "NOTES.md" ]; then
  echo "AEGIS 拦截：这个项目还没有 NOTES.md。" >&2
  echo "先建一份（内容见 AGENTS.md 第二节），再写文件。理由：没有记录，这次做完下次接不上。" >&2
  exit 2
fi

exit 0
