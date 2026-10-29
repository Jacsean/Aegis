#!/usr/bin/env bash
# Aegis 交付打包：只打「使用者维度」产物，剔除设计者维度（dev/）
# 用法: bash scripts/deliver.sh <版本号，如 1.6.0>
# 产出: ../out/aegis-git-<版本>.tar.gz（含 git 历史与 tag，工作树不含 dev/）

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

# 2. 剔除设计者维度（使用者的工作树里不应出现 dev/）
rm -rf "$TMP/$NAME/dev"
touch "$TMP/$NAME/.aegis-package"   # 交付包标记：gate.sh 见此只跑框架自检
say="已剔除 dev/（设计者维度）"; echo "  → $say"

# 2b. 清 git 索引里的 dev/ 跟踪（否则包内 git status 永远脏，branch.sh 第一步就卡）
git -C "$TMP/$NAME" rm -r --cached --quiet dev 2>/dev/null || true
git -C "$TMP/$NAME" -c user.name=deliver -c user.email=deliver@aegis.local \
  commit --quiet --allow-empty -m "chore: 交付包索引剔除设计者维度（deliver.sh 自动提交）"

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
  commit --quiet -m "chore: STATE 重置为新项目起始态（deliver.sh 自动提交）"

# 3. 验收自检：使用者维度完整性
cd "$TMP/$NAME"
for f in AGENTS.md STATE.md docs/CONCEPTS.md .ai/00-core.md .skills/aegis-state/SKILL.md scripts/gate.sh; do
  [ -f "$f" ] || { echo "✗ 缺使用者维度文件: $f"; exit 1; }
done
[ ! -e dev ] && echo "  ✓ dev/ 已剔除"
bash scripts/sync.sh --check >/dev/null 2>&1 && echo "  ✓ 派生物一致" || { echo "✗ 派生物不同步，先 make sync"; exit 1; }

# 4. 打包
tar czf "$OUT/$NAME.tar.gz" -C "$TMP" "$NAME"
echo "  ✓ $OUT/$NAME.tar.gz"
