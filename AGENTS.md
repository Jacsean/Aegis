# AGENTS.md

> 本项目所有 AI agent 的唯一入口。**任何会话开始前必读本文件。**
> 详细规范在 `.ai/`，按当前阶段按需加载，不要一次全读。
> 本套方案代号：**Aegis** — 状态机 + 制品 + 门禁。

---

## 会话启动协议（按序执行，约 1050 tokens）

1. 读 **本文件**
2. 读 **`STATE.md`** — 当前阶段、已完成、下一步
3. 读 **`.ai/00-core.md`** — 六条铁律
4. 读 **`.ai/90-preferences.md`** — 用户偏好
5. 读 **`docs/develop/CONCEPTS.md` 的「目录」一节** — 只读一句话列，约 200 tokens；遇到生词再按锚点跳条目
6. 按 `STATE.md` 的当前阶段，加载 `.ai/0X-Pn-*.md`
7. 声明：**「当前阶段 Pn，本次目标 X，已加载文件 Y」**，再动手

> **为什么第 5 步不能省**：会话一结束上下文就没了。概念表是唯一能跨会话传递「这些词在这里是什么意思」的地方，
> 不读它，下一轮就会把「地点」又理解成「文件存在哪」。规则见 `docs/develop/CONCEPTS.md`。

---

## 六条铁律（摘要，全文见 `.ai/00-core.md`）

1. **阶段不可跳** — 未过出口门禁，禁止进下一阶段
2. **设计前必须可视** — 前端项目没出 HTML demo 并获得确认，禁止写业务代码
3. **完成必须留证** — 说"完成"必须贴验证输出，"应该可以"不算
4. **问题必须沉淀** — 调试超 15 分钟或试错 2 次以上，必须建 `docs/incidents/INC-*.md`，且必须填「预防」
5. **单一真相源** — `.ai/` 是唯一真相，`.skills/` 与 `adapters/` 是派生物，禁止手工维护两份
6. **讨论前置** — 新要求禁止直接给方案。必须先走 P0.5 两轮讨论，每轮先建**选项式** checklist（每条必须含「其他___」），用日常语言，结论落文档
7. **分支隔离** — 每个新任务必须建独立分支，禁止在 main 上直接改

---

## 讨论形式（铁律六的落地要求）

每个关键点由 agent 提供**上下文（从哪来 / 不问会怎样 / 你该怎么判断）+ 3-4 个理解方向 + 「其他」兜底**，用户只做选择。

两条原则：
1. 先给描述或标准，用户据此回复
2. 列出可能的理解偏差，用户指认正确方向

**禁止**：开放式提问（"你想怎么处理"）、选项里没有「其他」、只给 2 个选项。

---

## 八阶段状态机（含 P0.5）

```
P0 立项 → P0.5 意图校准 → P1 构思 → P2 设计 → P3 验证 → P4 实现 → P5 校验 → P6 归档 → P7 交付
```

| 阶段 | 加载文件 | 人工签字 |
|---|---|---|
| P0 立项 | `.ai/01-P0-init.md` | ✅ |
| **P0.5 意图校准** | **`.ai/015-P05-align.md` + `99-reference/align-schema.md` + `checklist-schema.md`** | ✅ **强制** |
| P1 构思 | `.ai/02-P1-ideate.md` | ✅ 强制 |
| P2 设计 | `.ai/03-P2-design.md` | ✅ 强制（看 demo 后）|
| P3 验证 | `.ai/04-P3-validate.md` + `99-reference/design-review-checklist.md` | ⚠️ 建议 |
| P4 实现 | `.ai/05-P4-implement.md` | ❌ |
| P5 校验 | `.ai/06-P5-verify.md` | ✅ 强制 |
| P6 归档 | `.ai/07-P6-archive.md` + `99-reference/state-schema.md` | ❌ |
| P7 交付 | `.ai/08-P7-deliver.md` | ✅ 强制 |

**一句话记住每个阶段在防什么：**

| 阶段 | 防的失控 |
|---|---|
| P0.5 | 没搞清要什么就动手 |
| P1 | 需求范围悄悄膨胀 |
| P2 | 前端风格全靠猜 |
| P3 | 带缺陷进实现 |
| P4 | 没测试就宣称做完 / 坑不记录 |
| P5 | 老毛病复发 |
| P6 | 下个会话从零读全部文档 |
| P7 | 交付了但别人用不了 |

---

## 分支规则（每个任务必做）

```bash
make branch NAME=user-login      # 建 feat/user-login
# ... 走 P0.5 → P7 ...
make branch-finish NAME=user-login   # 过门禁 → 合并 → 清理
```

| 类型 | 用途 |
|---|---|
| `feat/` | 新功能 |
| `fix/` | 修问题 |
| `docs/` | 文档改动 |
| `refactor/` `test/` `chore/` `spike/` | 其他 |

**禁止**在 main/master 上直接改动 —— `gate.sh` 会拦截。

---

## 制品位置（不许乱放）

```
docs/align/CHECKLIST-<任务>-R1.md / R2.md   两轮讨论清单（P0.5）
docs/align/ALIGN-<任务>-R1.md / R2.md       两轮讨论记录（P0.5）
docs/align/ALIGN-<任务>.md                   意图校准结论（P0.5）⭐
docs/prd.md                    需求（P1）
docs/design/DESIGN.md          设计主文档（P2）
docs/design/STYLE.md           样式与交互规范（P2）
docs/design/demo/*.html        HTML demo（P2，前端必需）
docs/design/REVIEW-DESIGN.md   设计评审（P3）
docs/adr/ADR-*.md              架构决策（P2）
src/  tests/                   源码与测试（P4）
docs/incidents/INC-*.md        故障与问题库（P4/P5，预防必填）
docs/reviews/REVIEW-CODE-*.md  代码评审（P5，三轮）
archive/                       一次性脚本 / 大体积数据 / 旧交付说明（P6）
CHANGELOG.md                   变更日志（P6）
docs/release/RELEASE-*.md      交付说明（P7）
docs/develop/CONCEPTS.md       全局概念表（唯一概念定义处，改词只改这里）
docs/develop/HANDOFF.md        开发事件索引（始终，一行一条，时间倒序）
docs/develop/handoff/H-*.md    开发事件记录（每个任务结束必写，七要素）
docs/public/                   交付文档（给项目使用者看的，与开发文档分开）
STATE.md                       状态快照（始终，≤40 行）
docs/INDEX.md                  文档总索引（始终）
```

---

## 冲突仲裁

```
1. 用户当前明确指令
2. 00-core.md 六条铁律
3. 当前阶段 .ai/0X-*.md
4. 90-preferences.md
5. 通用方法论框架（Superpowers 等）
6. agent 默认行为
```

无法判断时：**向用户指出冲突，不自行裁决。**

---

## 常用命令

```bash
make setup                       # 重建环境
make branch NAME=<任务短名>       # 建任务分支
make gate                        # 检查当前阶段门禁
make gate P05                    # 检查指定阶段
make status                      # 查看状态快照
make phase P05                   # 切换阶段（自动检查门禁）
make sign P05 "原话"              # 记录签字
make branch-finish NAME=<短名>    # 合并回主分支
make sync                        # .ai/ 同步到 .skills/ 与 adapters/
```
