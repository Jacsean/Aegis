#!/usr/bin/env bash
# Aegis 拦截：不许在主干上直接提交（Reasonix PreToolUse，可阻断）
# exit 2 = 阻断，stderr 会回灌给模型

set -uo pipefail

payload="$(cat 2>/dev/null || true)"

# 只关心含 git commit / git merge 的命令
case "$payload" in
  *git*commit*|*git*merge*) ;;
  *) exit 0 ;;
esac

branch="$(git branch --show-current 2>/dev/null || echo "")"

case "$branch" in
  main|master|"")
    echo "AEGIS 拦截：当前在主干（${branch:-游离/无分支}），不许直接提交。" >&2
    echo "先建分支：git checkout -b <类型>/<短名>（类型：feat / fix / docs / refactor / test / chore）" >&2
    exit 2
    ;;
esac

exit 0
