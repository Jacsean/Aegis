#!/usr/bin/env bash
# Aegis 阶段出口门禁检查
# 用法: bash scripts/gate.sh [S1|S2|...|S8|ALL]
#       bash scripts/gate.sh          # 自动读 STATE.md 的当前阶段

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- 工作根定位 ----
# 1) 环境变量显式指定优先：AEGIS_WORK_ROOT（aegis 自身发布校验时用）
# 2) 否则从脚本所在位置向上找"项目根"：含 .ai/00-core.md 的最浅目录
# 3) 都找不到则回退到脚本的上一级
find_work_root() {
  if [ -n "${AEGIS_WORK_ROOT:-}" ]; then echo "$AEGIS_WORK_ROOT"; return; fi
  local d="$HERE"
  while [ "$d" != "/" ]; do
    if [ -f "$d/.ai/00-core.md" ]; then echo "$d"; return; fi
    d="$(dirname "$d")"
  done
  echo "$(dirname "$HERE")"
}
ROOT="$(find_work_root)"
cd "$ROOT"

# 框架自身发布态：没有项目 docs/，但带了 templates/docs/（说明这是"框架仓库"而非"在用项目"）
# 也可用 AEGIS_SELF=1 强制进入自检模式
SELF_RELEASE=0
if [ "${AEGIS_SELF:-0}" = "1" ]; then SELF_RELEASE=1
elif [ ! -d docs ] && [ -d templates/docs ]; then SELF_RELEASE=1; fi

# docs 根：项目用 docs/；框架自检用 templates/docs/
if [ "$SELF_RELEASE" -eq 1 ]; then DOCS="templates/docs"; else DOCS="docs"; fi

# 代码根：项目用 src/；框架自检时把 scripts/ 当代码根（框架没有业务代码）
if [ "$SELF_RELEASE" -eq 1 ]; then CODE="scripts"; else CODE="src"; fi

# 交付包内：设计者维度文件（docs/internal/）被剔除。此后的「项目内容」检查（S1~S8）一律跳过——
# 交付包是"还能不能装进新项目"的骨架，不是某个具体项目的制品；跑项目门禁只会刷一堆缺项噪音。
IN_PACKAGE=0
[ -f "$ROOT/.aegis-package" ] && IN_PACKAGE=1   # deliver.sh 出包时写入标记；交付包只跑框架自检

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; NC='\033[0m'
FAIL=0
WARN=0
ok()   { printf "  ${GREEN}✓${NC} %s\n" "$1"; }
die()  { printf "  ${RED}✗${NC} %s\n" "$1"; FAIL=$((FAIL+1)); }
warn() { printf "  ${YELLOW}!${NC} %s\n" "$1"; WARN=$((WARN+1)); }
head_() { printf "\n${YELLOW}[%s]${NC} %s\n" "$1" "$2"; }

# ---------- 当前阶段 ----------
PHASE="${1:-}"
if [ -z "$PHASE" ]; then
  if [ -f STATE.md ]; then
    PHASE="$(grep -oE '当前阶段：\*{0,2}[SP][0-9.]+' STATE.md | grep -oE '[SP][0-9.]+' | head -1)"
  fi
  [ -z "$PHASE" ] && PHASE="S1"
fi
# 归一化：S5 之外的 S<n> 直接走别名；不再保留旧编号归一化（v2.0.0 起旧编号只在 git 历史）
# S 阶段 → 内部检查块。S5 同时跑「设计检查点 + 代码检查点」两块
case "$PHASE" in
  S1) PHASE="S1" ;;
  S2) PHASE="S2" ;;
  S3) PHASE="S3" ;;
  S4) PHASE="S4" ;;
  S5) PHASE="S5" ;;
  S6) PHASE="S6" ;;
  S7) PHASE="S7" ;;
  S8) PHASE="S8" ;;
esac

echo "==============================================="
if [ "$SELF_RELEASE" -eq 1 ]; then
  echo " Aegis Gate — 框架自检模式（DOCS=$DOCS CODE=$CODE）"
else
  echo " Aegis Gate — 检查阶段: $PHASE"
fi
echo "==============================================="

# ---------- 包内模式：只做框架自检，不跑项目门禁 ----------
if [ "$IN_PACKAGE" -eq 1 ]; then
  if [ "$SELF_RELEASE" -eq 0 ]; then
    head_ FRAME "交付包自检"
    [ -f VERSION ] && ok "VERSION 存在（$(cat VERSION)）" || die "缺 VERSION"
    miss_spec=0
    for f in 00-core 09-scene-triage 10-S1-title 11-S2-align 12-S3-converge 13-S4-expand \
             14-S5-falsify 15-S6-implement 16-S7-solidify 17-S8-deliver 90-preferences; do
      [ -f ".ai/$f.md" ] || { die "缺 .ai/$f.md"; miss_spec=$((miss_spec+1)); }
    done
    [ "$miss_spec" -eq 0 ] && ok ".ai/ 阶段规范齐全（11 份）"
    [ -d docs/internal ] && die "交付包内出现 docs/internal/（设计者维度未剔除）" || ok "设计者维度已剔除（无 docs/internal/）"
    bash scripts/check-no-legacy.sh . >/dev/null 2>&1 \
      && ok "旧版流程设计不可见（check-no-legacy PASS）" \
      || die "使用者维度仍有旧版流程残留（跑 bash scripts/check-no-legacy.sh 看详情）"
    bash scripts/sync.sh --check >/dev/null 2>&1 \
      && ok "派生物一致" || die "派生物不同步（make sync）"
  fi
  echo ""
  echo "==============================================="
  if [ "$FAIL" -eq 0 ]; then
    echo "PASS — 交付包自检通过（包内不跑项目级 S1~S8 门禁：这是骨架，不是在用项目）"
    echo "==============================================="
    exit 0
  fi
  echo "FAIL — 交付包自检未通过：$FAIL 项缺失"
  echo "==============================================="
  exit 1
fi

