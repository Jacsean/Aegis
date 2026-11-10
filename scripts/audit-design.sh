#!/usr/bin/env bash
# 对照「2 维度 + 4 问题」的完整审计
# 用法: bash scripts/audit-design.sh [项目目录]
set -uo pipefail
T="${1:-.}"
cd "$T" 2>/dev/null || exit 2

ok()   { echo "  ✓ $*"; }
miss() { echo "  ✗ $*"; }
part() { echo "  ~ $*"; }

echo "==============================================="
echo " 设计目标对齐审计 —— $T"
echo "==============================================="

echo ""
echo "【维度一】思维模型（想法是否合理）"
n=$(find .agents/skills/aegis-think/references -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
[ "${n:-0}" -ge 16 ] && ok "16 个思维模型已装（$n 个文件）" || miss "思维模型缺失（只有 ${n:-0} 个）"
[ -f .agents/skills/aegis-think/SKILL.md ] && ok "选择机制的入口在（SKILL.md：先自问缺什么，再挑模型）" || miss "缺 SKILL.md"

echo ""
echo "【维度二】工程方法（如何设计/实现/验证/维护）"
# 如何设计
if [ -f .aegis/templates/design/DESIGN.md ] && [ -f .aegis/templates/design/STYLE.md ]; then
  ok "如何设计：DESIGN / STYLE 模板在"
else
  miss "如何设计：缺 DESIGN / STYLE 模板"
fi
# 如何实现
if grep -rqs '过度设计\|依赖能不加就不加' preferences.md 2>/dev/null; then
  ok "如何实现：给了实现约束（拒绝过度设计 / 依赖最小化）"
else
  part "如何实现：只给了粗约束（专业方法让路给 TDD 类 skill，这是定位使然）"
fi
# 如何验证
if grep -qs '必须贴出.*实际验证过的输出' AGENTS.md 2>/dev/null; then
  ok "如何验证：完成必须留证（贴真实输出，「应该可以」不算）"
else
  miss "如何验证：缺「完成必须留证」"
fi
[ -f .aegis/check.sh ] && ok "如何验证：四维度自检脚本在（bash .aegis/check.sh all .）" || miss "如何验证：缺 check.sh"
# 如何维护
m=0
[ -f docs/reference/concepts.md ] && m=$((m+1))
[ -f .aegis/templates/adr/ADR-0001-template.md ] && m=$((m+1))
[ -f .aegis/templates/incidents/INC-0001-template.md ] && m=$((m+1))
[ -f .aegis/templates/release/RELEASE-template.md ] && m=$((m+1))
[ "$m" -eq 4 ] && ok "如何维护：术语表 + ADR + 故障记录 + 发布说明（4/4）" || part "如何维护：$m/4 项"

echo ""
echo "【问题 1】思考模式是否合理"
[ -f .agents/skills/aegis-think/SKILL.md ] && ok "有 16 个模型 + 「先自问缺什么」的选择机制" || miss "无"
part "但没有「选对没选对」的验证机制（16 个也覆盖不了「人类百种思维模式」——这是设计取舍，不是缺陷）"

echo ""
echo "【问题 2】方法与理念是否凭空捏造"
grep -qs '说了用 X' CORE-CHECKLIST.md 2>/dev/null && ok "认知维度：说了用 X，输出里要有 X 的痕迹" || miss "缺认知维度"
grep -qs '\[检索\]' CORE-CHECKLIST.md 2>/dev/null && ok "事实维度：标了有出处，要给出来源" || miss "缺事实维度"

echo ""
echo "【问题 3】概念名词是否对齐"
[ -f docs/reference/concepts.md ] && ok "术语表在（docs/reference/concepts.md）" || miss "缺术语表"
grep -qs '语义' CORE-CHECKLIST.md 2>/dev/null && ok "语义维度在检查清单里" || miss "缺语义维度"

echo ""
echo "【问题 4】跨会话/项目/agent 无损接续"
[ -f NOTES.md ] && ok "NOTES.md 在（记录格式含「用户明确否定的」）" || miss "缺 NOTES.md"
grep -qs '下次能不能接上' CORE-CHECKLIST.md 2>/dev/null && ok "时间维度在检查清单里" || miss "缺时间维度"
[ -f AEGIS-分工.md ] && ok "AEGIS-分工.md 在（换 agent 接手先读这份）" || miss "缺分工约定"

echo ""
echo "==============================================="
echo " 审计完。标记说明：✓ 有载体  ~ 部分/取舍  ✗ 缺口"
echo "==============================================="
