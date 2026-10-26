#!/usr/bin/env bash
# Aegis 派生物同步：.ai/ (唯一真相源) → .skills/ 与 adapters/
# 用法: bash scripts/sync.sh [--check]
#   --check  只比对是否需要同步，不写入（适合 pre-commit 钩子）

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MODE="${1:-write}"
CHANGED=0
say() { printf "  %s\n" "$1"; }

# ---------- 1. .skills/ 存在性 ----------
echo "[1/4] 校验 .skills/ 完整性"

EXPECTED_SKILLS=(
  "aegis-state"
  "aegis-align"
  "aegis-p1-ideate"
  "aegis-p2-design"
  "aegis-p3-validate"
  "aegis-p4-implement"
  "aegis-p5-verify"
  "aegis-p6-archive"
  "aegis-p7-deliver"
)
for s in "${EXPECTED_SKILLS[@]}"; do
  if [ -f ".skills/$s/SKILL.md" ]; then say "✓ .skills/$s"; else say "✗ 缺 .skills/$s/SKILL.md"; CHANGED=1; fi
done

# 反向检查：.skills/ 下有未被登记的 skill（防止写了却没纳入校验）
for d in .skills/*/; do
  [ -d "$d" ] || continue
  nm=$(basename "$d")
  if ! printf '%s\n' "${EXPECTED_SKILLS[@]}" | grep -qx "$nm"; then
    say "! 未登记的 skill: $nm（请加入 sync.sh 的 EXPECTED_SKILLS）"
  fi
done

# ---------- 2. frontmatter 规范 ----------
echo "[2/4] 校验 SKILL.md frontmatter"

for f in .skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  dir=$(basename "$(dirname "$f")")
  name=$(awk '/^name:/{print $2; exit}' "$f")
  desc_chars=$(awk '/^description:/{sub(/^description: */,""); print length($0); exit}' "$f")
  fm_len=$(awk 'BEGIN{n=0;c=0} /^---$/{c++; if(c==2) exit; next} c==1{n+=length($0)+1} END{print n}' "$f")

  if [[ ! "${name:-}" =~ ^[a-z0-9-]+$ ]]; then
    say "✗ $dir: name 只能用小写字母/数字/连字符（当前: ${name:-空}）"; CHANGED=1
  else
    say "✓ $dir  (name=$name, desc=${desc_chars:-0}字符, frontmatter=${fm_len}字符)"
  fi

  [ "${desc_chars:-0}" -gt 500 ] && say "  ! description 超 500 字符，建议精简"
  [ "${fm_len:-0}" -gt 1024 ] && say "  ! frontmatter 超 1024 字符（硬限制）"
  grep -q '^description: Use when' "$f" || say "  ! description 建议以 'Use when' 开头"
done

# ---------- 3. harness 适配壳 ----------
echo "[3/4] 生成 adapters/ 适配壳"

write_if_changed() {
  local target="$1"; local tmp
  tmp="$(mktemp)"
  cat > "$tmp"
  if [ -f "$target" ] && cmp -s "$tmp" "$target"; then
    say "✓ $target"
    rm -f "$tmp"
  else
    if [ "$MODE" = "--check" ]; then
      say "✗ 需更新 $target"; CHANGED=1; rm -f "$tmp"
    else
      mkdir -p "$(dirname "$target")"
      mv "$tmp" "$target"
      say "→ $target"
    fi
  fi
}

write_if_changed adapters/cursor/rules.mdc <<'EOS'
---
description: Aegis project constitution
globs: ["**/*"]
alwaysApply: true
---
# Aegis

本项目使用 Aegis 流程系统（状态机 + 制品 + 门禁）。

会话开始必须：
1. 读 AGENTS.md
2. 读 STATE.md（当前阶段）
3. 读 .ai/00-core.md（六条铁律 + 分支铁律）与 .ai/90-preferences.md
4. 按当前阶段读 .ai/0X-Pn-*.md

禁止跳过阶段。
每个新任务必须建独立分支（<类型>/<短名>），禁止直接改主分支。
新要求必须先走 P0.5 两轮讨论（每轮先给问题清单，用日常语言），禁止直接给方案。
前端项目未出 HTML demo 并获得用户确认前，禁止写业务代码。
门禁检查：bash scripts/gate.sh
EOS

write_if_changed adapters/trae/rules.md <<'EOS'
# Aegis 项目规范

本仓库使用 Aegis 流程系统（状态机 + 制品 + 门禁）。

## 会话开始顺序
1. 读 `AGENTS.md`
2. 读 `STATE.md`（当前在哪个阶段）
3. 读 `.ai/00-core.md`（六条铁律 + 分支铁律）与 `.ai/90-preferences.md`
4. 按当前阶段读 `.ai/0X-Pn-*.md`

