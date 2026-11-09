#!/usr/bin/env bash
# Aegis v3 最小闭环安装器
# 用法: bash scripts/install-v3.sh <目标项目目录>
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
TARGET="${1:-}"

if [ -z "$TARGET" ]; then
  echo "用法: bash scripts/install-v3.sh <目标项目目录>"
  echo "例:   bash scripts/install-v3.sh ~/projects/my-snake"
  exit 1
fi

if [ ! -d "$TARGET" ]; then
  echo "✗ 目标目录不存在: $TARGET"
  echo "  要不要先建一个空目录？ mkdir -p $TARGET"
  exit 1
fi

echo "=== 安装 Aegis v3 最小闭环 → $TARGET ==="
echo ""

# ---------- 1. 探测宿主能力 ----------
echo "[1/4] 探测宿主能力"
CAP_HOOK="no"; CAP_SUBAGENT="no"; CAP_MEMORY="no"
[ -d "$TARGET/.claude" ] || [ -d "$HOME/.claude" ] && { CAP_HOOK="yes"; CAP_SUBAGENT="yes"; CAP_MEMORY="yes"; }
[ -f "$HOME/.reasonix/reasonix.toml" ] || [ -d "$HOME/.reasonix" ] && { CAP_HOOK="yes"; CAP_SUBAGENT="yes"; CAP_MEMORY="yes"; }
[ -d "$TARGET/.trae" ] || [ -d "$HOME/.trae-cn" ] && { CAP_HOOK="yes"; CAP_SUBAGENT="yes"; }
echo "  hook 自动拦截 : $CAP_HOOK"
echo "  子智能体      : $CAP_SUBAGENT"
echo "  结构化记忆    : $CAP_MEMORY"
echo "  （no 不影响使用，只是对应能力会降级）"
echo ""

# ---------- 2. 装技能 ----------
echo "[2/4] 安装技能到 .agents/skills/（Reasonix 与 Trae 都认这个位置）"
mkdir -p "$TARGET/.agents/skills"
cp -r "$ROOT/.agents/skills/aegis-think" "$TARGET/.agents/skills/"
n=$(find "$TARGET/.agents/skills/aegis-think" -name '*.md' | wc -l | tr -d ' ')
echo "  → 已安装 aegis-think（$n 个文件）"

# Claude Code 需要额外一份
if [ -d "$TARGET/.claude" ] || [ "$CAP_HOOK" = "yes" ]; then
  mkdir -p "$TARGET/.claude/skills"
  if [ ! -e "$TARGET/.claude/skills/aegis-think" ]; then
    cp -r "$ROOT/.agents/skills/aegis-think" "$TARGET/.claude/skills/"
    echo "  → 已为 Claude Code 复制一份到 .claude/skills/"
  fi
fi
echo ""

# ---------- 3. 装入口（标记追加，绝不覆盖已有内容）----------
echo "[3/4] 安装入口文件"

BEGIN_MARK='<!-- BEGIN AEGIS -->'
END_MARK='<!-- END AEGIS -->'

# 把 Aegis 的内容写进目标文件：
#   文件不存在      → 新建（含标记）
#   已有 AEGIS 段   → 只替换段内内容，段外一字不动
#   无 AEGIS 段     → 追加到末尾，原文完整保留
install_block() {
  local target="$1" src="$2"

  if [ ! -f "$target" ]; then
    { printf '%s\n' "$BEGIN_MARK"; cat "$src"; printf '%s\n' "$END_MARK"; } > "$target"
    echo "  → $target（新建）"
    return
  fi

  if grep -qF "$BEGIN_MARK" "$target"; then
    awk -v b="$BEGIN_MARK" -v e="$END_MARK" -v srcfile="$src" '
      $0 == b { print; while ((getline line < srcfile) > 0) print line; close(srcfile); skip=1; next }
      $0 == e { skip=0 }
      !skip   { print }
    ' "$target" > "$target.aegis.tmp" && mv "$target.aegis.tmp" "$target"
    echo "  → $target（替换 AEGIS 段，段外未动）"
  else
    { printf '\n%s\n' "$BEGIN_MARK"; cat "$src"; printf '%s\n' "$END_MARK"; } >> "$target"
    echo "  → $target（追加 AEGIS 段，原文完整保留）"
  fi
}

install_block "$TARGET/AGENTS.md"      "$ROOT/templates/v3/AGENTS.md"
install_block "$TARGET/CLAUDE.md"      "$ROOT/templates/v3/AGENTS.md"
install_block "$TARGET/preferences.md" "$ROOT/templates/v3/preferences.md"
echo ""

# ---------- 4. 初始化记录 ----------
echo "[4/5] 初始化记录文件"
if [ ! -f "$TARGET/NOTES.md" ]; then
  cat > "$TARGET/NOTES.md" <<'EOF'
# 决策记录

> 每条一次。上限 200 行，超了把已确认的移到 NOTES-ARCHIVE.md。
> 每条必须含：用了什么 / 判断是什么 / 排除了什么 / 用户明确否定的 / 什么情况说明我错了

EOF
  echo "  → NOTES.md（新建）"
else
  echo "  → NOTES.md 已存在，保留"
fi

# 核心检查清单 + 生长记录 + 项目约束 + 外接规则
# 后四个是使用者要长期维护的，已存在则保留，不许覆盖
for f in CORE-CHECKLIST.md CHECKLIST-GROWTH.md constraints.md EXTERNAL.md; do
  if [ ! -f "$TARGET/$f" ]; then
    cp "$ROOT/templates/v3/$f" "$TARGET/$f"
    echo "  → $f（新建）"
  else
    echo "  → $f 已存在，保留（它可能已被你改过）"
  fi
done
echo ""

# ---------- 5. 生成分工约定 ----------
echo "[5/5] 生成分工约定（探测已有 skills，说明谁管什么）"
bash "$ROOT/scripts/gen-division.sh" "$TARGET" 2>&1 | sed 's/^/  /'
echo ""

echo "=== 完成 ==="
echo ""
echo "下一步："
echo "  1. 在 $TARGET 里打开你的 agent（Reasonix / Claude Code / Trae）"
echo "  2. 说一句需求（比如「做个贪吃蛇，浏览器能玩就行」）"
echo "  3. 观察它是否先问再动手"
echo "  4. 记录 token 消耗（见 docs/develop/reasonix/TEST-snake-baseline.md）"
