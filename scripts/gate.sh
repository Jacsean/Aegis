#!/usr/bin/env bash
# Aegis 阶段出口门禁检查
# 用法: bash scripts/gate.sh [P0|P1|P2|...]
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
    PHASE="$(grep -oE '当前阶段：\*{0,2}P[0-9.]+' STATE.md | grep -oE 'P[0-9.]+' | head -1)"
  fi
  [ -z "$PHASE" ] && PHASE="P0"
fi
# 归一化：P0.5 → P05
[[ "$PHASE" == "P0.5" ]] && PHASE="P05"

echo "==============================================="
if [ "$SELF_RELEASE" -eq 1 ]; then
  echo " Aegis Gate — 框架自检模式（DOCS=$DOCS CODE=$CODE）"
else
  echo " Aegis Gate — 检查阶段: $PHASE"
fi
echo "==============================================="

# ---------- 通用：分支规范 ----------
if [[ "$PHASE" != "P0" ]] && [ "$SELF_RELEASE" -eq 0 ]; then
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

# ---------- P0 立项 ----------
if [[ "$PHASE" == "P0" || "$PHASE" == "ALL" ]]; then
  head_ P0 "立项：宪法与环境契约"

  [ -f AGENTS.md ] && ok "AGENTS.md 存在" || die "缺 AGENTS.md"
  [ -f .ai/00-core.md ] && ok ".ai/00-core.md 存在" || die "缺 .ai/00-core.md"
  [ -f .ai/90-preferences.md ] && ok ".ai/90-preferences.md 存在" || die "缺 .ai/90-preferences.md"
  [ -f STATE.md ] && ok "STATE.md 存在" || die "缺 STATE.md"
  [ -f "$DOCS/INDEX.md" ] && ok "$DOCS/INDEX.md 存在" || die "缺 $DOCS/INDEX.md"

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
  for f in 00-core 01-P0-init 015-P05-align 02-P1-ideate 03-P2-design 04-P3-validate \
           05-P4-implement 06-P5-verify 07-P6-archive 08-P7-deliver 90-preferences; do
    [ -f ".ai/$f.md" ] || { die "缺 .ai/$f.md"; miss_spec=$((miss_spec+1)); }
  done
  [ "$miss_spec" -eq 0 ] && ok ".ai/ 阶段规范齐全（11 份）"

  # reference schema
  miss_ref=0
  for f in prd-schema align-schema checklist-schema incident-schema state-schema adr-schema design-review-checklist; do
    [ -f ".ai/99-reference/$f.md" ] || { die "缺 .ai/99-reference/$f.md"; miss_ref=$((miss_ref+1)); }
  done
  [ "$miss_ref" -eq 0 ] && ok ".ai/99-reference/ 齐全（7 份）"

  # 适配壳
  miss_ad=0
  for f in adapters/cursor/rules.mdc adapters/trae/rules.md adapters/codex/AGENTS.md adapters/README.md; do
    [ -f "$f" ] || { die "缺适配壳 $f"; miss_ad=$((miss_ad+1)); }
  done
  [ "$miss_ad" -eq 0 ] && ok "adapters/ 适配壳齐全"

  # 模板
  miss_tpl=0
  for f in prd.md INDEX.md design/DESIGN.md design/STYLE.md design/REVIEW-DESIGN.md \
           adr/ADR-0001-template.md incidents/INC-0001-template.md \
           release/RELEASE-template.md reviews/REVIEW-CODE-template.md; do
    [ -f "$DOCS/$f" ] || { die "缺模板 $DOCS/$f"; miss_tpl=$((miss_tpl+1)); }
  done
  [ "$miss_tpl" -eq 0 ] && ok "templates/docs/ 模板齐全（9 份）"

  # 脚本可执行性
  for f in scripts/gate.sh scripts/state.sh scripts/branch.sh scripts/sync.sh; do
    [ -f "$f" ] || { die "缺脚本 $f"; continue; }
    bash -n "$f" 2>/dev/null && ok "语法正确: $f" || die "语法错误: $f"
  done
fi

# ---------- P0.5 意图校准 ----------
if [[ "$PHASE" == "P05" || "$PHASE" == "ALL" ]]; then
  head_ P05 "意图校准：两轮讨论 + checklist + 小白语言"

  ALIGN_DIR="$DOCS/align"
  # 任务短名来源，按可信度排序：
  #   1) 分支名 <类型>/<短名>（最准；在 main/master 上没有短名）
  #   2) docs/align/ 下实际存在的文件（去掉 -R1/-R2 后缀）
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

