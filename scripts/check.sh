#!/usr/bin/env bash
# Aegis 四维度自检 —— 把「靠自觉」变成「靠脚本」
#
# 用法:
#   bash scripts/check.sh [all|fact|semantic|time|cognition] [项目目录]
#
# 退出码: 0 = 全部通过（或只有提醒）  1 = 有必须处理的失败项
#
# 为什么要有这个脚本:
#   CORE-CHECKLIST.md 里的四个维度原来只是一份清单，靠 agent 或人主动去执行。
#   实测中发现：没人提醒就不会执行。这个脚本把其中能机械化的部分固定下来。

set -uo pipefail

KIND="${1:-all}"
TARGET="${2:-.}"
cd "$TARGET" 2>/dev/null || { echo "目录不存在: $TARGET"; exit 2; }

FAIL=0
WARN=0
fail() { echo "  ✗ $*"; FAIL=$((FAIL+1)); }
warn() { echo "  ! $*"; WARN=$((WARN+1)); }
pass() { echo "  ✓ $*"; }

# 扫哪些文档（排除设计者维度与历史归档）
scan_md() {
  find docs -type f -name '*.md' 2>/dev/null \
    | grep -v '/internal/' | grep -v '/rfc/' | grep -v '/archive/' | grep -v '/legacy/'
}

# ────────────────────────────────────────────
# 事实维度：标了 [检索] 的，有没有真给来源
# ────────────────────────────────────────────
check_fact() {
  echo ""
  echo "【事实】标了「有出处」的，有没有真给出处"
  local bad=0 checked=0

  while IFS= read -r f; do
    [ -f "$f" ] || continue
    checked=$((checked+1))
    # 行级检查：只看本行
    # 教训：曾用「本行 + 向下 2 行」，结果列表里下一行的链接给上一行背了书，漏报。
    #      宁可误报（来源该写在本行）也不要漏报——漏报等于给人假的安全感。
    while IFS= read -r hit; do
      [ -z "$hit" ] && continue
      local ln="${hit%%:*}" rest="${hit#*:}"
      case "$rest" in
        *http://*|*https://*|*arXiv:*) ;;   # 本行有来源，放行
        *)
          fail "标了 [检索] 但本行没有链接或 arXiv 编号"
          echo "        $f:$ln"
          echo "        ${rest:0:90}"
          bad=$((bad+1))
          ;;
      esac
    done < <(grep -n '\[检索\]' "$f" 2>/dev/null)
  done < <(scan_md)

  [ "$bad" -eq 0 ] && pass "说明过「有出处」的地方都给了出处（扫了 $checked 份文档）"
}

# ────────────────────────────────────────────
# 语义维度：概念表在不在；术语有没有对不上
# ────────────────────────────────────────────
check_semantic() {
  echo ""
  echo "【语义】术语有没有说岔"

  local CF="docs/reference/concepts.md"
  if [ ! -f "$CF" ]; then
    fail "缺 docs/reference/concepts.md（术语无处定义，词义会随会话漂移）"
    return
  fi
  pass "概念表存在（$CF）"

  # 从概念表提取术语：### 中文（English）
  grep -oE '^###[[:space:]]+[^（(]+' "$CF" 2>/dev/null \
    | sed -E 's/^###[[:space:]]+//; s/[[:space:]]+$//' > /tmp/aegis-terms.$$
  local n
  n=$(wc -l < /tmp/aegis-terms.$$ | tr -d ' ')
  if [ "$n" -eq 0 ]; then
    fail "概念表里一个术语都没提取到（格式应为 '### 术语（English）'）"
    rm -f /tmp/aegis-terms.$$
    return
  fi
  pass "概念表已定义 $n 个术语"

  # 反向检查：文档里用反引号包起来的 2-4 字纯中文词，不在术语表的列为候选
  # 注意（三个坑，都实测踩过）：
  #   1. Git Bash 的 grep 不支持 [一-龥]，也不支持 -P，两者都返回空
  #   2. ${#w} 取到的是字节数（'血条' = 6），不是字符数 —— 中文 1 字 = 3 字节
  #   3. 所以改用「字节长度 6-12（即 2-4 个汉字）+ 不含 ASCII」
  local cand
  cand=$(scan_md | xargs -r grep -ohE '`[^`]{2,12}`' 2>/dev/null \
    | tr -d '`' \
    | while IFS= read -r w; do
        blen=$(printf '%s' "$w" | wc -c | tr -d ' ')
        if [ "$blen" -ge 6 ] && [ "$blen" -le 12 ] \
           && ! printf '%s' "$w" | grep -q '[a-zA-Z0-9_/*.<>|:()]' \
           && ! printf '%s' "$w" | grep -qE '^[…·—－]+$'; then
          printf '%s\n' "$w"
        fi
      done \
    | sort | uniq -c | sort -rn \
    | while read -r cnt word; do
        grep -qxF "$word" /tmp/aegis-terms.$$ || echo "$cnt $word"
      done | head -8)

  if [ -n "$cand" ]; then
    warn "以下中文词在文档里被当作术语用，但概念表没有定义（考虑补进去，或改用已有词）："
    echo "$cand" | while read -r cnt word; do echo "        $word（出现 $cnt 次）"; done
  else
    pass "没有发现「用了但没定义」的术语"
  fi
  rm -f /tmp/aegis-terms.$$
}

