#!/usr/bin/env bash
# 检查「有模板但没装」—— 本项目的铁律检测器
#
# 背景：
#   Aegis 反复犯同一个错——把有效方法固化成「本仓库的文档」，而不是「使用者的能力」。
#   具体表现：templates/ 里放了模板，但 install-v3.sh 没把它装过去，使用者永远拿不到。
#
# 这个脚本检查：templates/ 下的每个文件，是否真的会被安装到使用者项目。
#
# 用法: bash scripts/check-templates.sh
# 退出码: 0 = 全部会被安装   1 = 有模板没被安装

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

INSTALL="scripts/install-v3.sh"
[ -f "$INSTALL" ] || { echo "找不到 $INSTALL"; exit 2; }

echo "==============================================="
echo " 模板可达性检查（有模板 ≠ 使用者能拿到）"
echo "==============================================="
echo ""

MISS=0
TOTAL=0
SKIPPED=0

# 明确「Aegis 自己流程专用、不给使用者」的模板（白名单，必须写清为什么不给）
# 判断依据：这些是 Aegis 八阶段开发流程（S5 评审 / handoff 记录）的配套产物，
#           使用者项目没有这套流程，给了就是死代码。
SELF_ONLY="templates/docs/internal/handoff-index.md
templates/docs/internal/reviews/REVIEW-CODE-template.md
templates/docs/design/REVIEW-DESIGN.md"

# 收集 templates/ 下所有文件
while IFS= read -r f; do
  [ -f "$f" ] || continue
  # 跳过 settings.json（它由 node 脚本合并，不是直接 cp）
  case "$f" in *settings.json) continue ;; esac

  # 白名单：Aegis 自己用，不装给使用者
  if printf '%s\n' "$SELF_ONLY" | grep -qxF "$f"; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  TOTAL=$((TOTAL + 1))

  base=$(basename "$f")
  # 判断 install-v3.sh 有没有引用这个文件（按文件名或目录名匹配）
  if grep -qF "$base" "$INSTALL" 2>/dev/null; then
    continue
  fi
  # 目录整体 cp 的情况（如 cp templates/docs/adr → .aegis/templates/）
  dir=$(basename "$(dirname "$f")")
  if grep -qE "templates/docs/$dir|templates/v3/$dir" "$INSTALL" 2>/dev/null; then
    continue
  fi
  # hooks 目录整体 cp
  case "$f" in
    templates/v3/reasonix/hooks/*)
      grep -qF 'templates/v3/reasonix/hooks/' "$INSTALL" && continue ;;
  esac
  # skills 目录整体 cp
  case "$f" in
    */.agents/skills/*|*/skills/*)
      grep -qF 'skills' "$INSTALL" && continue ;;
  esac

  echo "  ✗ $f"
  echo "      这个模板不会被 install-v3.sh 装到使用者项目 —— 使用者永远拿不到"
  MISS=$((MISS + 1))
done < <(find templates -type f 2>/dev/null | sort)

echo ""
if [ "$MISS" -eq 0 ]; then
  echo "  ✓ templates/ 下 $TOTAL 个文件全部会被安装"
  [ "$SKIPPED" -gt 0 ] && echo "  （另有 $SKIPPED 个白名单项：Aegis 自己流程专用，不装给使用者）"
  echo "==============================================="
  exit 0
else
  echo "  $MISS / $TOTAL 个模板不会被安装"
  echo "==============================================="
  echo "修法：在 $INSTALL 里加上对应的 cp，或者删掉这个模板。"
  echo "判断依据（AGENTS.md 铁律）：使用者装完 Aegis 后会在自己项目里看到这个吗？"
  echo "  会 → 装过去；不会 → 那它不该在 templates/ 里。"
  exit 1
fi
