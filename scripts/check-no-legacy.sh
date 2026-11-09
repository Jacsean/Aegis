#!/usr/bin/env bash
# 九阶段「使用中完全不可见」验收（v2.0.0 失败定义的可执行判据）
# 用法: bash scripts/check-no-legacy.sh [目录，默认当前目录]
#   退出码 0 = 使用者维度 0 命中（合格）；1 = 有残留（不合格）
#
# 判据来源：docs/prd.md「失败定义」
#   「交付包内任意 agent 按启动协议走任何场景，能碰到旧版流程设计 = 失败」
#   「旧版设计只能作为回溯可读，使用过程中完全不可见」
#
# 豁免（不算残留）：
#   - CHANGELOG.md 的历史条目（只增不改，是发布历史）
#   - docs/ 内的发布说明/PRD 中对"切换动作"的一次性陈述（不引导使用者进入旧流程）
#   - 本脚本自身

set -uo pipefail
ROOT="${1:-.}"
cd "$ROOT" || { echo "✗ 目录不存在: $ROOT"; exit 1; }
SELF="scripts/check-no-legacy.sh"

# 使用者维度
SCAN_DIRS=(docs .ai .skills adapters scripts templates examples)
EXTRA_FILES=(AGENTS.md README.md STATE.md Makefile)

# 旧编号体系 / 旧文件名 / 旧流转图
PAT='P0\.5|\bP05\b|0[1-8]-P[0-9]|阶段流转图（九阶段'
# docs/ 内允许的「切换动作陈述」文件（发布说明与 PRD 必须能说清"从什么切到什么"）
DOCS_EXEMPT='CHANGELOG\.md|docs/reference/concepts\.md|docs/release/|docs/rfc/'

hits=0
scan=()
for d in "${SCAN_DIRS[@]}"; do [ -d "$d" ] && scan+=("$d"); done
for f in "${EXTRA_FILES[@]}"; do [ -f "$f" ] && scan+=("$f"); done

# 1. docs/internal/ 不得在交付包内
[ -d docs/internal ] && echo "  ! 检测到 docs/internal/（设计者维度）——若是交付包，说明剔除失败"

# 2. 旧编号/旧文件名扫描
while IFS= read -r line; do
  [ -z "$line" ] && continue
  f="${line%%:*}"
  [ "$f" = "$SELF" ] && continue
  # CHANGELOG 历史条目永久豁免
  case "$f" in CHANGELOG.md) continue ;; esac
  # docs/ 下说明性文件豁免（但不豁免 .ai 阶段规范与 skills）
  case "$f" in docs/*) echo "$f" | grep -qE "$DOCS_EXEMPT" && continue ;; esac
  echo "  ✗ $line"
  hits=$((hits+1))
done < <(grep -rnE "$PAT" "${scan[@]}" 2>/dev/null)

# 2b. 内部设计过程痕迹不得出现在使用者维度（H 编号是对设计者档案的引用，包内是死链；
#     框架自身的对齐签字/内部 PRD 属设计者维度）
while IFS= read -r line; do
  [ -z "$line" ] && continue
  echo "  ✗ $line"
  hits=$((hits+1))
done < <(grep -rnE '^> 状态：.*H-0[0-9]{3}' .ai/ templates/ adapters/ 2>/dev/null)
[ -f docs/internal/path-map.md ] && { echo "  ✗ docs/internal/path-map.md 在使用者维度（应移设计者维度）"; hits=$((hits+1)); }
while IFS= read -r f; do
  echo "  ✗ $f 含框架内部对齐签字（应移设计者维度）"; hits=$((hits+1))
done < <(grep -rln '签字（用户原话）' docs/ 2>/dev/null)

# 3. 对外用法不得引导旧编号
grep -qE 'gate\.sh \[P0' scripts/gate.sh 2>/dev/null && { echo "  ✗ gate.sh 用法仍引导旧编号"; hits=$((hits+1)); }
grep -qE 'state\.sh phase P0' scripts/state.sh 2>/dev/null && { echo "  ✗ state.sh 用法仍引导旧编号"; hits=$((hits+1)); }

# 4. 阶段规范文件必须是 S 编号命名（00-core / 09 场景决断 / 90 / 99 除外）
for f in .ai/*.md; do
  b="$(basename "$f")"
  case "$b" in
    00-*|09-*|90-*|99-*) continue ;;
  esac
  case "$b" in
    [0-9][0-9]-S[1-8]-*) ;;
    *) echo "  ✗ .ai 阶段文件命名非 S 体系: $f"; hits=$((hits+1)) ;;
  esac
done

echo ""
if [ "$hits" -eq 0 ]; then
  echo "PASS — 使用者维度 0 处旧流程残留（旧设计使用中不可见）"
  exit 0
fi
echo "FAIL — 发现 $hits 处旧流程残留（违反 v2.0.0 失败定义）"
exit 1
