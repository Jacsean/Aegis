# CHANGELOG

格式遵循语义化版本。每条写清「新增 / 变更 / 修复 / 移除 / 未进版」。

---

## [1.0.0] - 2026-10-20

**第一个原型版本（Prototype）。** 只固化「已实现且已实测通过」的部分。
仅讨论过、未落地的提案一律列在文末「未进版」，不参与本版本。

### 新增

**阶段规范（`.ai/`，11 份）**
- `00-core.md`：三轴模型（阶段轴 / 制品轴 / 门禁轴）、六条铁律 + 分支铁律、会话启动协议、冲突仲裁
- `01-P0-init.md`：立项（项目类型 / 技术栈 / 环境 / 已有代码四问；建 `.venv`、`pyproject.toml`、`Makefile`、`docs/INDEX.md`）
- `015-P05-align.md`：意图校准（两轮不可合并、checklist 前置、选项式、小白语言、R1/R2/R3 模板、出口门禁）
- `02-P1-ideate.md` ～ `08-P7-deliver.md`：构思 / 设计 / 验证 / 实现 / 校验 / 归档 / 交付
- `90-preferences.md`：沟通风格、讨论方式、技术词规则、决策权归属、明确不做的事

**参考规范（`.ai/99-reference/`，7 份）**
- `prd-schema.md`、`align-schema.md`、`checklist-schema.md`、`incident-schema.md`、`state-schema.md`、`adr-schema.md`、`design-review-checklist.md`
- `checklist-schema.md` 含：选项式规范、为什么用选项式、两条原则、单条最小结构四要素、6 条选项设计规则、完整示例、技术词黑名单、自检清单

**Skills（`.skills/`，9 个，Superpowers 格式）**
- `aegis-state`、`aegis-align`、`aegis-p1-ideate` ～ `aegis-p7-deliver`
- 全部通过 frontmatter 校验（name 正则 / description <500 字符 / frontmatter ≤1024 字符 / 以 "Use when" 开头）

**脚本（`scripts/`，4 个）**
- `gate.sh`：8 个阶段出口门禁 + 框架自检模式
  - P0：AGENTS/.ai/STATE/INDEX/.venv/Makefile/.gitignore
  - P05：两轮 checklist 条目数（≥5 / ≥6）、技术词黑名单、每条含「其他」、A/B/C 三方向、汇总四节 + 签字
  - P1：PRD 六节、非目标非占位符
  - P2：DESIGN / STYLE / demo 自包含 / demo 5 态 / ADR / 签字
  - P3：12 项评审清单
  - P4：`.venv`、测试文件、调试残留、TODO/FIXME、硬编码密钥、INC「预防」
  - P5：当日代码评审记录 + 用户签字
  - P6：STATE ≤40 行、下一步可执行、CHANGELOG 版本条目、无模糊表述、INDEX 完整性、tag 与版本一致
  - P7：RELEASE 五节、已知限制非「无」、验证证据非空话、用户签收
  - FRAME（`AEGIS_SELF=1`）：VERSION、11 份规范、7 份 schema、适配壳、9 份模板、4 个脚本语法
- `state.sh`：`show / init / phase / sign / next`；阶段序号映射（P0=0、P05=1 … P7=8）、拒绝跳步、回退提示、前进自动跑门禁、`FORCE=1` 记豁免
- `branch.sh`：`start / list / status / finish / check`；7 种类型、要求工作区干净、从 main 拉、合并前自动跑门禁
- `sync.sh`：`EXPECTED_SKILLS` 9 项 + 反向检查未登记 skill、frontmatter 校验、生成 `adapters/` 壳、软链自愈

**模板（`templates/docs/`，9 份）**
- `INDEX.md`、`prd.md`、`design/DESIGN.md`、`design/STYLE.md`、`design/REVIEW-DESIGN.md`、`adr/ADR-0001-template.md`、`incidents/INC-0001-template.md`、`release/RELEASE-template.md`、`reviews/REVIEW-CODE-template.md`、`align/README.md`

**样例（`examples/`）**
- `align/`：CHECKLIST / ALIGN 两轮真实样例（5 份）
- `design/demo/01-task-list.html`：可交互、自包含、覆盖 5 态的 demo 范例

**适配壳（`adapters/`）**
- `cursor/rules.mdc`、`trae/rules.md`、`codex/AGENTS.md`
- `claude-code/`、`reasonix/`、`deepseek/`、`generic/`：各一份接入说明（这几个 agent 直接读 `AGENTS.md`，无额外文件）
- `adapters/README.md`：总表 + 新增一个 agent 适配的 4 步

**其它**
- `VERSION`：版本号唯一来源
- `archive/`（scripts / fixtures / releases）+ 归档规则
- `out/VERSION-INDEX.md`：交付物索引

### 变更

