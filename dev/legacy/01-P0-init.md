# 01 · P0 立项（Init）

> 状态：已作废（2026-10-21，八阶段定稿 H-0022 落地中）→ 由八阶段新文档「S1 立题 + S4 展开（环境/技术栈）」取代；本文件仅回溯可读，使用过程禁止引用

> 目的：建立项目宪法与环境契约。让后续所有会话有一个稳定的地基。

---

## 输入

- 用户的项目意图（哪怕一句话）
- 项目类型与大致规模

---

## 动作清单

### 1. 澄清基本要素（必须问用户，不可假设）

| 要问的 | 为什么必须问 |
|---|---|
| 项目类型（Web / 后端 / 数据脚本 / 库） | 决定哪些阶段门禁是硬性 |
| 技术栈（语言 / 框架 / 数据库） | 属于「方案性问题」，agent 无权决定 |
| 运行环境（本机 / 容器 / 服务器） | 决定 setup 脚本 |
| 是否已有代码库 | 决定是新建还是接入 |

> ⚠️ 这一条常被跳过。跳过 = 后续所有阶段都建立在猜测上。

### 2. 建立宪法

- 写 `AGENTS.md`（入口，保持精简）
- 建立 `.ai/` 目录并填写 `90-preferences.md`
- 确认 `.ai/00-core.md` 五条铁律适用（如需调整，明确记录）

### 3. 建立环境契约

**Python 项目：**
```bash
python3 -m venv .venv
.venv/bin/pip install -U pip
cat > pyproject.toml <<'EOF'
[project]
name = "<项目名>"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = []
EOF
```

**Node 项目：**
```bash
pnpm init
```

**Makefile 必须提供 `setup` 目标**，保证一条命令重建环境。

### 4. 建立仓库与状态

```bash
git init
printf '.venv/\n__pycache__/\n*.pyc\nnode_modules/\n.tmp/\n' > .gitignore
```

- 写 `STATE.md`（用 `scripts/state.sh init`）
- 建 `docs/INDEX.md`（用模板）

---

## 必备制品

| 制品 | 路径 | 要求 |
|---|---|---|
| 入口 | `AGENTS.md` | 存在，含指针与冲突仲裁 |
| 规范 | `.ai/` | 至少含 `00-core.md`、`90-preferences.md` |
| 状态 | `STATE.md` | 填了项目名、类型、技术栈、当前阶段 P0 |
| 环境 | `.venv/` | Python 项目必须存在 |
| 依赖 | `pyproject.toml` 或 `package.json` | 存在 |
| 索引 | `docs/INDEX.md` | 存在 |
| 构建 | `Makefile` | 含 `setup` 目标 |
| 忽略 | `.gitignore` | 含 `.venv/` 等 |

---

## 出口门禁

- [ ] `make setup` 能一条命令重建环境并成功
- [ ] `bash scripts/gate.sh P0` 输出 PASS
- [ ] `STATE.md` 中阶段字段 = `P0`，且已列出技术栈
- [ ] 用户已确认技术栈与项目类型

---

## 人工确认

✅ **必须**。确认内容：技术栈、项目类型、环境方案。

在 `STATE.md` 的「门禁签字」区记录：
```
- P0 环境确认：<日期> 用户确认 ✅
```

---

## 常见失误

| 失误 | 后果 | 纠正 |
|---|---|---|
| 不建 venv，直接用系统 Python | 依赖污染、不可复现 | 硬性要求，脚本检查 |
| 不写 STATE.md | 新会话无法快速定位 | P0 出口必备 |
| 技术栈自己拍板 | 后续全推倒 | 属方案性问题，必须问 |
| AGENTS.md 写成万字长文 | 每次会话烧 token | 保持 20 行精华 + 指针 |