# ---------- 通用：分支规范 ----------
if [[ "$PHASE" != "S1" ]] && [ "$SELF_RELEASE" -eq 0 ]; then
  head_ BRANCH "分支规范（每任务必须独立分支）"
  if git rev-parse --git-dir >/dev/null 2>&1; then
    CUR=$(git branch --show-current 2>/dev/null)
    if [ "$CUR" = "main" ] || [ "$CUR" = "master" ] || [ -z "$CUR" ]; then
      die "当前在 main 或游离状态——新任务必须建独立分支（bash scripts/branch.sh start <短名>）"
    elif [[ "$CUR" =~ ^(feat|fix|docs|refactor|test|chore|spike)/[a-z0-9-]+$ ]]; then
      ok "分支名合规: $CUR"
    else
      die "分支名不合规: $CUR（应为 <类型>/<短名>）"
    fi
  else
    warn "非 git 仓库，跳过分支检查"
  fi
fi

# ---------- S1 立题 ----------
if [[ "$PHASE" == "S1" || "$PHASE" == "ALL" ]]; then
  head_ S1 "立题：宪法与环境契约"

  [ -f AGENTS.md ] && ok "AGENTS.md 存在" || die "缺 AGENTS.md"
  [ -f .ai/00-core.md ] && ok ".ai/00-core.md 存在" || die "缺 .ai/00-core.md"
  [ -f .ai/90-preferences.md ] && ok ".ai/90-preferences.md 存在" || die "缺 .ai/90-preferences.md"
  [ -f STATE.md ] && ok "STATE.md 存在" || die "缺 STATE.md"
  [ -f "$DOCS/README.md" ] && ok "$DOCS/README.md 存在" || die "缺 $DOCS/README.md"

  # 概念表（启动协议第 5 步要读它；没有它，词义无从校准）
  # 3.2 修订留痕：.ai/ 文档状态行检查（告警级）
  for f in .ai/*.md .ai/99-reference/*.md; do
    [ -f "$f" ] || continue
    grep -q '^> 状态：' "$f" || warn "$f 缺状态行（00-core 3.2：定稿/暂定/已作废→指向）"
  done
  CF="$DOCS/reference/concepts.md"
  if [ -f "$CF" ]; then
    ok "CONCEPTS.md 存在"
    if grep -q '^## 目录' "$CF" && [ "$(grep -c '^| ' "$CF")" -ge 5 ]; then
      ok "CONCEPTS.md 有目录且非空"
    else
      die "CONCEPTS.md 缺「目录」一节或目录为空（启动协议靠它扫词）"
    fi
  else
    die "缺 $CF —— 概念定义无处安放，词义会随会话漂移"
  fi

  # 环境契约
  if [ -f pyproject.toml ] || [ -f requirements.txt ]; then
    [ -d .venv ] && ok "Python 虚拟环境 .venv 存在" || die "Python 项目必须有 .venv（铁律：环境可复现）"
    [ -x .venv/bin/python ] && ok ".venv/bin/python 可执行" || warn ".venv 存在但 python 不可执行"
  fi
  if [ -f package.json ]; then
    [ -d node_modules ] && ok "node_modules 存在" || warn "node_modules 未安装"
  fi

  [ -f Makefile ] && grep -q '^setup:' Makefile && ok "Makefile 有 setup 目标" || die "Makefile 缺 setup 目标"
  [ -f .gitignore ] && grep -q '\.venv' .gitignore && ok ".gitignore 已忽略 .venv" || warn ".gitignore 未忽略 .venv"
fi

# ---------- FRAME 框架产品完整性（仅自检模式） ----------
if [ "$SELF_RELEASE" -eq 1 ]; then
  head_ FRAME "框架产品完整性（发布前必查）"

  [ -f VERSION ] && ok "VERSION 存在（$(cat VERSION)）" || die "缺 VERSION"

  # 阶段规范 9 份
  miss_spec=0
  for f in 00-core 09-scene-triage 10-S1-title 11-S2-align 12-S3-converge 13-S4-expand \
           14-S5-falsify 15-S6-implement 16-S7-solidify 17-S8-deliver 90-preferences; do
    [ -f ".ai/$f.md" ] || { die "缺 .ai/$f.md"; miss_spec=$((miss_spec+1)); }
  done
  [ "$miss_spec" -eq 0 ] && ok ".ai/ 阶段规范齐全（11 份）"

  # reference schema
  miss_ref=0
  for f in prd-schema align-schema checklist-schema incident-schema state-schema adr-schema handoff-schema design-review-checklist; do
    [ -f ".ai/99-reference/$f.md" ] || { die "缺 .ai/99-reference/$f.md"; miss_ref=$((miss_ref+1)); }
  done
  [ "$miss_ref" -eq 0 ] && ok ".ai/99-reference/ 齐全（8 份）"

  # 适配壳
  miss_ad=0
  for f in adapters/cursor/rules.mdc adapters/trae/rules.md adapters/codex/AGENTS.md adapters/README.md; do
    [ -f "$f" ] || { die "缺适配壳 $f"; miss_ad=$((miss_ad+1)); }
  done
  [ "$miss_ad" -eq 0 ] && ok "adapters/ 适配壳齐全"

  # 模板
  miss_tpl=0
  for f in prd.md README.md design/DESIGN.md design/STYLE.md design/REVIEW-DESIGN.md \
           adr/ADR-0001-template.md incidents/INC-0001-template.md \
           release/RELEASE-template.md internal/reviews/REVIEW-CODE-template.md \
           internal/handoff-index.md internal/handoff/README.md; do
    [ -f "$DOCS/$f" ] || { die "缺模板 $DOCS/$f"; miss_tpl=$((miss_tpl+1)); }
  done
  [ "$miss_tpl" -eq 0 ] && ok "templates/docs/ 模板齐全（11 份）"

  # 脚本可执行性
  for f in scripts/gate.sh scripts/state.sh scripts/branch.sh scripts/sync.sh scripts/deliver.sh scripts/check-no-legacy.sh; do
    [ -f "$f" ] || { die "缺脚本 $f"; continue; }
    bash -n "$f" 2>/dev/null && ok "语法正确: $f" || die "语法错误: $f"
  done
fi

# ---------- S2 对齐（意图校准）----------
if [[ "$PHASE" == "S2" || "$PHASE" == "ALL" ]]; then
  head_ S2 "S2 对齐：两轮讨论 + checklist + 小白语言"

  ALIGN_DIR="$DOCS/rfc"
  # 任务短名来源，按可信度排序：
  #   1) 分支名 <类型>/<短名>（最准；在 main/master 上没有短名）
  #   2) docs/rfc/ 下实际存在的文件（去掉 -R1/-R2 后缀）
  #   3) 都不行才报错
  CUR_BR=$(git branch --show-current 2>/dev/null || echo "")
  SLUG=""
  if [[ "$CUR_BR" =~ ^[a-z]+/(.+)$ ]]; then
    SLUG="${BASH_REMATCH[1]}"
  fi
  if [ -z "$SLUG" ] && [ -d "$ALIGN_DIR" ]; then
    SLUG=$(ls "$ALIGN_DIR" 2>/dev/null \
      | grep -oE '^(ALIGN|CHECKLIST)-.+\.md$' \
      | sed -E 's/^(ALIGN|CHECKLIST)-//; s/\.md$//; s/-R[0-9]+$//' \
      | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')
  fi
  if [ -z "$SLUG" ]; then
    die "找不到对齐任务名（分支名应为 <类型>/<短名>，或先在 $ALIGN_DIR 建 ALIGN-<任务>.md）"
  else
    ok "任务: $SLUG"

    # R1 / R2 的 checklist 与记录
    for R in R1 R2; do
      CF="$ALIGN_DIR/CHECKLIST-${SLUG}-${R}.md"
      AF="$ALIGN_DIR/ALIGN-${SLUG}-${R}.md"
      if [ -f "$CF" ]; then
        # 条目统计：支持 "## 1." / "## A1." / "- [ ] 1." 三种编号形式
        # 排除仅分组用的 "## A. 为什么"（单个字母加点、无数字）
        n_head=$(grep -cE '^#{2,4}[[:space:]]+([A-Z]?[0-9]+)[.．、]' "$CF" || true)
        n_box=$(grep -cE '^[[:space:]]*-[[:space:]]*\[[ xX]\][[:space:]]*([A-Z]?[0-9]+)' "$CF" || true)
        n=$(( ${n_head:-0} + ${n_box:-0} ))
        min=5; [ "$R" = "R2" ] && min=6
        [ "${n:-0}" -ge "$min" ] && ok "$R checklist 条目: $n" || die "$R checklist 条目不足（$n < $min）"

        # 技术黑名单检查
        BLACK='API|接口|数据库|schema|token|鉴权|认证|授权|JWT|session|并发|事务|缓存|中间件|队列|微服务|容器|部署|负载均衡|CDN|状态管理|Redux|ORM|MVC|序列化'
        hits=$(grep -E "^\s*-\s*\[[ xX]\]" "$CF" | grep -oE "$BLACK" | sort -u | tr '\n' ' ')
        if [ -n "$hits" ]; then
          die "$R checklist 含未解释技术词: $hits（铁律：小白语言）"
        else
          ok "$R checklist 无未解释技术词"
        fi

        # 选项式检查：每条必须含「其他」
        other_cnt=$(grep -cE '其他[[:space:]]*[:：]' "$CF" || true)
        if [ "${other_cnt:-0}" -ge "${n:-1}" ]; then
          ok "$R 每条均含「其他」选项（$other_cnt/$n）"
        else
          die "$R 有条目缺「其他：___」选项（$other_cnt/$n，缺则等于逼迫选择）"
        fi

        # 选项式检查：每条至少 3 个方向（A/B/C + 其他）
        opt_a=$(grep -cE '^[[:space:]]*[-*]?[[:space:]]*A[.．、]' "$CF" || true)
        opt_b=$(grep -cE '^[[:space:]]*[-*]?[[:space:]]*B[.．、]' "$CF" || true)
        opt_c=$(grep -cE '^[[:space:]]*[-*]?[[:space:]]*C[.．、]' "$CF" || true)
        if [ "${opt_a:-0}" -ge 1 ] && [ "${opt_b:-0}" -ge 1 ] && [ "${opt_c:-0}" -ge 1 ]; then
          ok "$R 选项结构正常（A:$opt_a B:$opt_b C:$opt_c）"
        else
          die "$R 选项方向不足（A:$opt_a B:$opt_b C:$opt_c，每条至少 3 个方向 + 其他）"
        fi

        # ---- 第七维：外部参照标注 ----
        # 逐条目检查：每个关键点标题下（到下一个同级或更高级标题前）必须至少有一行依据标记。
        # 不能只看总数——总数够了但集中写在开头，等于没标。
        missing_basis=$(awk '
          function flush() {
            if (key != "" && !has) { print key }
          }
          /^#{2,4}[[:space:]]+[A-Z]?[0-9]+[.．、]/ {
            flush()
            key = $0; has = 0; next
          }
          /^#{2,4}[[:space:]]+.*未覆盖方向/ { flush(); key = ""; next }
          /\[(检索|推荐|无参照)\]/ { if (key != "") has = 1 }
          END { flush() }
        ' "$CF")
        n_missing=$(printf '%s\n' "$missing_basis" | grep -c . || true)
        if [ "${n_missing:-0}" -eq 0 ]; then
          ok "$R 每一条都有依据（$n 条全标）"
        else
          die "$R 有 $n_missing 条缺依据行（每条下面都要有 [检索]/[推荐]/[无参照] 之一）："
          printf '%s\n' "$missing_basis" | head -5 | sed -E 's/^#{2,4}[[:space:]]*/      /'
        fi

        # 未覆盖方向：必须有这一节，且不能只有表头
        if grep -qE '^#{2,4}[[:space:]]*.*未覆盖方向' "$CF"; then
          uncovered=$(awk '/^#{2,4}[[:space:]]*.*未覆盖方向/{f=1;next} /^#{1,4} /{if(f)f=0} f' "$CF" \
            | grep -E '^\|' \
            | grep -vE '^\|[[:space:]]*[-: ]+\|' \
            | grep -vE '^\|[[:space:]]*方向[[:space:]]*\|' || true)
          if [ -n "$uncovered" ]; then
            ok "$R 含「未覆盖方向」（$(printf '%s\n' "$uncovered" | grep -c . || echo 0) 行）"
            # 三列检查：随便取一行看竖线数
            cols=$(printf '%s\n' "$uncovered" | head -1 | awk -F'|' '{print NF-2}')
            [ "${cols:-0}" -ge 3 ] && ok "$R 未覆盖方向含三列" || warn "$R 未覆盖方向有 ${cols:-0} 列（应含：方向 / 为什么没列 / 要采用还需了解什么）"
          else
            die "$R「未覆盖方向」一节为空——空等于声称选项已穷尽，而那几乎总是假的"
          fi
        else
          die "$R 缺「未覆盖方向」一节（清单末尾必须写：知道但没列为选项的方向）"
        fi

        # 禁止无出处的断言（警告，不拦截：正常写作也会用这些词）
        vague=$(grep -nE '(业界普遍|业界主流|通常认为|大家都知道|一般来说都)' "$CF" \
          | grep -vE '\[(检索|推荐)\]' | head -3 || true)
        if [ -n "$vague" ]; then
          warn "$R 有未标注出处的概括性断言（应改写成 [检索]/[推荐] 或补具体出处）："
          printf '%s\n' "$vague" | sed 's/^/      /'
        else
          ok "$R 无未标注出处的概括性断言"
        fi

        # ---- 五元素：上下文与归因 ----
        # 「从哪来」：让用户知道这个问题从他的话里哪句来。缺了就无法代入。
        # 条目 = 编号标题 / 标题式（## C. 边界）不计 / 表格行不计 / 代码块不计 / 「未覆盖方向」整节不计
        n_q=$(awk '
          /^```/ { fence = !fence; next }
          fence { next }
          /^#{2,4}[[:space:]]+.*未覆盖方向/ { skip = 1; next }
          /^#{2,4}[[:space:]]+.*(为什么|成功与失败|边界|优先级)[[:space:]]*$/ { next }
          /^#{2,4}[[:space:]]+[A-Z]?[0-9]+[.．、]/ { c++; skip = 0; next }
          END { print c + 0 }
        ' "$CF")
        n_from=$(grep -cE '(\*\*从哪来[：:]|从哪来[：:])' "$CF" || true)
        if [ "${n_from:-0}" -eq 0 ]; then
          die "$R 无任何「从哪来」——用户不知道问题从他的话里哪句来，无法代入"
        elif [ "${n_from:-0}" -lt "${n_q:-1}" ]; then
          warn "$R 有 $((n_q - n_from)) 条缺「从哪来」（共 $n_q 条，标了 $n_from 条）——允许省略，但要在文中写明理由"
        else
          ok "$R 每条都有「从哪来」（$n_from/$n_q）"
        fi

        # 五元素自检：给了几段。段数过少说明回到了旧模板（只有选项 + 判断依据）
        n_from=$(grep -cE '\*\*从哪来[：:]' "$CF" || true)
        n_why=$(grep -cE '\*\*不问会怎样[：:]' "$CF" || true)
        n_how=$(grep -cE '\*\*你该怎么判断[：:]' "$CF" || true)
        total=$(( ${n_from:-0} + ${n_why:-0} + ${n_how:-0} ))
        need=$(( ${n_q:-1} ))   # 条目数：平均每条至少一段
        if [ "$total" -lt "$need" ]; then
          warn "$R 五元素只给了 $total 段（共 $n_q 条）——平均每条不到一段，读起来就是「直接给选项」，用户无法代入"
        else
          ok "$R 五元素覆盖度 $total 段（从哪来 ${n_from:-0} / 不问会怎样 ${n_why:-0} / 你该怎么判断 ${n_how:-0}，共 $n_q 条）"
        fi

        # 「我可能根本没问对」：至少出现一次，给用户跳出错误框架的口子
        if grep -qE '我可能(根本)?没问对' "$CF"; then
          ok "$R 含「我可能没问对」（允许用户指出问题方向错了）"
        else
          warn "$R 缺「我可能没问对」——用户在错误框架里回答也没法纠正"
        fi
      else
        die "缺 $CF"
      fi

      if [ -f "$AF" ]; then ok "$R 讨论记录存在"; else die "缺 $AF"; fi
    done

    # 汇总文档
    SUM="$ALIGN_DIR/ALIGN-${SLUG}.md"
    if [ -f "$SUM" ]; then
      ok "汇总文档存在"
      for sec in "真正想要" "不做什么" "做对" "确认"; do
        grep -q "$sec" "$SUM" && ok "含「$sec」" || die "汇总缺「$sec」一节"
      done
      grep -qE '总确认原话[[:space:]]*[:：][[:space:]]*[^[:space:]<]' "$SUM" \
        && ok "用户已签字确认" || die "缺用户签字（总确认原话为空）"
    else
      die "缺 $SUM"
    fi
  fi
fi

# ---------- S3 收敛 ----------
if [[ "$PHASE" == "S3" || "$PHASE" == "ALL" ]]; then
  head_ S3 "收敛：PRD 六节 + 用户签字"

  if [ ! -f "$DOCS/prd.md" ]; then
    die "缺 $DOCS/prd.md"
  else
    ok "$DOCS/prd.md 存在"
    for sec in "背景" "目标" "非目标" "用户" "验收标准"; do
      grep -q "$sec" "$DOCS/prd.md" && ok "含「$sec」一节" || die "PRD 缺「$sec」一节"
    done
    # 关键界面清单仅前端项目必需
    if grep -qiE '前端|frontend|页面|界面' "$DOCS/prd.md"; then
      if grep -q "关键界面" "$DOCS/prd.md"; then ok "含「关键界面清单」"; else die "前端项目 PRD 缺「关键界面清单」"; fi
    fi

    # 非目标必须非空（且不能只是 <...> 占位符）
    nongram="$(awk '/^#+.*非目标/{f=1;next} /^#+ /{f=0} f' "$DOCS/prd.md" \
      | grep -E '^[[:space:]]*([-*]|[0-9]+\.)' \
      | grep -vE '^[[:space:]]*>' \
      | sed -E 's/<[^<>]*>//g' \
      | sed -E 's/^[[:space:]]*([-*]|[0-9]+\.)[[:space:]]*//' \
      | sed -E 's/(不做|原因)[[:space:]]*[:：]//g' \
      | grep -vE '^[[:space:]:：、,，。.；;！!?？-]*$' \
      | grep -vE '\.\.\.|…' \
      | sed -E 's/^[[:space:]]+|[[:space:]]+$//g' \
      | grep -vE '^$' \
      | head -1)"
    if [ -n "$nongram" ]; then
      ok "「非目标」非空：$(printf '%s' "$nongram" | cut -c1-30)…"
    else
      die "「非目标」为空或仅占位符（必须写具体不做什么）"
    fi
  fi

  # 签字
  if [ -f STATE.md ] && grep -qE 'S3.*确认.*✅' STATE.md; then
    ok "S3 用户签字已记录"
  else
    die "STATE.md 缺 S3 用户签字（未签字禁止进 S4）"
  fi
fi

# ---------- S4 展开 ----------
if [[ "$PHASE" == "S4" || "$PHASE" == "ALL" ]]; then
  head_ S4 "展开：DESIGN + HTML demo + STYLE + ADR"

  [ -f "$DOCS/design/DESIGN.md" ] && ok "DESIGN.md 存在" || die "缺 $DOCS/design/DESIGN.md"
  if [ -f "$DOCS/design/DESIGN.md" ]; then
    grep -qiE '模块|架构' "$DOCS/design/DESIGN.md" && ok "DESIGN 含模块/架构" || die "DESIGN 缺模块划分"
    grep -qiE '依赖' "$DOCS/design/DESIGN.md" && ok "DESIGN 含依赖方向" || warn "DESIGN 缺依赖方向说明"
    grep -qiE '错误|异常' "$DOCS/design/DESIGN.md" && ok "DESIGN 含错误路径" || die "DESIGN 缺错误路径设计"
  fi

  # 前端项目：必须有 demo
  if grep -qiE '前端|frontend|页面|界面' "$DOCS/prd.md" 2>/dev/null; then
    demo_count=$(find "$DOCS/design/demo" -maxdepth 1 -name '*.html' 2>/dev/null | wc -l | tr -d ' ')
    if [ "$demo_count" -gt 0 ]; then
      ok "HTML demo 数量: $demo_count"
      # 每个 demo 是否自包含（不含外链 cdn/http 引用）
      for f in $DOCS/design/demo/*.html; do
        [ -f "$f" ] || continue
        if grep -qE '<script[^>]+src="https?://' "$f" || grep -qE '<link[^>]+href="https?://' "$f"; then
          die "$(basename "$f") 引用了外部资源（必须自包含）"
        fi
      done
      ok "demo 自包含性检查完成"

      # 5 态检查（启发式：文件里出现 loading/空/error 等关键词，或有状态切换）
      for f in $DOCS/design/demo/*.html; do
        [ -f "$f" ] || continue
        hits=0
        grep -qiE 'loading|加载' "$f" && hits=$((hits+1))
        grep -qiE 'empty|空状态|暂无|没有数据' "$f" && hits=$((hits+1))
        grep -qiE 'error|错误|失败' "$f" && hits=$((hits+1))
        if [ "$hits" -lt 3 ]; then
          die "$(basename "$f") 未覆盖 5 态（loading/empty/error 至少都要出现）"
        else
          ok "$(basename "$f") 覆盖多态"
        fi
      done
    else
      die "前端项目缺 HTML demo（$DOCS/design/demo/*.html）—— 铁律二"
    fi

    [ -f "$DOCS/design/STYLE.md" ] && ok "STYLE.md 存在" || die "前端项目缺 $DOCS/design/STYLE.md"
    if [ -f "$DOCS/design/STYLE.md" ]; then
      grep -qiE '色彩|颜色' "$DOCS/design/STYLE.md" && ok "STYLE 含色彩" || warn "STYLE 缺色彩规范"
      grep -qiE '字体|字号' "$DOCS/design/STYLE.md" && ok "STYLE 含字体" || warn "STYLE 缺字体规范"
      grep -qiE '交互' "$DOCS/design/STYLE.md" && ok "STYLE 含交互规范" || warn "STYLE 缺交互规范"
    fi
  fi

  # ADR
  adr_count=$(find "$DOCS/adr" -maxdepth 1 -name 'ADR-*.md' 2>/dev/null | wc -l | tr -d ' ')
  [ "$adr_count" -gt 0 ] && ok "ADR 数量: $adr_count" || warn "无 ADR（若有重大决策则必需）"

  # 签字
  if [ -f STATE.md ] && grep -qE 'S4.*确认.*✅' STATE.md; then
    ok "S4 用户签字已记录"
  else
    die "STATE.md 缺 S4 用户签字（未看 demo 禁止进 S6）"
  fi
fi

# ---------- S5 找破绽 · 设计检查点 ----------
if [[ "$PHASE" == "S5-DESIGN" || "$PHASE" == "ALL" || "$PHASE" == "S5" ]]; then
  head_ S5 "找破绽：设计评审 12 项"
  if [ -f "$DOCS/design/REVIEW-DESIGN.md" ]; then
    ok "REVIEW-DESIGN.md 存在"
    cnt=$(grep -cE '^\s*-\s*\[[ xX]\]' "$DOCS/design/REVIEW-DESIGN.md" || true)
    [ "${cnt:-0}" -ge 12 ] && ok "评审条目数: $cnt" || die "评审条目不足 12 项（当前 ${cnt:-0}）"
  else
    die "缺 $DOCS/design/REVIEW-DESIGN.md"
  fi
  if [ -d "$DOCS/incidents" ] && [ -n "$(ls -A "$DOCS/incidents" 2>/dev/null)" ]; then
    ok "已回灌历史 incidents 检查"
  else
    warn "incidents 库为空（首次项目可忽略）"
  fi
fi

# ---------- S6 实现 ----------
if [[ "$PHASE" == "S6" || "$PHASE" == "ALL" ]]; then
  head_ S6 "实现：测试留证 + 无调试残留 + INC 闭环"

  # 环境
  if [ -f pyproject.toml ] || [ -f requirements.txt ]; then
    [ -x .venv/bin/python ] && ok ".venv/bin/python 可用" || die "缺 .venv（S6 必须用虚拟环境）"
  fi

  # 测试存在且能跑
  t_count=$(find tests -name 'test_*.py' -o -name '*_test.py' 2>/dev/null | wc -l | tr -d ' ')
  if [ "${t_count:-0}" -gt 0 ]; then
    ok "测试文件数: $t_count"
  else
    warn "tests/ 下无测试文件（若为纯文档改动可忽略）"
  fi

  # 调试残留（排除 .venv / node_modules）
  residual=$(grep -rnE '^\s*(print\(|console\.log\(|debugger)' \
      --include='*.py' --include='*.js' --include='*.ts' --include='*.jsx' --include='*.tsx' \
      $CODE 2>/dev/null | grep -vE '^\S+:\s*#' | head -5 || true)
  if [ -n "$residual" ]; then
    die "存在调试残留（print / console.log / debugger）："
    printf '%s\n' "$residual" | sed 's/^/      /'
  else
    ok "无调试残留"
  fi

  # TODO 遗留
  todo_cnt=$(grep -rnE '(TODO|FIXME)' --include='*.py' --include='*.js' --include='*.ts' $CODE 2>/dev/null | wc -l | tr -d ' ')
  [ "${todo_cnt:-0}" -eq 0 ] && ok "无 TODO/FIXME 遗留" || warn "有 $todo_cnt 处 TODO/FIXME（需登记）"

  # 硬编码密钥
  secret=$(grep -rnEi "(api[_-]?key|secret|password|token)\s*[:=]\s*['\"][A-Za-z0-9/+=_-]{12,}" \
      --include='*.py' --include='*.js' --include='*.ts' $CODE 2>/dev/null | head -3 || true)
  if [ -n "$secret" ]; then
    die "疑似硬编码密钥（应走环境变量）："
    printf '%s\n' "$secret" | sed 's/^/      /'
  else
    ok "无硬编码密钥"
  fi

  # INC 是否都填了「预防」
  if [ -d "$DOCS/incidents" ]; then
    inc_files=$(find "$DOCS/incidents" -name 'INC-*.md' ! -name '*template*' 2>/dev/null)
    if [ -n "$inc_files" ]; then
      bad=0
      for f in $inc_files; do
        # 「预防」小节内，取**具体内容**后的一行（跳过说明行、勾选项、占位符）
        prev=$(awk '/^#+.*预防/{f=1;next} /^#+ /{f=0} f' "$f" \
          | grep -vE '^\s*-\s*\[[ xX]\]' \
          | sed -E 's/<[^<>]*>//g' \
          | sed -E 's/\*\*具体内容[[:space:]]*[:：]\*\*//; s/具体内容[[:space:]]*[:：]//' \
          | sed -E 's/^[[:space:]]*([-*]|[0-9]+\.)[[:space:]]*//' \
          | grep -vE '^[[:space:]:：、,，。.；;！!?？*-]*$' \
          | grep -vE '^(至少选|至少填|选一项|任选|例如|示例|提示)' \
          | grep -vE '^>' \
          | head -1)
        [ -z "$prev" ] && { die "$(basename "$f") 缺「预防」具体内容（铁律四：不填不算闭环）"; bad=$((bad+1)); }
      done
      cnt_inc=$(printf '%s\n' "$inc_files" | grep -c . || true)
      [ "$bad" -eq 0 ] && ok "INC 均含「预防」具体内容（$cnt_inc 篇）"
    else
      ok "无新增 INC（首次实现可接受）"
    fi
  fi
fi

# ---------- S5 找破绽 · 代码检查点 ----------
if [[ "$PHASE" == "S5-CODE" || "$PHASE" == "ALL" || "$PHASE" == "S5" ]]; then
  head_ S5 "找破绽：三轮 review"
  today=$(date +%F)
  found=$(find "$DOCS/reviews" -maxdepth 1 -name "REVIEW-CODE-${today}*.md" 2>/dev/null | wc -l | tr -d ' ')
  [ "$found" -gt 0 ] && ok "今日代码评审记录存在" || die "缺今日 $DOCS/reviews/REVIEW-CODE-${today}.md"
  if [ -f STATE.md ] && grep -qE 'S5.*确认.*✅' STATE.md; then ok "S5 用户签字已记录"; else die "缺 S5 用户签字"; fi
fi

# ---------- S7 固化 ----------
if [[ "$PHASE" == "S7" || "$PHASE" == "ALL" ]]; then
  head_ S7 "固化：STATE 精简 + CHANGELOG + INDEX 完整 + tag"

  # STATE 行数上限 40
  if [ -f STATE.md ]; then
    lines=$(wc -l < STATE.md | tr -d ' ')
    if [ "$lines" -le 40 ]; then ok "STATE.md 行数: $lines（≤40）"
    else die "STATE.md 行数: $lines > 40（归档必须压缩，细节进 CHANGELOG）"; fi
    # 下一步不能是空话
    nxt=$(awk '/^## 下一步/{f=1;next} /^## /{f=0} f' STATE.md | grep -E '^[0-9]+\.' | head -1)
    if printf '%s' "$nxt" | grep -qE '继续开发|待定|完善|优化'; then
      die "STATE.md「下一步」过于笼统：「$nxt」（应写可执行动作）"
    elif [ -n "$nxt" ]; then
      ok "「下一步」可执行：$(printf '%s' "$nxt" | cut -c1-28)…"
    else
      die "STATE.md「下一步」为空"
    fi
  else
    die "缺 STATE.md"
  fi

  # CHANGELOG
  if [ -f CHANGELOG.md ]; then
    ok "CHANGELOG.md 存在"
    if grep -qE '^## \[?[0-9]+\.[0-9]+\.[0-9]+' CHANGELOG.md; then
      ok "CHANGELOG 含版本条目"
    else
      die "CHANGELOG 无版本条目（格式：## [1.3.0] - 2026-03-14）"
    fi
    if grep -qE '优化若干|若干细节|等等' CHANGELOG.md; then
      die "CHANGELOG 含无法追溯的模糊表述（「若干细节」类）"
    else
      ok "CHANGELOG 无可追溯性问题"
    fi
  else
    die "缺 CHANGELOG.md"
  fi

  # HANDOFF 开发事件记录（七要素，见 .ai/99-reference/handoff-schema.md）
  HF="$ROOT/docs/internal/handoff.md"
  if [ -f "$HF" ]; then
    ok "HANDOFF 索引存在"
    # 索引层：必须是有表头的一行一条
    if grep -qE '^\|[[:space:]]*编号[[:space:]]*\|' "$HF"; then
      ok "HANDOFF 索引含标准表头（编号/时间/谁/事件/结果/链接）"
    else
      die "HANDOFF 索引缺标准表头（| 编号 | 时间 | 谁 | 事件 | 结果 | 链接 |）"
    fi
    # 最新一条必须有对应记录文件，且七要素齐
    latest=$(grep -E '^\|[[:space:]]*H-[0-9]+' "$HF" | grep -vE '~~' | head -1)
    if [ -n "$latest" ]; then
      hid=$(printf '%s' "$latest" | awk -F'|' '{gsub(/ /,"",$2); print $2}')
      hfile=$(find "$ROOT/dev/handoff" -name "${hid}-*.md" 2>/dev/null | head -1)
      if [ -n "$hfile" ]; then
        ok "$hid 有对应记录文件：$(basename "$hfile")"
        miss=""
        for k in 时间 谁 事件 为什么这样处理 怎么处理的 试过什么 下一步; do
          grep -qE "^[-*][[:space:]]*\*\*${k}" "$hfile" || miss="$miss $k"
        done
        if [ -z "$miss" ]; then
          ok "$hid 七要素齐全"
          # 铁律七：概念固化检查（告警级，不阻塞）
          if grep -qE '^[-*][[:space:]]*\*\*新词\*\*' "$hfile"; then
            ok "$hid 概念固化已申报（新词行存在）"
          else
            warn "$hid 缺「新词」行（铁律七 S7 必填：新词+词条状态，无写「无」）"
          fi
        else
          die "$hid 缺要素：$miss（七要素见 handoff-schema.md）"
        fi
        # 「试过什么」不许是空话
        tried=$(awk '/\*\*试过什么\*\*/{f=1;next} /^[-*][[:space:]]*\*\*/{f=0} f' "$hfile")
        if printf '%s' "$tried" | grep -qE '没试什么|无特别|没有尝试|N/A'; then
          die "$hid「试过什么」写了空话（应写「本任务未走过弯路」，或列出实际试过的方案）"
        elif printf '%s' "$tried" | grep -qE '(✅|❌)'; then
          ok "$hid「试过什么」有具体条目"
        else
          warn "$hid「试过什么」未见 ✅/❌ 标记，确认是否写成了泛泛描述"
        fi
        # 字段名过时：位置 → 地点（2026-10-21 起）
        if grep -qE '^[-*][[:space:]]*\*\*位置\*\*' "$hfile"; then
          warn "$hid 用了旧字段「位置」，应改为「地点」（见 CONCEPTS.md）"
        fi
        # 上下游链接不许留空
        for k in 上接 下接; do
          v=$(grep -E "^[-*][[:space:]]*\*\*${k}\*\*" "$hfile" | head -1)
          if [ -z "$v" ]; then
            die "$hid 缺「$k」（没有就写「无」/「暂无」，不许省略）"
          else
            # 取冒号后内容，去掉空白；空则视为没写
            val=$(printf '%s' "$v" | sed -E "s/^[-*][[:space:]]*\*\*${k}\*\*[：:][[:space:]]*//")
            if [ -z "$(printf '%s' "$val" | tr -d '[:space:]')" ]; then
              die "$hid「$k」为空（写「无」或「暂无」，不许留空）"
            fi
          fi
        done
      else
        die "$hid 在索引里但没有对应记录文件（$ROOT/docs/internal/handoff/${hid}-*.md）"
      fi
      # 逐一核对索引里所有未划掉的编号都有记录文件
      orphan=""
      for h in $(grep -E '^\|[[:space:]]*H-[0-9]+' "$HF" | grep -vE '~~' \
                 | awk -F'|' '{gsub(/ /,"",$2); print $2}'); do
        if ! find "$ROOT/dev/handoff" -name "${h}-*.md" 2>/dev/null | grep -q .; then
          orphan="$orphan $h"
        fi
      done
      if [ -n "$orphan" ]; then
        die "索引里有编号但找不到记录文件：$orphan（索引与记录必须成对）"
      else
        ok "索引与记录文件一一对应"
      fi
    else
      warn "HANDOFF 索引里还没有任何记录"
    fi
  else
    [ "$IN_PACKAGE" -eq 1 ] || warn "缺 $HF —— 本任务结束时有没有写开发事件记录？"
  fi

  # INDEX 完整性
  if [ -f "$DOCS/README.md" ]; then
    missing=0
    for f in $(find docs -type f \( -name '*.md' -o -name '*.html' \) ! -name 'INDEX.md' 2>/dev/null); do
      # 登记方式二选一：写全文件名，或写所在目录（如 `align/`、`adr/`）代表该目录已概括
      base=$(basename "$f")
      dir=$(dirname "$f")
      if grep -q "$base" "$DOCS/README.md"; then continue; fi
      if grep -qF "$(printf '%s/' "$dir")" "$DOCS/README.md"; then continue; fi
      if grep -qF "$(printf '%s' "$dir" | sed -E 's#^(docs|templates/docs)/##')/" "$DOCS/README.md"; then continue; fi
      die "文档未登记进 INDEX: $f"; missing=$((missing+1))
    done
    [ "$missing" -eq 0 ] && ok "$DOCS/ 下全部文档已登记 INDEX"
  else
    die "缺 $DOCS/README.md"
  fi

  # 代码改动检查（相对 main）
  if git rev-parse --git-dir >/dev/null 2>&1; then
    for base in main master; do
      if git show-ref --verify --quiet "refs/heads/$base"; then
        code_chg=$(git diff --name-only "$base...HEAD" 2>/dev/null \
          | grep -E '\.(py|js|ts|jsx|tsx|go|rs|java|rb|php|vue|svelte)$' || true)
        if [ -n "$code_chg" ]; then
          warn "本分支相对 $base 有代码文件改动（S7 本身不应改代码，确认改动都发生在 S6/S5）："
          printf '%s\n' "$code_chg" | head -5 | sed 's/^/      /'
        else
          ok "本分支无代码文件改动（S7 合规）"
        fi
        break
      fi
    done

    # tag 与 CHANGELOG 版本一致
    tag=$(git tag --points-at HEAD 2>/dev/null | head -1)
    if [ -n "$tag" ]; then
      ok "当前 commit 有 tag: $tag"
      tver=$(printf '%s' "$tag" | sed -E 's/^v//')
      if [ -f CHANGELOG.md ] && grep -q "\[$tver\]" CHANGELOG.md; then
        ok "tag 与 CHANGELOG 版本一致（$tver）"
      else
        die "tag $tag 在 CHANGELOG 中无对应版本条目"
      fi
    else
      die "当前 commit 无 tag（归档必须打 tag）"
    fi
  else
    warn "非 git 仓库，跳过 tag 检查"
  fi
fi

# ---------- S8 交付 ----------
if [[ "$PHASE" == "S8" || "$PHASE" == "ALL" ]]; then
  head_ S8 "交付：RELEASE 五节 + 真实证据 + 用户签收"

  rel=$(find "$DOCS/release" -maxdepth 1 -name 'RELEASE-v[0-9]*.md' 2>/dev/null | sort | tail -1)
  if [ -z "$rel" ]; then
    die "缺 $DOCS/release/RELEASE-v<X.Y.Z>.md"
  else
    ok "交付说明: $(basename "$rel")"

    for sec in "交付了什么" "怎么用" "已知限制" "验证证据" "签收"; do
      grep -q "$sec" "$rel" && ok "含「$sec」一节" || die "RELEASE 缺「$sec」一节"
    done

    # 已知限制必须 ≥1 条且不是"无"
    # 注意：条目形如 "- <占位描述>"，占位符剥掉后为空，必须整条丢弃而不是保留空行
    lim=$(awk '/^#+.*已知限制/{f=1;next} /^#+ /{f=0} f' "$rel" \
      | sed -E 's/^[[:space:]]*([-*]|[0-9]+\.)[[:space:]]*//' \
      | grep -vE '^[[:space:]]*>' \
      | sed -E 's/<[^<>]*>//g' \
      | sed -E 's/^[[:space:]]+//' \
      | grep -vE '^[[:space:]:：、,，。.；;！!?？-]*$' \
      | grep -vE '^[[:space:]]*(无|暂无|没有|none|N/A)[[:space:]。.！!]*$' \
      | grep -vE '^例[[:space:]]*[:：]' \
      | head -1)
    if [ -n "$lim" ]; then
      ok "已知限制具体：$(printf '%s' "$lim" | cut -c1-28)…"
    else
      die "「已知限制」为空或仅写「无」（隐藏限制比限制本身更伤信任）"
    fi

    # 验证证据不能是空话
    evid=$(awk '/^#+.*验证证据/{f=1;next} /^#+ /{f=0} f' "$rel" \
      | grep -vE '^[[:space:]]*(```|#|>|$)' \
      | sed -E 's/^[[:space:]]+|[[:space:]]+$//g' \
      | grep -vE '^$' | head -1)
    if [ -z "$evid" ]; then
      die "「验证证据」为空（必须贴真实运行输出）"
    elif printf '%s' "$evid" | grep -qxE '已测试|测试通过|正常|无问题|OK|ok'; then
      die "「验证证据」为结论性空话：「$evid」（需贴真实输出）"
    else
      ok "验证证据有实际内容"
    fi
  fi

  if [ -f STATE.md ] && grep -qE 'S8.*确认.*✅' STATE.md; then
    ok "S8 用户签收已记录"
  else
    die "缺 S8 用户签收（未签收禁止合并到主分支）"
  fi
fi

# ---------- 结果 ----------
echo ""
echo "==============================================="
if [ "$FAIL" -eq 0 ]; then
  printf "${GREEN}PASS${NC} — %s 门禁全部通过" "$PHASE"
  [ "$WARN" -gt 0 ] && printf "（%d 条提醒）" "$WARN"
  echo ""
  echo "==============================================="
  exit 0
else
  printf "${RED}FAIL${NC} — %s 门禁未通过：%d 项缺失，%d 条提醒\n" "$PHASE" "$FAIL" "$WARN"
  echo "==============================================="
  echo "提示：铁律一 —— 门禁未过，禁止进入下一阶段。"
  exit 1
fi
