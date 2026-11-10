#!/usr/bin/env bash
# Aegis 多平台同步 —— 一份源，生成各 harness 形态
#
# 解决什么问题：
#   换一个 harness 就要重配一遍 skill / rules / hooks，还要把设计习惯搬过去。
#   这个脚本让你「定义一次」，然后按目标平台生成对应文件，并告诉你每个平台缺什么。
#
# 用法:
#   bash scripts/sync-harness.sh <项目目录>                   # 只同步探测到的平台
#   bash scripts/sync-harness.sh <项目目录> --all              # 全部平台
#   bash scripts/sync-harness.sh <项目目录> --targets=claude,reasonix
#
# 支持的平台:
#   claude    Claude Code     .claude/skills/ + .claude/settings.json + CLAUDE.md
#   reasonix  Reasonix        .agents/skills/ + .reasonix/ + AGENTS.md
#   cursor    Cursor          .cursor/rules/*.mdc（无 hook，只有 rules）
#   codex     Codex           AGENTS.md
#
# 设计原则：
#   一份源（templates/v3/）→ 各平台形态。
#   不引入新配置格式，不复制大段内容（能软链就软链）。

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

TARGET="${1:-}"
[ -z "$TARGET" ] && { echo "用法: bash scripts/sync-harness.sh <项目目录> [--all|--targets=a,b]"; exit 2; }
shift
[ -d "$TARGET" ] || { echo "目录不存在: $TARGET"; exit 2; }
TARGET="$(cd "$TARGET" && pwd)"

MODE="auto"
for arg in "$@"; do
  case "$arg" in
    --all) MODE="all" ;;
    --targets=*) MODE="${arg#--targets=}" ;;
  esac
done

# ────────────────────────────────────────────
# 平台能力表（这是"差异报告"的数据源）
# ────────────────────────────────────────────
# 格式: 平台名|配置目录|hook 支持|skill 位置|rules 文件|备注
# hook: full=可阻断 / partial=只能提醒 / none=没有
platform_info() {
  case "$1" in
    claude)   echo ".claude|full|.claude/skills|CLAUDE.md|hook 最全（PreToolUse/PostToolUse/SessionStart/Stop/PreCompact）" ;;
    reasonix) echo ".reasonix|full|.agents/skills|AGENTS.md|已验证 exit 2 可阻断" ;;
    cursor)   echo ".cursor|none|.cursor/rules|.cursor/rules/aegis.mdc|只有 rules，无 hook——拦截层会失效" ;;
    codex)    echo "|none||AGENTS.md|只有 rules 文件，无 hook/skill 机制" ;;
    *)        echo "|none|||未知平台" ;;
  esac
}

detect_platforms() {
  local found=""
  [ -d "$TARGET/.claude" ] || [ -d "$HOME/.claude" ] && found="$found claude"
  [ -d "$TARGET/.reasonix" ] || [ -d "$HOME/.reasonix" ] && found="$found reasonix"
  [ -d "$TARGET/.cursor" ] || [ -d "$HOME/.cursor" ] && found="$found cursor"
  [ -f "$TARGET/AGENTS.md" ] || [ -f "$HOME/.codex/AGENTS.md" ] && found="$found codex"
  echo "$found"
}

if [ "$MODE" = "auto" ]; then
  PLATFORMS="$(detect_platforms)"
  [ -z "$PLATFORMS" ] && PLATFORMS="claude reasonix"
elif [ "$MODE" = "all" ]; then
  PLATFORMS="claude reasonix cursor codex"
else
  PLATFORMS="$(echo "$MODE" | tr ',' ' ')"
fi

echo "==============================================="
echo " Aegis 多平台同步 → $TARGET"
echo " 目标平台: $PLATFORMS"
echo "==============================================="

SRC_SKILL="$ROOT/.agents/skills/aegis-think"
SRC_RULES="$ROOT/templates/v3/AGENTS.md"

# 脚本会在两种地方被调用，源不一样：
#   ① Aegis 仓库里（首次安装）：源 = templates/v3/ + .agents/skills/
#   ② 已装好的项目里（换 harness 补配）：源 = 项目自己的 AGENTS.md + .agents/skills/
# 判断依据：本仓库有没有 templates/v3/AGENTS.md
if [ ! -f "$SRC_RULES" ]; then
  SRC_RULES="$TARGET/AGENTS.md"
  SRC_SKILL="$TARGET/.agents/skills/aegis-think"
  MODE_NOTE="（在项目内运行，用项目自己的文件作源）"
else
  MODE_NOTE="（在 Aegis 仓库内运行，用 templates/ 作源）"
fi

[ -d "$SRC_SKILL" ] || { echo "✗ 找不到源 skill: $SRC_SKILL（先在项目里跑一次 install-v3.sh）"; exit 1; }
[ -f "$SRC_RULES" ] || { echo "✗ 找不到源 rules: $SRC_RULES"; exit 1; }
echo "  源: skill=$SRC_SKILL"
echo "      rules=$SRC_RULES"
echo "      $MODE_NOTE"

