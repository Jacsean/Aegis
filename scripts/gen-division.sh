#!/usr/bin/env bash
# 生成《AEGIS 分工约定》：探测项目已有的 skills，按职责表判断与 Aegis 的关系
# 用法: bash scripts/gen-division.sh <目标项目目录>
set -uo pipefail

TARGET="${1:-}"
if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then
  echo "用法: bash scripts/gen-division.sh <目标项目目录>（目录必须已存在）"
  exit 1
fi

OUT="$TARGET/AEGIS-分工.md"

# ---------- 职责表 ----------
# 输出格式: 关系|它负责什么|怎么相处
relation_of() {
  case "$1" in
    # A 类：真冲突（都不需要裁决）
    using-superpowers)
      echo "并列|让 agent 先找该用哪个 skill|两个入口都注入；Aegis 在前（先判断要不要做），它在后" ;;
    init)
      echo "并列|自动生成 AGENTS.md|Aegis 用标记追加，不覆盖它生成的内容" ;;

    # B 类：串联（有先后）
    brainstorming)
      echo "串联|发散 2-3 个方案 + 权衡|Aegis 先判断「你要的是不是他需要的」，它再发散" ;;
    knowledge-handbook)
      echo "串联|沉淀成可检索的手册|NOTES.md 是源，知识库是提炼；NOTES 降级为索引层" ;;
    find-skills|install-capability)
      echo "串联|查找/安装外部 skill|它负责装，Aegis 负责记账（装完进本文件，调用进 NOTES）" ;;

    # C 类：并列（查的东西不同）
    verification-before-completion)
      echo "并列|验证是否真的完成（跑测试、看输出）|它查「做对没」，Aegis 查「记录没、来源标没、4 问题过没过」" ;;
    requesting-code-review|receiving-code-review)
      echo "并列|代码评审|它评代码质量，Aegis 不评价内容好坏" ;;
    review|security-review)
      echo "并列|正确性/安全性审查（子智能体）|同上，互不干扰" ;;
    thinking-model-workflows)
      echo "并列|用 PDCA/OODA/FMEA 编排多智能体工作流|它管「多个 agent 怎么协同」，Aegis 管「一句话怎么理解」，维度不同" ;;

    # D 类：让路（Aegis 完全不碰）
    writing-plans|executing-plans)
      echo "让路|计划怎么写、怎么执行|Aegis 不碰" ;;
    test-driven-development|test)
      echo "让路|测试怎么做、怎么跑|Aegis 不碰；除非 constraints.md 里要求「必须有测试」" ;;
    systematic-debugging)
      echo "让路|怎么调试|Aegis 不碰" ;;
    finishing-a-development-branch)
      echo "让路|分支怎么收尾|Aegis 不碰" ;;
    using-git-worktrees)
      echo "让路|工作区怎么隔离|Aegis 不碰" ;;
    subagent-driven-development|dispatching-parallel-agents)
      echo "让路|子智能体怎么派|Aegis 不碰" ;;
    version-control)
      echo "让路|分支策略 / SemVer / 提交规范|让给它；Aegis 的 preferences 只保留「必须建分支」这一条底线" ;;
    changelog-keepachangelog|maker-project-log)
      echo "让路|变更日志 / 项目归档|Aegis 不碰" ;;
    skill-creator|writing-skills)
      echo "让路|怎么做 skill|Aegis 不碰" ;;
    explore|research)
      echo "让路|调研|Aegis 不碰；但要求调研结论标来源" ;;

    # Aegis 自己
    aegis-think|aegis-core)
      echo "自有|Aegis 自己的能力|—" ;;

    # 未收录
    *)
      echo "默认|（未收录进职责表）|Aegis 不管它怎么做，但它的产出要进 NOTES、结论要标来源" ;;
  esac
}

# ---------- 探测已有的 skill ----------
declare -a FOUND=()
add_found() {
  local name="$1"
  for x in "${FOUND[@]:-}"; do [ "$x" = "$name" ] && return; done
  FOUND+=("$name")
}

