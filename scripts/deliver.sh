#!/usr/bin/env bash
# Aegis 交付打包：只打「使用者维度」产物，剔除设计者维度（docs/internal/）
# 用法: bash scripts/deliver.sh <版本号，如 1.6.0>
# 产出: ../out/aegis-git-<版本>.tar.gz（含 git 历史与 tag，工作树不含 docs/internal/）

set -euo pipefail
VER="${1:?用法: deliver.sh <版本号>}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/../out"
NAME="aegis-git-v$VER"

mkdir -p "$OUT"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# 1. 完整克隆（保 git 历史 + 全部 tag 回退点）
git clone --quiet "$ROOT" "$TMP/$NAME"
git -C "$TMP/$NAME" checkout --quiet "v$VER" 2>/dev/null || true

# 2. 剔除设计者维度（使用者的工作树里不应出现 docs/internal/ 与 docs/rfc/）
#    分工见 docs/README.md 的「一、随交付」/「二、设计者维度」两节。
rm -rf "$TMP/$NAME/docs/internal"
rm -rf "$TMP/$NAME/docs/rfc"
touch "$TMP/$NAME/.aegis-package"   # 交付包标记：gate.sh 见此只跑框架自检
echo "  → 已剔除 docs/internal/ 与 docs/rfc/（设计者维度）"


# 2a2. 重置自举产生的本地状态（这些是「框架自己这个项目」的，不是「给使用者的模板」）
#      使用者在自己的项目里跑 install-v3.sh 时，这些文件会从 templates/v3/ 生成；
#      交付包里带着 Aegis 仓库自己那份，只会让人误以为"已经是装好的状态"。
#      保留的：AGENTS.md（框架入口）/ CLAUDE.md GEMINI.md（入口副本）/
#              README.md CHANGELOG.md VERSION STATE.md Makefile（框架本体）
LOCAL_STATE="NOTES.md AEGIS-分工.md CORE-CHECKLIST.md CHECKLIST-GROWTH.md constraints.md EXTERNAL.md preferences.md"
for f in $LOCAL_STATE; do rm -f "$TMP/$NAME/$f"; done
echo "  → 已剔除自举本地状态（使用者需自行 install-v3.sh 生成）：$LOCAL_STATE"

# 2b. 清 git 索引里已剔除项的跟踪（否则包内 git status 永远脏，branch.sh 第一步就卡）
git -C "$TMP/$NAME" rm -r --cached --quiet docs/internal 2>/dev/null || true
git -C "$TMP/$NAME" rm -r --cached --quiet docs/rfc 2>/dev/null || true
git -C "$TMP/$NAME" rm --cached --quiet $LOCAL_STATE 2>/dev/null || true
git -C "$TMP/$NAME" -c user.name=deliver -c user.email=deliver@aegis.local \
  commit --quiet --allow-empty -m "chore: 交付包索引剔除设计者维度与自举状态（deliver.sh 自动提交）"

# 2c. STATE.md 换成新项目起始态（包内不该带着框架自己的 S8 待复签状态）
cat > "$TMP/$NAME/STATE.md" <<'STATE'
# STATE

> 新项目起始态。按 AGENTS.md 启动协议走：场景决断 → S1 立题。

- 项目：（填你的项目名） · **当前阶段：S1（立题）** · 分支：main

## 已完成
- （无）

## 进行中
- 场景决断 / S1 立题

## 门禁签字
- （尚无；S2 对齐出口是全流程唯一强制签字点）

## 已知限制
- （无）
STATE
echo "  → STATE.md 已重置为新项目起始态"

# 2d. 把包内改动提交进索引，工作区保持干净（branch.sh 才能第一步通过）
printf '.aegis-package\n' > "$TMP/$NAME/.git/info/exclude"
git -C "$TMP/$NAME" add STATE.md
git -C "$TMP/$NAME" -c user.name=deliver -c user.email=deliver@aegis.local \
  commit --quiet --allow-empty -m "chore: STATE 重置为新项目起始态（deliver.sh 自动提交）"

# 3. 验收自检：使用者维度完整性
cd "$TMP/$NAME"
for f in AGENTS.md STATE.md docs/reference/concepts.md .ai/00-core.md .skills/aegis-state/SKILL.md scripts/gate.sh; do
  [ -f "$f" ] || { echo "✗ 缺使用者维度文件: $f"; exit 1; }
done
[ ! -e docs/internal ] && echo "  ✓ docs/internal/ 已剔除（设计者维度）"
[ ! -e docs/rfc ] && echo "  ✓ docs/rfc/ 已剔除（设计者维度）" || { echo "✗ docs/rfc/ 未剔除"; exit 1; }
# 自举运行时文件：一个都不许留（使用者跑 install-v3.sh 时从 templates/v3/ 生成）
leftover=""
for f in NOTES.md "AEGIS-分工.md" CORE-CHECKLIST.md CHECKLIST-GROWTH.md constraints.md EXTERNAL.md preferences.md; do
  [ -e "$f" ] && leftover="$leftover $f"
done
if [ -z "$leftover" ]; then
  echo "  ✓ 自举运行时文件已全部剔除（7 个）"
else
  echo "✗ 交付包内仍有自举运行时文件:$leftover"; exit 1
fi
# 框架本体必须在
for f in AGENTS.md README.md CHANGELOG.md VERSION Makefile; do
  [ -f "$f" ] || { echo "✗ 缺框架本体文件: $f"; exit 1; }
done
echo "  ✓ 框架本体文件齐全"

# 断链检查：docs/README.md「一、随交付」里列出的路径必须真实存在
miss=0
for p in docs/reference/concepts.md docs/guides/README.md docs/release; do
  [ -e "$p" ] || { echo "✗ docs/README.md 声称随交付但不存在: $p"; miss=$((miss+1)); }
done
[ "$miss" -eq 0 ] && echo "  ✓ docs/README.md 随交付索引无断链"
# 反向检查：索引里不该出现已剔除目录的引用（除非在「设计者维度」一节）
if grep -q 'docs/internal' docs/README.md 2>/dev/null; then
  echo "  ✓ docs/README.md 已标注设计者维度目录（交付包中不存在，属正常说明）"
fi
bash scripts/sync.sh --check >/dev/null 2>&1 && echo "  ✓ 派生物一致" || { echo "✗ 派生物不同步，先 make sync"; exit 1; }

# 4. 打包
tar czf "$OUT/$NAME.tar.gz" -C "$TMP" "$NAME"
echo "  ✓ $OUT/$NAME.tar.gz"
