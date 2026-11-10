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

# ---------- 4b. 文档骨架（维度二：工程方法的载体）----------
# 为什么要有：Aegis 的「语义」维度要求「术语归到已有概念了吗」，
# 但如果项目里连概念表都没有，这条检查就是空转。
# 判断依据：概念表和索引是「必须齐备」的（成本极低，缺了就没地方落笔）；
#          ADR / 故障记录是「有需要用」的，只给模板，不占目录。
mkdir -p "$TARGET/docs/reference"
if [ ! -f "$TARGET/docs/reference/concepts.md" ]; then
  cp "$ROOT/templates/v3/concepts.md" "$TARGET/docs/reference/concepts.md"
  echo "  → docs/reference/concepts.md（术语表，空表带收录判据）"
else
  echo "  → docs/reference/concepts.md 已存在，保留"
fi
if [ ! -f "$TARGET/docs/README.md" ]; then
  cp "$ROOT/templates/v3/docs-README.md" "$TARGET/docs/README.md"
  echo "  → docs/README.md（文档索引 + 目录约定）"
else
  echo "  → docs/README.md 已存在，保留"
fi
# ADR / 故障记录 / 发布说明 / 设计文档：模板放 .aegis/templates/，需要时自行 copy
mkdir -p "$TARGET/.aegis/templates"
cp -r "$ROOT/templates/docs/adr" "$ROOT/templates/docs/incidents" "$ROOT/templates/docs/release" "$TARGET/.aegis/templates/" 2>/dev/null || true
# 设计文档模板（DESIGN / STYLE）：通用价值，任何要写设计的项目都用得上
# 注意不含 REVIEW-DESIGN.md —— 那是 Aegis 八阶段流程 S5 的配套产物，使用者没有这套流程
mkdir -p "$TARGET/.aegis/templates/design"
cp "$ROOT/templates/docs/design/DESIGN.md" "$ROOT/templates/docs/design/STYLE.md" "$TARGET/.aegis/templates/design/" 2>/dev/null || true
echo "  → .aegis/templates/（ADR / 故障记录 / 发布说明 / 设计文档模板，需要时 copy 到 docs/）"
echo ""

# ---------- 5. 挂载 Reasonix hooks（只在用 Reasonix 时）----------
echo "[5/6] 挂载约束（Reasonix hooks）"
if [ "$CAP_HOOK" = "yes" ]; then
  mkdir -p "$TARGET/.reasonix/hooks"
  cp "$ROOT/templates/v3/reasonix/hooks/"*.sh "$TARGET/.reasonix/hooks/"
  chmod +x "$TARGET/.reasonix/hooks/"*.sh 2>/dev/null || true
  echo "  → .reasonix/hooks/（4 个脚本）"

  if command -v node >/dev/null 2>&1; then
    node -e '
      const fs=require("fs");
      const [tgt, src] = process.argv.slice(1);
      const add = JSON.parse(fs.readFileSync(src,"utf8"));
      let cur = {};
      if (fs.existsSync(tgt)) { try { cur = JSON.parse(fs.readFileSync(tgt,"utf8")); } catch(e){ cur={}; } }
      cur.hooks = cur.hooks || {};
      let added = 0, updated = 0;
      for (const [ev, arr] of Object.entries(add.hooks || {})) {
        cur.hooks[ev] = cur.hooks[ev] || [];
        for (const h of arr) {
          // 同 command = 同一条 hook：用新版覆盖旧版（否则重装不会修复 match/description 的改动）
          const i = cur.hooks[ev].findIndex(x => x.command === h.command);
          if (i >= 0) { cur.hooks[ev][i] = h; updated++; }
          else { cur.hooks[ev].push(h); added++; }
        }
      }
      fs.writeFileSync(tgt, JSON.stringify(cur, null, 2) + "\n");
      console.log("  → .reasonix/settings.json（合并：新增 " + added + " 条，更新 " + updated + " 条）");
    ' "$TARGET/.reasonix/settings.json" "$ROOT/templates/v3/reasonix/settings.json"
  else
    if [ -f "$TARGET/.reasonix/settings.json" ]; then
      cp "$TARGET/.reasonix/settings.json" "$TARGET/.reasonix/settings.json.bak"
      echo "  ! 已有 settings.json 且没装 node，无法安全合并"
      echo "    已备份为 settings.json.bak；请手动把 $ROOT/templates/v3/reasonix/settings.json 里的 hooks 并进去"
    else
      cp "$ROOT/templates/v3/reasonix/settings.json" "$TARGET/.reasonix/settings.json"
      echo "  → .reasonix/settings.json（新建）"
    fi
  fi
  echo "  ! 保存后需重启 Reasonix 才生效；项目级 hooks 新版本可能需要 /hooks trust"
else
  echo "  跳过（未探测到 Reasonix/Claude 配置目录）"
fi
echo ""

# ---------- 6. 生成分工约定 ----------
echo "[6/6] 生成分工约定（探测已有 skills，说明谁管什么）"
# 把生成器也装进目标项目，否则 AEGIS-分工.md 里写的"重新生成"命令会指向不存在的脚本
mkdir -p "$TARGET/.aegis"
cp "$ROOT/scripts/gen-division.sh" "$TARGET/.aegis/gen-division.sh"
chmod +x "$TARGET/.aegis/gen-division.sh" 2>/dev/null || true
echo "  → .aegis/gen-division.sh（装了技能后可自行重新生成分工表）"
# 四维度自检脚本 —— 让「逐条核对」不靠自觉
cp "$ROOT/scripts/check.sh" "$TARGET/.aegis/check.sh"
chmod +x "$TARGET/.aegis/check.sh" 2>/dev/null || true
echo "  → .aegis/check.sh（随时自检：bash .aegis/check.sh all .）"
bash "$ROOT/scripts/gen-division.sh" "$TARGET" 2>&1 | sed 's/^/  /'
echo ""

echo "=== 完成 ==="
echo ""
echo "下一步："
echo "  1. 在 $TARGET 里打开你的 agent（Reasonix / Claude Code / Trae）"
echo "  2. 说一句需求（比如「做个贪吃蛇，浏览器能玩就行」）"
echo "  3. 观察它是否先问再动手"
echo "  4. 观察写文件时是否被 AEGIS BLOCKED 拦下（没有 NOTES.md 时会拦）"
echo "  5. 记录本次 token 消耗，与本项目文档里记录的基线对比"
