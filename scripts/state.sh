#!/usr/bin/env bash
# Aegis 状态快照读写
# 用法:
#   bash scripts/state.sh show                  查看当前状态
#   bash scripts/state.sh init                  初始化 STATE.md
#   bash scripts/state.sh phase P2              切换阶段
#   bash scripts/state.sh sign P1 "用户确认原话"  记录门禁签字
#   bash scripts/state.sh next "第一步|第二步"    更新下一步

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
STATE=STATE.md

now() { date '+%Y-%m-%d %H:%M'; }

case "${1:-show}" in

  show)
    [ -f "$STATE" ] && cat "$STATE" || echo "STATE.md 不存在，请先运行: bash scripts/state.sh init"
    ;;

  init)
    if [ -f "$STATE" ]; then
      echo "STATE.md 已存在，未覆盖。如需重建请先手动删除。"
      exit 1
    fi
    cat > "$STATE" <<'EOF'
# STATE

- 项目：<填写项目名>
- 类型：<Web 前端 / 后端服务 / 数据脚本 / 库 SDK>
- 技术栈：<语言 + 框架 + 数据库>
- **当前阶段：P0 立项**
- 当前迭代：初始化

## 已完成

- （无）

## 进行中

- P0 立项：待填 AGENTS.md 项目信息、建 .venv、初始化 git

## 下一步

1. 与用户确认技术栈与项目类型
2. make setup 建环境
3. 填 docs/INDEX.md
4. 过 P0 门禁 → 进 P1

## 门禁签字

- （暂无）

## 最近决策

- （暂无）

## 已知限制

- （暂无）

## 豁免记录

- （暂无）
EOF
    echo "已创建 STATE.md"
    ;;

  phase)
    NEW="${2:-}"
    [[ "$NEW" =~ ^S[1-8]$ ]] || { echo "用法: bash scripts/state.sh phase S1..S8"; exit 1; }
    [ -f "$STATE" ] || { echo "STATE.md 不存在"; exit 1; }

    CUR="$(grep -oE '当前阶段：\*{0,2}[SP][0-9.]+' "$STATE" | grep -oE '[SP][0-9.]+' | head -1)"
    CUR="${CUR:-S1}"

    ord() {
      case "$1" in
        S1) echo 1;; S2) echo 2;; S3) echo 3;; S4) echo 4;;
        S5) echo 5;; S6) echo 6;; S7) echo 7;; S8) echo 8;;
        # 兼容旧 STATE 中残留的旧编号（只在读取时归一，不再写入）
        P0|P05) echo 1;; P1) echo 2;; P2) echo 3;; P3) echo 4;;
        P4) echo 5;; P5) echo 6;; P6) echo 7;; P7) echo 8;; *) echo 99;;
      esac
    }
    CUR_N=$(ord "$CUR"); NEW_N=$(ord "$NEW")

    if [ "${FORCE:-0}" != "1" ]; then
      if [ "$NEW_N" -gt $((CUR_N + 1)) ]; then
        echo "✗ 拒绝跳步：当前 $CUR，不能直接跳到 $NEW。"
        echo "  铁律一：阶段不可跳。必须先逐级通过 ${CUR} 的出口门禁。"
        echo "  确需豁免：FORCE=1 bash scripts/state.sh phase $NEW"
        exit 1
      fi
      if [ "$NEW_N" -lt "$CUR_N" ]; then
        echo "↩ 回退到 $NEW（这是正常流程，不是失败）"
      fi
      if [ "$NEW_N" -eq $((CUR_N + 1)) ]; then
        echo "→ $CUR → $NEW，检查 $CUR 出口门禁..."
        if ! bash scripts/gate.sh "$CUR" > /tmp/aegis_gate.$$ 2>&1; then
          grep -E '✗|FAIL' /tmp/aegis_gate.$$ | head -10
          rm -f /tmp/aegis_gate.$$
          echo ""
          echo "✗ 门禁未通过，禁止进入 $NEW。"
          echo "  确需豁免：FORCE=1 bash scripts/state.sh phase $NEW"
          exit 1
        fi
        grep -E 'PASS' /tmp/aegis_gate.$$ | tail -1
        rm -f /tmp/aegis_gate.$$
      fi
    else
      printf -- "- %s 强制从 %s 切换到 %s（用户豁免）\n" "$(now)" "$CUR" "$NEW" >> "$STATE"
      echo "⚠ 已强制切换 $CUR → $NEW，豁免已记录"
    fi

    DISPLAY="$NEW"
    python3 - "$STATE" "$DISPLAY" <<'PY'
import sys, re, pathlib
p, new = pathlib.Path(sys.argv[1]), sys.argv[2]
t = p.read_text(encoding='utf-8')
# 保留原有的加粗包裹：`- **当前阶段：P0 立项**` 这种行要维持 ** 成对
def repl(m):
    line = m.group(0)
    bold = line.startswith('**') or line.startswith('- **')
    head = ''
    if bold:
        head = '**' if line.startswith('**') else '- **'
        return f"{head}当前阶段：{new}**"
    return f"当前阶段：{new}"
t = re.sub(r'(?:- )?\*{0,2}当前阶段：\*{0,2}[SP][0-9.]+[^\n]*', repl, t, count=1)
p.write_text(t, encoding='utf-8')
PY
    echo "已切换阶段 → $DISPLAY（记得更新「下一步」）"
    ;;

  sign)
    GATE="${2:-}"
    NOTE="${3:-用户确认}"
    [ -n "$GATE" ] || { echo "用法: bash scripts/state.sh sign P1 \"用户原话\""; exit 1; }
    [ -f "$STATE" ] || { echo "STATE.md 不存在"; exit 1; }
    LINE="- $GATE 确认：$(now) 用户确认 ✅「$NOTE」"
    python3 - "$STATE" "$LINE" <<'PY'
import sys, re, pathlib
p, line = pathlib.Path(sys.argv[1]), sys.argv[2]
text = p.read_text(encoding='utf-8')
# 在「## 门禁签字」小节内追加
m = re.search(r'(## 门禁签字\s*\n)([\s\S]*?)(?=\n## |\Z)', text)
if m:
    body = m.group(2).replace('- （暂无）', '').rstrip()
    new_body = (body + "\n" if body else "") + line + "\n"
    text = text[:m.start(2)] + new_body + text[m.end(2):]
else:
    text += "\n## 门禁签字\n\n" + line + "\n"
p.write_text(text, encoding='utf-8')
print("已记录签字: " + line)
PY
    ;;

  next)
    NEW="${2:-}"
    [ -n "$NEW" ] || { echo "用法: bash scripts/state.sh next \"步骤1|步骤2\""; exit 1; }
    [ -f "$STATE" ] || { echo "STATE.md 不存在"; exit 1; }
    python3 - "$STATE" "$NEW" <<'PY'
import sys, re, pathlib
p, new = pathlib.Path(sys.argv[1]), sys.argv[2]
text = p.read_text(encoding='utf-8')
items = [x.strip() for x in new.split('|') if x.strip()]
block = "## 下一步\n\n" + "\n".join(f"{i+1}. {x}" for i, x in enumerate(items)) + "\n"
if re.search(r'^## 下一步\s*$', text, re.M):
    text = re.sub(r'## 下一步[\s\S]*?(?=^## |\Z)', block + "\n", text, flags=re.M)
else:
    text += "\n" + block
p.write_text(text, encoding='utf-8')
print("已更新「下一步」")
PY
    ;;

  *)
    echo "用法: bash scripts/state.sh [show|init|phase Pn|sign Pn \"原话\"|next \"a|b\"]"
    exit 1
    ;;
esac