# ────────────────────────────────────────────
# 时间维度：NOTES 有没有更新、字段全不全
# ────────────────────────────────────────────
check_time() {
  echo ""
  echo "【时间】下次能不能接上"

  if [ ! -f NOTES.md ]; then
    fail "缺 NOTES.md —— 这次做完，下个会话接不上"
    return
  fi
  pass "NOTES.md 存在"

  # 每条记录必须含的字段
  local entries
  entries=$(grep -c '^## ' NOTES.md 2>/dev/null || true)
  entries="${entries:-0}"
  if [ "$entries" -eq 0 ] 2>/dev/null || [ "$entries" -le 0 ]; then
    fail "NOTES.md 里一条记录都没有（格式：'## <日期> <任务一句话>'）"
    return
  fi
  pass "有 $entries 条记录"

  local badent=0
  # 按 ## 切块，逐块检查必需字段
  awk '
    BEGIN { RS = "\n## "; n = 0 }
    NR == 1 { next }
    {
      n++
      title = $0
      sub(/\n.*/, "", title)
      lack = ""
      if ($0 !~ /用了/) lack = lack "「用了什么」"
      if ($0 !~ /判断/) lack = lack "「判断是什么」"
      if ($0 !~ /排除/) lack = lack "「排除了什么」"
      if ($0 !~ /否定/) lack = lack "「用户明确否定的」"
      if ($0 !~ /说明我错|我错了/) lack = lack "「什么情况说明我错了」"
      if (lack != "") printf "条目「%s」缺: %s\n", title, lack
    }
  ' NOTES.md > /tmp/aegis-notes.$$ 2>/dev/null

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    warn "$line"
    badent=$((badent+1))
  done < /tmp/aegis-notes.$$
  rm -f /tmp/aegis-notes.$$

  [ "$badent" -eq 0 ] && pass "所有记录字段齐全（用了/判断/排除/否定/什么情况说明我错了）"

  # 源码是否比 NOTES 新（改了代码没记录）
  if [ -d src ]; then
    local newest
    newest=$(find src -type f \( -name '*.py' -o -name '*.js' -o -name '*.ts' -o -name '*.go' -o -name '*.rs' \) -newer NOTES.md 2>/dev/null | head -3)
    if [ -n "$newest" ]; then
      warn "以下源码比 NOTES.md 新（改完没记录）："
      echo "$newest" | while IFS= read -r f; do echo "        $f"; done
    else
      pass "源码没有比 NOTES.md 新的（改了就记了）"
    fi
  fi
}

# ────────────────────────────────────────────
# 认知维度：NOTES 说用了某方法，正文有没有痕迹
# ────────────────────────────────────────────
check_cognition() {
  echo ""
  echo "【认知】说了用什么方法，输出里有没有痕迹"

  if [ ! -f NOTES.md ]; then
    warn "没有 NOTES.md，无法检查（先跑时间维度）"
    return
  fi

  # 从 NOTES 提取「用了」后面的方法名
  local models
  models=$(grep -oE '(第一性原理|5Why|5W2H|MECE|逆向|事前验尸|预先验尸|六顶帽|苏格拉底|推论阶梯|二阶思维|反方最强论证|Kano|峰终|设计思维|双环反思|判据优先|问题分类)' NOTES.md 2>/dev/null | sort -u)

  if [ -z "$models" ]; then
    warn "NOTES 里没有记录用了哪个思维模型（认知维度无从检查）"
    return
  fi

  local nodoc=0
  while IFS= read -r m; do
    [ -z "$m" ] && continue
    # 在文档里找该模型名（包括 docs/internal/ —— 那里也是"输出"的一部分）
    if find docs -type f -name '*.md' 2>/dev/null | xargs -r grep -l "$m" 2>/dev/null | grep -q .; then
      pass "「$m」在文档里有痕迹"
    else
      warn "「$m」只在 NOTES 里提到，项目文档里找不到痕迹（说了没写？）"
      nodoc=$((nodoc+1))
    fi
  done <<< "$models"

  [ "$nodoc" -eq 0 ] && pass "NOTES 里声明的模型，在文档里都能找到对应内容"
}

# ────────────────────────────────────────────
# 主流程
# ────────────────────────────────────────────
echo "==============================================="
echo " Aegis 四维度自检 —— $TARGET"
echo "==============================================="

case "$KIND" in
  all)       check_fact; check_semantic; check_time; check_cognition ;;
  fact)      check_fact ;;
  semantic)  check_semantic ;;
  time)      check_time ;;
  cognition) check_cognition ;;
  *) echo "未知维度: $KIND（可选 all|fact|semantic|time|cognition）"; exit 2 ;;
esac

echo ""
echo "==============================================="
if [ "$FAIL" -gt 0 ]; then
  echo " 不通过 —— $FAIL 项必须处理，$WARN 项提醒"
  echo "==============================================="
  echo "提示：这四个维度查的是「言行是否一致」，查不了「判断是否正确」。"
  exit 1
else
  echo " 通过 —— $WARN 项提醒（不阻断）"
  echo "==============================================="
  exit 0
fi