## 硬规则
- 禁止跳过阶段；未过出口门禁不得前进
- 每个新任务必须建独立分支，禁止直接改主分支
- 新要求必须先走 P0.5 两轮讨论（每轮先给问题清单，用日常语言），禁止直接给方案
- 前端项目未出 HTML demo 并获得用户确认前，禁止写业务代码
- 说"完成"必须贴验证输出

## 门禁
```bash
bash scripts/gate.sh
```
EOS

write_if_changed adapters/codex/AGENTS.md <<'EOS'
# AGENTS.md（Codex 适配壳）

本项目约定文件位于仓库根目录 `AGENTS.md`。

请先阅读：
- `AGENTS.md` — 入口与六条铁律 + 分支铁律
- `STATE.md` — 当前阶段与下一步

再按 `STATE.md` 中的当前阶段，加载 `.ai/0X-Pn-*.md`。

门禁：`bash scripts/gate.sh`
EOS



# ---------- 4. 真生成：.ai/ 真相源 → .skills/*/SKILL.md 同步块 ----------
echo "[4/4] 生成 .skills/ 同步块（铁律 + 概念表目录 + 分工原则）"

# 从真相源提取的三段内容，拼成同步块；--check 模式只比对不写入
extract() { # $1=文件 $2=起始标记 $3=结束标记
  awk -v s="$2" -v e="$3" 'index($0,s){f=1} f&&e&&index($0,e)&&!index($0,s){exit} f{print}' "$1"
}

CORE_SNIP="$(extract .ai/00-core.md '## 3. 六条铁律' '## 4.')"
CONCEPT_SNIP="$(extract docs/develop/CONCEPTS.md '## 目录（一句话列' '\037')"   # 到文件尾
PREF_SNIP="$(extract .ai/90-preferences.md '## 分工原则' '### 技术词使用规则')"

BUILD_BLOCK() {
  cat <<'EOS'
<!-- BEGIN GENERATED BLOCK（由 scripts/sync.sh 从 .ai/ 与 docs/develop/CONCEPTS.md 生成，勿手改；改真相源后运行 make sync）-->

## 同步块（真相源摘录，会话必读）

EOS
  printf '%s\n\n' "$CORE_SNIP"
  printf '%s\n\n' "$PREF_SNIP"
  printf '%s\n' "$CONCEPT_SNIP"
  cat <<'EOS'
<!-- END GENERATED BLOCK -->
EOS
}

GEN_LINE_RE='BEGIN GENERATED BLOCK'
for f in .skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  # 删除旧的生成块
  tmp_new="$(mktemp)"
  awk -v b="$GEN_LINE_RE" '
    $0 ~ /<!-- BEGIN GENERATED BLOCK/ {skip=1; next}
    $0 ~ /<!-- END GENERATED BLOCK/   {skip=0; next}
    !skip
  ' "$f" > "$tmp_new"
  BUILD_BLOCK > "$(mktemp)" # noop 保序
  { cat "$tmp_new"; BUILD_BLOCK; } > "$f.new"
  rm -f "$tmp_new"
  # 压缩多余空行（删块后留下的三连空行）
  if cmp -s "$f" "$f.new"; then
    say "✓ $f 同步块已最新"; rm -f "$f.new"
  else
    if [ "$MODE" = "--check" ]; then
      say "✗ $f 同步块需更新"; CHANGED=1; rm -f "$f.new"
    else
      mv "$f.new" "$f"; say "→ $f 同步块已重生成"
    fi
  fi
done

# ---------- 5. 软链 ----------
for link in CLAUDE.md GEMINI.md; do
  if [ -L "$link" ]; then
    say "✓ $link -> $(readlink "$link")"
  elif [ -e "$link" ]; then
    # 实体文件：若内容与 AGENTS.md 相同（未保留软链的打包/解包会把软链摊成副本），自动转回软链
    if [ "$MODE" = "--check" ]; then
      if cmp -s "$link" AGENTS.md; then
        say "! $link 是实体副本（zip 解包所致），运行 make sync 会转为软链"; CHANGED=1
      else
        say "! $link 是实体文件且内容与 AGENTS.md 不同，未覆盖（请人工确认）"
      fi
    else
      if cmp -s "$link" AGENTS.md; then
        rm -f "$link" && ln -s AGENTS.md "$link" && say "→ $link 实体副本已转为软链"
      else
        say "! $link 内容是自定义的，保留为实体文件（建议改为软链）"
      fi
    fi
  else
    if [ "$MODE" = "--check" ]; then say "✗ $link 未建立软链"; CHANGED=1
    else ln -sf AGENTS.md "$link"; say "→ $link -> AGENTS.md"; fi
  fi
done

echo ""
if [ "$MODE" = "--check" ]; then
  if [ "$CHANGED" -eq 0 ]; then echo "同步状态：一致"; exit 0; else echo "同步状态：需更新，请运行 make sync"; exit 1; fi
else
  echo "同步完成。"
fi
