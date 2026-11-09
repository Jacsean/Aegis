#!/usr/bin/env bash
# Aegis 拦截：不许在主干上直接提交（Reasonix PreToolUse，可阻断）
# exit 2 = 阻断，stderr 会回灌给模型
#
# 为什么 match 用 "*"：Reasonix 的 match 是锚定正则，且各版本命令工具名不一致
#（bash / run_command / shell …）。所以匹配所有，靠 payload 里的 command 内容判断。

set -uo pipefail

payload="$(cat 2>/dev/null || true)"
[ -z "$payload" ] && exit 0

# 只关心含 git commit / git merge / git push 的命令
case "$payload" in
  *git*commit*|*git*merge*|*git*push*) ;;
  *) exit 0 ;;
esac

branch="$(git branch --show-current 2>/dev/null || echo "")"

case "$branch" in
  main|master|"")
    echo "AEGIS 拦截：当前在主干（${branch:-游离 / 非 git 仓库}），不许直接提交。" >&2
    echo "先建分支：git checkout -b <类型>/<短名>（类型：feat / fix / docs / refactor / test / chore）" >&2
    exit 2
    ;;
esac

exit 0
