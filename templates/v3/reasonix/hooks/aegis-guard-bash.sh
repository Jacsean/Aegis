#!/usr/bin/env bash
# Aegis 拦截：不许在主干上直接提交（Reasonix PreToolUse，可阻断）
# exit 2 = 阻断，stderr 会回灌给模型
#
# 为什么 match 用 "*"：Reasonix 的 match 是锚定正则，且各版本命令工具名不一致
#（bash / run_command / shell …）。所以匹配所有，靠 payload 里的 command 内容判断。

set -uo pipefail

payload="$(cat 2>/dev/null || true)"
[ -z "$payload" ] && exit 0

# 只处理「命令类」工具：payload 里必须有 "command" 字段
# （ask / read_file / write_file 等没有这个字段，一律放行 —— 否则 ask 的问题里
#   只要提到 "git commit" 就会被误拦，实测踩过）
printf '%s' "$payload" | grep -q '"command"' || exit 0

# 只关心含 git commit / git merge / git push 的命令
case "$payload" in
  *git*commit*|*git*merge*|*git*push*) ;;
  *) exit 0 ;;
esac

branch="$(git branch --show-current 2>/dev/null || echo "")"

case "$branch" in
  main|master|"")
    echo "[AEGIS BLOCKED — 不是权限问题，是项目规则] 当前在主干（${branch:-游离 / 非 git 仓库}），不许直接提交。" >&2
    echo "怎么解：先建分支 git checkout -b <类型>/<短名>（类型：feat / fix / docs / refactor / test / chore），再重试提交。" >&2
    echo "为什么：每个任务独立分支，出问题才能整分支丢弃而不是逐个挑提交。" >&2
    exit 2
    ;;
esac

exit 0
