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
