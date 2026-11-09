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

# 2. 剔除设计者维度（使用者的工作树里不应出现 docs/internal/）
rm -rf "$TMP/$NAME/docs/internal"
touch "$TMP/$NAME/.aegis-package"   # 交付包标记：gate.sh 见此只跑框架自检
say="已剔除 docs/internal/（设计者维度）"; echo "  → $say"


# 2a2. 重置自举产生的本地状态（这些是「框架自己这个项目」的，不是「给使用者的模板」）
#      NOTES.md 里是框架开发过程中的决策记录，不该随交付包发给使用者；
#      AEGIS-分工.md 是安装时按本机环境探测生成的，使用者要自己跑一次。
rm -f "$TMP/$NAME/NOTES.md" "$TMP/$NAME/AEGIS-分工.md"
echo "  → 已剔除 NOTES.md 与 AEGIS-分工.md（自举本地状态，使用者需自行生成）"

# 2b. 清 git 索引里已剔除项的跟踪（否则包内 git status 永远脏，branch.sh 第一步就卡）
git -C "$TMP/$NAME" rm -r --cached --quiet docs/internal 2>/dev/null || true
git -C "$TMP/$NAME" rm -r --cached --quiet docs/internal/reasonix/tests 2>/dev/null || true
git -C "$TMP/$NAME" rm --cached --quiet NOTES.md "AEGIS-分工.md" 2>/dev/null || true
git -C "$TMP/$NAME" -c user.name=deliver -c user.email=deliver@aegis.local \
  commit --quiet --allow-empty -m "chore: 交付包索引剔除设计者维度与测试产物（deliver.sh 自动提交）"

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
[ ! -e docs/internal ] && echo "  ✓ docs/internal/ 已剔除"
[ ! -e NOTES.md ] && echo "  ✓ NOTES.md 已剔除（自举本地状态）"
[ ! -e "AEGIS-分工.md" ] && echo "  ✓ AEGIS-分工.md 已剔除（使用者需自行生成）"
if [ -f docs/internal/reasonix/FINDINGS.md ]; then
  echo "  ✓ FINDINGS.md 保留（Aegis 实测发现，是设计依据）"
else
  echo "  ! FINDINGS.md 不存在（若尚未产生实测发现可忽略）"
fi
bash scripts/sync.sh --check >/dev/null 2>&1 && echo "  ✓ 派生物一致" || { echo "✗ 派生物不同步，先 make sync"; exit 1; }

# 4. 打包
tar czf "$OUT/$NAME.tar.gz" -C "$TMP" "$NAME"
echo "  ✓ $OUT/$NAME.tar.gz"