for d in "$TARGET/.agents/skills" "$TARGET/.claude/skills" "$TARGET/.trae/skills" \
         "$HOME/.reasonix/skills" "$HOME/.claude/skills" "$HOME/.agents/skills"; do
  [ -d "$d" ] || continue
  for s in "$d"/*/; do
    [ -d "$s" ] || continue
    add_found "$(basename "$s")"
  done
done

# ---------- 生成 ----------
{
  echo "# AEGIS 分工约定"
  echo ""
  echo "> 生成时间：$(date '+%Y-%m-%d %H:%M')"
  echo "> 本文件说明：这个项目里 Aegis 和已有能力怎么分工。**换 agent 接手时，先读这份再动手。**"
  echo "> 重新生成：\`bash scripts/gen-division.sh .\`（会覆盖本文件）"
  echo ""
  echo "---"
  echo ""
  echo "## 一、Aegis 负责什么（底线，不可绕过）"
  echo ""
  echo "| 环节 | 管什么 |"
  echo "|---|---|"
  echo "| 入口 | 判断「你要的是不是他需要的」，给出判断和依据 |"
  echo "| 出口 | 记录（NOTES 更新）/ 来源标注 / 4 个问题逐条过 |"
  echo ""
  echo "**Aegis 不管**：怎么做测试、怎么设计方案、怎么调试、用什么框架——那些是专业做法，由对应能力或你决定。"
  echo ""
  echo "---"
  echo ""
  echo "## 二、检测到的能力，分工如下"
  echo ""

  if [ "${#FOUND[@]}" -eq 0 ]; then
    echo "（没有检测到已安装的 skill）"
  else
    # 只列职责表里已收录的；未收录的折叠成一行（否则装了 40 个 skill 的表没人看）
    echo "| 能力 | 它负责什么 | 怎么和 Aegis 相处 |"
    echo "|---|---|---|"
    OWN=(); SERIAL=(); PARALLEL=(); YIELD=(); DEFAULT=()
    for s in "${FOUND[@]}"; do
      IFS='|' read -r rel job how <<< "$(relation_of "$s")"
      case "$rel" in
        自有)   OWN+=("$s") ;;
        串联)   SERIAL+=("$s");   printf '| `%s` | %s | %s |\n' "$s" "$job" "$how" ;;
        并列)   PARALLEL+=("$s"); printf '| `%s` | %s | %s |\n' "$s" "$job" "$how" ;;
        让路)   YIELD+=("$s");    printf '| `%s` | %s | %s |\n' "$s" "$job" "$how" ;;
        *)      DEFAULT+=("$s") ;;
      esac
    done
    echo ""
    echo "**汇总**：自有 ${#OWN[@]} 项 · 串联 ${#SERIAL[@]} 项 · 并列 ${#PARALLEL[@]} 项 · 让路 ${#YIELD[@]} 项"
    if [ "${#DEFAULT[@]}" -gt 0 ]; then
      echo ""
      echo "**另有 ${#DEFAULT[@]} 项未收录的能力**（按下面第三节的默认规则处理）："
      echo ""
      echo '```'
      printf '%s\n' "${DEFAULT[@]}" | paste -sd' ' -
      echo '```'
    fi
  fi

  echo ""
  echo "---"
  echo ""
  echo "## 三、对任何未收录的能力，默认规则"
  echo ""
  echo "1. Aegis **不管它怎么做**（那是它的专业）"
  echo '2. 它的**产出要进 `NOTES.md`**（用了什么、产出在哪、留下什么）'
  echo "3. 它的**结论要标来源**：\`[检索]\` / \`[推荐]\` / \`[无参照]\`"
  echo "4. 一次任务**最多用 2 个**外接能力；超过说明任务太大，该拆"
  echo ""
  echo "---"
  echo ""
  echo "## 四、Aegis 明确做不到的事（提前说明，免得误判）"
  echo ""
  echo "| 做不到 | 为什么 |"
  echo "|---|---|"
  echo "| 拦住「已加载到上下文的其他 skill 指令被执行」 | 那不是工具调用，是模型照着做，没有事件可挂 |"
  echo "| 拦住「模型不调用任何工具、直接回答」 | 没有动作可拦 |"
  echo "| 验证「结论内容对不对」 | 只能验证形式（有没有标来源），不能验证真假 |"
  echo ""
  echo "**所以 Aegis 的定位是：审计 + 否决权，不是控制权。** 它能说「这不算完成」，不能说「你不能这么想」。"
} > "$OUT"

echo "→ 已生成：$OUT"
echo "  检测到 ${#FOUND[@]} 个已安装能力"
