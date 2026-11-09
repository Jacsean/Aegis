#!/usr/bin/env bash
# Aegis 拦截：写文件前检查 NOTES.md 是否存在（Reasonix PreToolUse，可阻断）
# exit 2 = 阻断，stderr 会回灌给模型
#
# 为什么 match 用 "*" 而不是 "write|edit"：
#   Reasonix 的 match 是**锚定**正则，`write` 不匹配 `write_file`（实测踩过）。
#   而各版本工具名不一致（write / write_file / edit / edit_file / multi_edit），
#   所以改成匹配所有，由本脚本按 toolName 自己判断。

set -uo pipefail

payload="$(cat 2>/dev/null || true)"

# 调试日志：设 AEGIS_HOOK_DEBUG=1 时记录每次收到的 payload（用于核对真实字段名）
if [ "${AEGIS_HOOK_DEBUG:-0}" = "1" ]; then
  printf '[%s] guard-write payload: %s\n' "$(date +%H:%M:%S)" "$payload" >> "${TMPDIR:-/tmp}/aegis-hook-debug.log" 2>/dev/null || true
fi
[ -z "$payload" ] && exit 0

# ---- 1. 取工具名，只处理写入类 ----
tool="$(printf '%s' "$payload" | grep -oE '"toolName"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"([^"]*)"$/\1/')"

case "$tool" in
  *write*|*edit*|*create*|*append*) ;;
  *) exit 0 ;;   # read / bash / grep / ls 等一律放行
esac

# ---- 2. 取目标路径，写 NOTES.md 本身不拦 ----
target="$(printf '%s' "$payload" | grep -oE '"(path|file_path|target)"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')"

case "$target" in
  *NOTES.md|*NOTES-ARCHIVE.md) exit 0 ;;
esac

# ---- 3. NOTES.md 不存在 → 阻断 ----
if [ ! -f "NOTES.md" ]; then
  echo "[AEGIS BLOCKED — 不是权限问题，是项目规则] 这个项目还没有 NOTES.md。" >&2
  echo "被拦下的操作：$tool → ${target:-未知目标}" >&2
  echo "怎么解：先建 NOTES.md（格式见 AGENTS.md 第二节），再重试同一操作。" >&2
  echo "为什么：没有记录，这次做完下次接不上（Aegis 的「时间」维度）。" >&2
  exit 2
fi

exit 0
