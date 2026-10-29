# Aegis — 工程流程系统
# 用法: make help

SHELL := /bin/bash
PY    := .venv/bin/python
PIP   := .venv/bin/pip

.PHONY: help setup gate status sync check-sync deliver gate-s1 gate-s2 gate-s3 gate-s4 gate-s5 gate-s6 gate-s7 gate-s8 phase sign next demo clean branch br-status br-check branch-finish

help:
	@echo "Aegis 常用命令"
	@echo ""
	@echo "  —— 分支（每任务必须独立分支）——"
	@echo "  make branch NAME=user-login   新建任务分支 feat/user-login"
	@echo "  make br-status               当前分支状态"
	@echo "  make br-check                检查分支命名是否合规"
	@echo "  make branch-finish NAME=x    合并回主分支并清理"
	@echo ""
	@echo "  —— 环境与流程 ——"
	@echo "  make setup            重建环境（venv + 依赖）"
	@echo "  make gate             检查当前阶段门禁"
	@echo "  make gate S2          检查指定阶段（S1..S8）"
	@echo "  make status           查看状态快照 STATE.md"
	@echo "  make phase S3         切换阶段（会自动跑门禁）"
	@echo "  make sign S2 \"原话\"    记录门禁签字"
	@echo "  make next \"a|b\"       更新下一步"
	@echo "  make sync             同步 .ai/ 派生物（.skills/ + adapters/）"
	@echo "  make check-sync       只检查是否需同步"
	@echo "  make deliver V=1.6.0  打使用者维度交付包（剔除 dev/）"
	@echo "  make demo             打开第一个 HTML demo"
	@echo ""

# ---------- 分支 ----------
branch:
	@if [ -z "$(NAME)" ]; then echo "用法: make branch NAME=任务短名 [TYPE=feat]"; exit 1; fi
	@bash scripts/branch.sh start "$(NAME)" "$(or $(TYPE),feat)"

br-status:
	@bash scripts/branch.sh status

br-check:
	@bash scripts/branch.sh check

branch-finish:
	@if [ -z "$(NAME)" ]; then echo "用法: make branch-finish NAME=任务短名"; exit 1; fi
	@bash scripts/branch.sh finish "$(NAME)"

# ---------- 环境 ----------
setup:
	@echo "==> 建立 Python 虚拟环境"
	@if [ ! -d .venv ]; then python3 -m venv .venv; fi
	@$(PIP) install -q -U pip
	@if [ -f requirements.txt ]; then $(PIP) install -q -r requirements.txt; fi
	@if [ -f pyproject.toml ]; then $(PIP) install -q -e . 2>/dev/null || true; fi
	@echo "==> 完成。Python: $$($(PY) --version)"

# ---------- 门禁 ----------
gate:
	@if [ -n "$(filter S%,$(MAKECMDGOALS))" ]; then \
		bash scripts/gate.sh $(filter S%,$(MAKECMDGOALS)); \
	else \
		bash scripts/gate.sh; \
	fi

S1 S2 S3 S4 S5 S6 S7 S8:
	@:

# ---------- 状态 ----------
status:
	@bash scripts/state.sh show

phase:
	@bash scripts/state.sh phase $(P)

sign:
	@bash scripts/state.sh sign $(P) "$(M)"

next:
	@bash scripts/state.sh next "$(M)"

# ---------- 同步 ----------
sync:
	@bash scripts/sync.sh

check-sync:
	@bash scripts/sync.sh --check

deliver:
	@bash scripts/deliver.sh $(V)

# ---------- 其他 ----------
demo:
	@f=$$(find docs/design/demo examples/design/demo -maxdepth 1 -name '*.html' 2>/dev/null | sort | head -1); \
	if [ -n "$$f" ]; then echo "打开: $$f"; \
		(command -v xdg-open >/dev/null && xdg-open "$$f") || \
		(command -v open >/dev/null && open "$$f") || \
		echo "请手动用浏览器打开: $$f"; \
	else echo "暂无 demo（P2 阶段需要创建）"; fi

clean:
	@rm -rf .tmp __pycache__ .pytest_cache
	@find . -name '*.pyc' -not -path './.venv/*' -delete
	@echo "已清理临时文件"

# ---------- 八阶段门禁别名（v2.0.0） ----------
gate-s1: ; @bash scripts/gate.sh S1
gate-s2: ; @bash scripts/gate.sh S2
gate-s3: ; @bash scripts/gate.sh S3
gate-s4: ; @bash scripts/gate.sh S4
gate-s5: ; @bash scripts/gate.sh S5
gate-s6: ; @bash scripts/gate.sh S6
gate-s7: ; @bash scripts/gate.sh S7
gate-s8: ; @bash scripts/gate.sh S8
