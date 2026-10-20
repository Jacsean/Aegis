#!/usr/bin/env bash
# Aegis 分支管理
# 用法:
#   bash scripts/branch.sh start <任务短名> [类型]   新建任务分支（默认 feat）
#   bash scripts/branch.sh list                      列出所有任务分支
#   bash scripts/branch.sh status                    当前分支状态
#   bash scripts/branch.sh finish <任务短名>          合并回 main 并清理
#   bash scripts/branch.sh check                     检查分支规范（pre-commit 用）

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; NC='\033[0m'
ok()   { printf "${GREEN}✓${NC} %s\n" "$1"; }
err()  { printf "${RED}✗${NC} %s\n" "$1"; }
info() { printf "${YELLOW}→${NC} %s\n" "$1"; }

TYPES="feat|fix|docs|refactor|test|chore|spike"
MAIN="main"

ensure_git() {
  git rev-parse --git-dir >/dev/null 2>&1 || { err "不是 git 仓库，请先 git init"; exit 1; }
}

current_branch() { git branch --show-current 2>/dev/null || echo ""; }

case "${1:-status}" in

  start)
    NAME="${2:-}"
    TYPE="${3:-feat}"
    [ -n "$NAME" ] || { echo "用法: bash scripts/branch.sh start <任务短名> [类型]"; exit 1; }
    ensure_git

    # 规范：小写字母/数字/连字符
    SLUG="$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
    [ -n "$SLUG" ] || { err "任务短名不合法"; exit 1; }
    [[ "$TYPE" =~ ^($TYPES)$ ]] || { err "类型必须是: $TYPES"; exit 1; }

    BR="$TYPE/$SLUG"

    # 检查工作区干净
    # 例外：STATE.md 是流程自身的状态文件，阶段切换必然改动它。
    # 允许"只有 STATE.md 有改动"时自动提交，否则拒绝（防止把半成品代码带进新分支）。
    if [ -n "$(git status --porcelain)" ]; then
      other="$(git status --porcelain | awk '{print $2}' | grep -v '^STATE\.md$' || true)"
      if [ -z "$other" ] && [ -n "$(git status --porcelain | awk '{print $2}' | grep '^STATE\.md$' || true)" ]; then
        info "仅 STATE.md 有改动（阶段切换所致），自动提交"
        git add STATE.md
        git commit -q -m "chore: 阶段切换前固化 STATE.md" || true
      else
        err "工作区有未提交改动，请先提交或 stash"
        git status --short
        exit 1
      fi
    fi

    # 从 main 拉
    if git show-ref --verify --quiet "refs/heads/$MAIN"; then
      CUR=$(current_branch)
      [ "$CUR" != "$MAIN" ] && { info "切回 $MAIN"; git checkout -q "$MAIN"; }
      git pull -q --ff-only 2>/dev/null || true
    else
      info "尚无 $MAIN 分支，将创建"
      git checkout -q -b "$MAIN" 2>/dev/null || true
    fi

    if git show-ref --verify --quiet "refs/heads/$BR"; then
      err "分支 $BR 已存在"
      exit 1
    fi

    git checkout -q -b "$BR"
    ok "已建分支: $BR"

    # 建对应的 align 目录占位
    mkdir -p docs/align
    if [ ! -f "docs/align/.gitkeep" ]; then touch "docs/align/.gitkeep"; fi

    echo ""
    echo "下一步（铁律六）："
    echo "  1. 写 docs/align/CHECKLIST-${SLUG}-R1.md"
    echo "  2. 与用户逐条讨论，记录 docs/align/ALIGN-${SLUG}-R1.md"
    echo "  3. 再写 R2 checklist，重复一轮"
    echo "  4. 汇总 docs/align/ALIGN-${SLUG}.md 并请用户签字"
    ;;

  list)
    ensure_git
    echo "任务分支（非 $MAIN）："
    git branch --format='  %(refname:short)  %(committerdate:relative)' | grep -vE "^  $MAIN\b" || echo "  （无）"
    ;;

  status)
    ensure_git
    CUR=$(current_branch)
    echo "当前分支：$CUR"
    if [ "$CUR" = "$MAIN" ]; then
      printf "${YELLOW}提示：当前在主分支。新任务请先建分支：${NC}\n"
      echo "  bash scripts/branch.sh start <任务短名>"
    else
      [[ "$CUR" =~ ^($TYPES)/[a-z0-9-]+$ ]] && ok "分支名合规" || err "分支名不合规（应为 <类型>/<短名>）"
      AHEAD=$(git rev-list --count "$MAIN..$CUR" 2>/dev/null || echo 0)
      echo "领先 $MAIN：$AHEAD 个提交"
    fi
    echo ""
    git status --short || true
    ;;

  finish)
    NAME="${2:-}"
    ensure_git
    CUR=$(current_branch)
    [ "$CUR" != "$MAIN" ] || { err "当前在 $MAIN，无需合并"; exit 1; }

    if [ -n "$NAME" ]; then
      SLUG="$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g')"
      # 校验 align 签字存在
      if [ -f "docs/align/ALIGN-${SLUG}.md" ]; then
        grep -q '总确认原话' "docs/align/ALIGN-${SLUG}.md" && ok "ALIGN 签字存在" || err "ALIGN 缺签字"
      else
        info "未找到 docs/align/ALIGN-${SLUG}.md（若已过 P0.5 应存在）"
      fi
    fi

    echo ""
    echo "合并前检查（铁律一）："
    if ! bash scripts/gate.sh > /tmp/aegis_finish.$$ 2>&1; then
      grep -E '✗|FAIL' /tmp/aegis_finish.$$ | head -10
      rm -f /tmp/aegis_finish.$$
      err "门禁未通过，不能合并到 $MAIN"
      echo "  若确需合并：FORCE=1 bash scripts/branch.sh finish"
      [ "${FORCE:-0}" = "1" ] || exit 1
    else
      grep -E 'PASS' /tmp/aegis_finish.$$ | tail -1
      rm -f /tmp/aegis_finish.$$
    fi

    if [ -n "$(git status --porcelain)" ]; then
      err "还有未提交改动，请先提交"
      exit 1
    fi

    BR="$CUR"
    info "合并 $BR → $MAIN"
    git checkout -q "$MAIN"
    git merge -q --no-ff "$BR" -m "merge: $BR" || { err "合并失败（可能有冲突）"; exit 1; }
    ok "已合并"

    echo ""
    read -r -p "删除分支 $BR？(y/N) " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
      git branch -d "$BR" && ok "已删除 $BR"
    else
      info "保留分支 $BR"
    fi
    ;;

  check)
    ensure_git
    CUR=$(current_branch)
    FAIL=0
    if [ "$CUR" = "$MAIN" ]; then
      # 在 main 上且有改动 → 违反分支规范
      if [ -n "$(git status --porcelain)" ]; then
        err "在 $MAIN 上有未提交改动（应先建任务分支）"
        FAIL=1
      else
        ok "在 $MAIN 且工作区干净"
      fi
    else
      [[ "$CUR" =~ ^($TYPES)/[a-z0-9-]+$ ]] && ok "分支名合规: $CUR" || { err "分支名不合规: $CUR"; FAIL=1; }
    fi
    [ "$FAIL" -eq 0 ] && exit 0 || exit 1
    ;;

  *)
    echo "用法: bash scripts/branch.sh [start|list|status|finish|check]"
    exit 1
    ;;
esac