# ────────────────────────────────────────────
# 链接或复制（能用软链就用，省空间也避免两份内容漂移）
# ────────────────────────────────────────────
# 注意：Git Bash 的 `ln -s` 在 Windows 上**会静默退化成复制**，
#       命令本身返回 0，但产物不是链接。必须用 `[ -L ]` 复核，
#       否则会报出"软链"这个假结果（实测踩过）。
link_or_copy() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  rm -rf "$dst" 2>/dev/null
  ln -s "$src" "$dst" 2>/dev/null
  if [ -L "$dst" ]; then
    echo "      软链（改源即生效，不占额外空间）"
  else
    rm -rf "$dst" 2>/dev/null
    cp -r "$src" "$dst"
    echo "      复制（本机不支持软链，两份内容需靠 sync-harness.sh 保持同步）"
  fi
}

# 把 AGENTS.md 转成 Cursor 的 .mdc 格式（前面加 frontmatter）
gen_cursor_rule() {
  local dst="$1"
  mkdir -p "$(dirname "$dst")"
  {
    echo "---"
    echo "description: Aegis 约束层（记录、四维度自检、关键动作拦截）"
    echo "globs:"
    echo "alwaysApply: true"
    echo "---"
    echo ""
    echo "<!-- 由 Aegis sync-harness.sh 从 templates/v3/AGENTS.md 生成，别手改 -->"
    echo ""
    cat "$SRC_RULES"
  } > "$dst"
}

# ────────────────────────────────────────────
# 逐平台生成
# ────────────────────────────────────────────
for p in $PLATFORMS; do
  IFS='|' read -r conf_dir hook_level skill_dir rules_file note <<< "$(platform_info "$p")"

  echo ""
  echo "── $p ──"

  case "$p" in
    claude)
      echo "  skill  : .claude/skills/aegis-think"
      link_or_copy "$SRC_SKILL" "$TARGET/.claude/skills/aegis-think"
      echo "  rules  : CLAUDE.md（标记追加）"
      if [ -f "$ROOT/scripts/install-v3.sh" ]; then
        echo "      （由 install-v3.sh 的 install_block 处理，这里跳过避免重复）"
      fi
      # hooks
      if [ -d "$TARGET/.claude" ] || [ "$MODE" = "all" ]; then
        mkdir -p "$TARGET/.claude"
        if [ -f "$TARGET/.claude/settings.json" ]; then
          echo "  hooks  : .claude/settings.json 已存在 → 不覆盖，需手动合并"
          echo "      参考模板: templates/v3/reasonix/settings.json（格式相近）"
        else
          echo "  hooks  : 需要用 Claude Code 的 settings.json 格式，见下方差异报告"
        fi
      fi
      ;;

    reasonix)
      echo "  skill  : .agents/skills/aegis-think"
      link_or_copy "$SRC_SKILL" "$TARGET/.agents/skills/aegis-think"
      echo "  hooks  : .reasonix/hooks/（4 个脚本）"
      mkdir -p "$TARGET/.reasonix/hooks"
      if [ -d "$ROOT/templates/v3/reasonix/hooks" ]; then
        cp "$ROOT/templates/v3/reasonix/hooks/"*.sh "$TARGET/.reasonix/hooks/" 2>/dev/null || true
        chmod +x "$TARGET/.reasonix/hooks/"*.sh 2>/dev/null || true
      fi
      echo "  rules  : AGENTS.md（标记追加）"
      ;;

    cursor)
      echo "  rules  : .cursor/rules/aegis.mdc（从 AGENTS.md 转换）"
      gen_cursor_rule "$TARGET/.cursor/rules/aegis.mdc"
      echo "  skill  : ✗ Cursor 没有 skill 机制 → 16 个模型用不了"
      echo "  hooks  : ✗ Cursor 没有 hook → 拦截层完全失效"
      ;;

    codex)
      echo "  rules  : AGENTS.md（Codex 直接读）"
      echo "  skill  : ✗ Codex 没有 skill 机制 → 16 个模型用不了"
      echo "  hooks  : ✗ Codex 无 hook（沙箱级隔离，不是 hook 级）"
      ;;

    *)
      echo "  ✗ 未知平台: $p"
      ;;
  esac
done

# ────────────────────────────────────────────
# 能力差异报告 —— 这是解决"不可控"的关键
# ────────────────────────────────────────────
echo ""
echo "==============================================="
echo " 能力差异报告（同一份 Aegis，在不同平台发挥不同）"
echo "==============================================="
echo ""
printf "  %-10s %-12s %-14s %-10s\n" "平台" "拦截能力" "思维模型(16)" "文档骨架"
printf "  %-10s %-12s %-14s %-10s\n" "──────" "────────" "────────────" "────────"
for p in $PLATFORMS; do
  case "$p" in
    claude|reasonix) printf "  %-10s %-12s %-14s %-10s\n" "$p" "✓ 可阻断" "✓ 可用" "✓ 可用" ;;
    cursor)          printf "  %-10s %-12s %-14s %-10s\n" "$p" "✗ 无" "✗ 无" "✓ 可用" ;;
    codex)           printf "  %-10s %-12s %-14s %-10s\n" "$p" "✗ 无" "✗ 无" "✓ 可用" ;;
    *)               printf "  %-10s %-12s %-14s %-10s\n" "$p" "?" "?" "?" ;;
  esac
done
echo ""
echo "  说明："
echo "    拦截能力 = 「缺 NOTES 拦写文件」「main 上拦提交」能不能真拦住"
echo "    思维模型 = aegis-think 的 16 个模型能不能被触发"
echo "    文档骨架 = 概念表 / 索引 / ADR / 故障记录模板（纯文件，任何平台都能用）"
echo ""
echo "  结论：Aegis 的牙在 hook 上。没有 hook 的平台，它退化成一份提醒清单。"
echo "==============================================="
