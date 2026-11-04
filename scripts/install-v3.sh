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

# ---------- 3. 装入口 ----------
echo "[3/4] 安装入口文件"
if [ -f "$TARGET/AGENTS.md" ]; then
  cp "$TARGET/AGENTS.md" "$TARGET/AGENTS.md.bak.$(date +%Y%m%d%H%M%S)"
  echo "  ! 已有 AGENTS.md，已备份后覆盖"
fi
cp "$ROOT/templates/v3/AGENTS.md" "$TARGET/AGENTS.md"
echo "  → AGENTS.md"
# Claude Code 读 CLAUDE.md：用实体副本（Windows 上软链会失效）
cp "$ROOT/templates/v3/AGENTS.md" "$TARGET/CLAUDE.md"
echo "  → CLAUDE.md（实体副本）"
echo ""

# ---------- 4. 初始化记录 ----------
echo "[4/4] 初始化记录文件"
if [ ! -f "$TARGET/NOTES.md" ]; then
  cat > "$TARGET/NOTES.md" <<'EOF'
# 决策记录

> 每条一次。上限 200 行，超了把已确认的移到 NOTES-ARCHIVE.md。

EOF
  echo "  → NOTES.md（空）"
else
  echo "  → NOTES.md 已存在，保留"
fi
echo ""

echo "=== 完成 ==="
echo ""
echo "下一步："
echo "  1. 在 $TARGET 里打开你的 agent（Reasonix / Claude Code / Trae）"
echo "  2. 说一句需求（比如「做个贪吃蛇，浏览器能玩就行」）"
echo "  3. 观察它是否先问再动手"
echo "  4. 记录 token 消耗（见 docs/develop/reasonix/TEST-snake-baseline.md）"