# ---------- P1 构思 ----------
if [[ "$PHASE" == "P1" || "$PHASE" == "ALL" ]]; then
  head_ P1 "构思：PRD 六节 + 用户签字"

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
  if [ -f STATE.md ] && grep -qE 'P1.*确认.*✅' STATE.md; then
    ok "P1 用户签字已记录"
  else
    die "STATE.md 缺 P1 用户签字（未签字禁止进 P2）"
  fi
fi

# ---------- P2 设计 ----------
if [[ "$PHASE" == "P2" || "$PHASE" == "ALL" ]]; then
  head_ P2 "设计：DESIGN + HTML demo + STYLE + ADR"

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
  if [ -f STATE.md ] && grep -qE 'P2.*确认.*✅' STATE.md; then
    ok "P2 用户签字已记录"
  else
    die "STATE.md 缺 P2 用户签字（未看 demo 禁止进 P4）"
  fi
fi

# ---------- P3 设计评审 ----------
if [[ "$PHASE" == "P3" || "$PHASE" == "ALL" ]]; then
  head_ P3 "验证：设计评审 12 项"
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

# ---------- P4 实现 ----------
if [[ "$PHASE" == "P4" || "$PHASE" == "ALL" ]]; then
  head_ P4 "实现：测试留证 + 无调试残留 + INC 闭环"

  # 环境
  if [ -f pyproject.toml ] || [ -f requirements.txt ]; then
    [ -x .venv/bin/python ] && ok ".venv/bin/python 可用" || die "缺 .venv（P4 必须用虚拟环境）"
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

# ---------- P5 校验 ----------
if [[ "$PHASE" == "P5" || "$PHASE" == "ALL" ]]; then
  head_ P5 "校验：三轮 review"
  today=$(date +%F)
  found=$(find "$DOCS/reviews" -maxdepth 1 -name "REVIEW-CODE-${today}*.md" 2>/dev/null | wc -l | tr -d ' ')
  [ "$found" -gt 0 ] && ok "今日代码评审记录存在" || die "缺今日 $DOCS/reviews/REVIEW-CODE-${today}.md"
  if [ -f STATE.md ] && grep -qE 'P5.*确认.*✅' STATE.md; then ok "P5 用户签字已记录"; else die "缺 P5 用户签字"; fi
fi

# ---------- P6 归档 ----------
if [[ "$PHASE" == "P6" || "$PHASE" == "ALL" ]]; then
  head_ P6 "归档：STATE 精简 + CHANGELOG + INDEX 完整 + tag"

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

  # INDEX 完整性
  if [ -f "$DOCS/INDEX.md" ]; then
    missing=0
    for f in $(find docs -type f \( -name '*.md' -o -name '*.html' \) ! -name 'INDEX.md' 2>/dev/null); do
      # 登记方式二选一：写全文件名，或写所在目录（如 `align/`、`adr/`）代表该目录已概括
      base=$(basename "$f")
      dir=$(dirname "$f")
      if grep -q "$base" "$DOCS/INDEX.md"; then continue; fi
      if grep -qF "$(printf '%s/' "$dir")" "$DOCS/INDEX.md"; then continue; fi
      if grep -qF "$(printf '%s' "$dir" | sed -E 's#^(docs|templates/docs)/##')/" "$DOCS/INDEX.md"; then continue; fi
      die "文档未登记进 INDEX: $f"; missing=$((missing+1))
    done
    [ "$missing" -eq 0 ] && ok "$DOCS/ 下全部文档已登记 INDEX"
  else
    die "缺 $DOCS/INDEX.md"
  fi

  # 代码改动检查（相对 main）
  if git rev-parse --git-dir >/dev/null 2>&1; then
    for base in main master; do
      if git show-ref --verify --quiet "refs/heads/$base"; then
        code_chg=$(git diff --name-only "$base...HEAD" 2>/dev/null \
          | grep -E '\.(py|js|ts|jsx|tsx|go|rs|java|rb|php|vue|svelte)$' || true)
        if [ -n "$code_chg" ]; then
          warn "本分支相对 $base 有代码文件改动（P6 本身不应改代码，确认这些改动都发生在 P4/P5）："
          printf '%s\n' "$code_chg" | head -5 | sed 's/^/      /'
        else
          ok "本分支无代码文件改动（P6 合规）"
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

# ---------- P7 交付 ----------
if [[ "$PHASE" == "P7" || "$PHASE" == "ALL" ]]; then
  head_ P7 "交付：RELEASE 五节 + 真实证据 + 用户签收"

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

  if [ -f STATE.md ] && grep -qE 'P7.*确认.*✅' STATE.md; then
    ok "P7 用户签收已记录"
  else
    die "缺 P7 用户签收（未签收禁止合并到主分支）"
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