- **目录结构重排**：
  - 原平铺的 `docs/` 拆成三块：`templates/docs/`（模板）、`examples/`（样例）、用户项目自己的 `docs/`（运行时产物）
  - 原 `.harness/` 改名为 `adapters/`，语义从「派生物壳」改为「各 agent 接入方式」，并补 README 说明每个文件装到哪
  - 框架本体不再带 `src/`、`tests/`、`docs/`（那些是用户项目的东西）
- `gate.sh` 引入工作根定位（`AEGIS_WORK_ROOT` → 向上找 `.ai/00-core.md` → 脚本上一级），并区分两种模式：
  - 用户项目模式：`DOCS=docs`、`CODE=src`，跑 BRANCH 检查
  - 框架自检模式：`DOCS=templates/docs`、`CODE=scripts`，跑 FRAME 检查，跳过 BRANCH
- `sync.sh` 输出目标从 `.harness/` 改为 `adapters/`；删掉重复维护的 `.harness/README.md` 生成块
- `Makefile` 的 `demo` 目标同时支持 `docs/design/demo` 与 `examples/design/demo`
- `README.md` 目录结构重写为三节：框架本体 / 装到项目后 / 交付物在哪
- **`README.md` Token 数据按实测修正**：原写「~800 tokens / 降 90%」是错的；实测启动四件套 ≈5900 tokens，进 P0.5 约 10200，`.ai/` 全量约 23400
- `AGENTS.md`、`.ai/00-core.md` 的「`.harness/` 是派生物」改为「`adapters/` 是派生物」

### 修复

- `gate.sh` P6 的 INDEX 检查原按文件名精确匹配，会把目录级登记（`align/`、`adr/`）误判为未登记 → 文件名或所在目录任一命中即通过
- `gate.sh` P7「已知限制」剥掉 `<...>` 占位符后残留空行被当成有效内容 → 先剥列表符再做空行过滤
- `gate.sh` P4 的 INC「预防」检查把模板说明句「至少选一项」当成内容 → 补说明行过滤
- `gate.sh` P7 `find -name 'RELEASE-v*.md'` 误匹配 `RELEASE-template.md` → 改为 `'RELEASE-v[0-9]*.md'`
- `state.sh` 切换阶段后残留旧的「P1 立项」描述 → 改为整行精确替换
- `state.sh sign` 原把签字追加到「豁免记录」小节 → 改为在「门禁签字」内插入
- 主分支默认名只认 `main` → 兼容 `master`
- `gate.sh` P05 条目统计对 `## 1.` 标题式失效、`## A1.` 只数到 2 条 → 正则改为 `([A-Z]?[0-9]+)`
- 只给 A/B 两个选项未拦截 → 增加 C 检查
- STATE.md 阶段行出现 `- ****当前阶段` 星号叠加 → 改逐行精确替换
- `state.sh phase` 切换后写成 `- **当前阶段：P0.5`（缺收尾 `**`）→ 改为保留原有加粗包裹
- `gate.sh` P05 在 main/master 上把分支名 `master` 当成任务短名 → 改为 `[类型]/[短名]` 匹配优先，其次从 `docs/align/` 现有文件推断，都不行才报错
- `branch.sh start` 因「工作区必须干净」与阶段切换必然改动 `STATE.md` 冲突，导致流程卡死 → 改为「仅 `STATE.md` 有改动时自动提交，混有其他改动仍拒绝」

### 移除

- `docs/`（框架内自带的文档目录）——已拆到 `templates/docs/` 与 `examples/`
- `.harness/`——改名为 `adapters/`
- 框架内的空 `src/`、`tests/`、`docs-template/` 误建目录

### 未进版（已讨论，未实现，留待 1.1+）

以下内容**不在** 1.0.0 内，列在此处保证不丢：

1. **8 阶段骨架替换 9 阶段**（S1 立题 → S2 对齐 → S3 收敛 → S4 展开 → S5 找破绽 → S6 实现 → S7 固化 → S8 交付）
2. **「探明」入口分诊**（加功能 / 重构 / 排查 / 决策四种前置动作）
3. **思维模式层**（6 组模式：反向思考、前提显式化、减法优先、显式权衡、反证、复盘归因，嵌进各阶段做必答问题）
4. **两类场景分支**（无到有 4 阶段 / 有到强 5 阶段，含「结合判断」）
5. **checklist 七维框架落地**（当前六维骨架已实现；第七维「参考同行」的调研前置流程、主副维标注、去重防漂移三机制尚未写进 `.ai/015-P05-align.md`）
6. **包结构**（`plugin.json` + `install.sh`）
7. **Superpowers 融合包**（`vendor/` 内联 + `VENDOR.md` + `sync-upstream.sh`）
8. **原型阶段允许不完整**（当前 9 阶段对 3 天原型要求过重）

---

## [0.1.0] - 2026-10-13

### 新增
- 项目骨架、`.ai/` 规范库前 6 份（P0 / P0.5 / P1 / P2 + core + preferences）、`.skills/` 前 4 个 skill、门禁脚本 P0–P2 段
