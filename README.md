# Aegis — 工程流程系统

> 一套以**状态机为骨架、以制品为中心、以门禁为强制力**的 AI agent 项目开发规范。
> 解决"通用方法论框架（如 Superpowers）在真实项目中失控"的问题。

---

## 一、它解决什么问题

通用 skills 框架的问题是：**它只有横向的技能集合，没有纵向的工程状态机**。
所以 agent 可以在任意时刻跳步、自作主张、不存档、不沉淀经验。

Aegis 针对 8 类具体失控现象设计：

| 现象 | Aegis 的解法 |
|---|---|
| 没 review 就自作主张生成方案 | S3/S4 出口有**人工签字门禁**，未签状态机停在原地 |
| 前端不给 demo 直接写代码 | S4 **必备制品**含 `demo/*.html`，缺则 S6 无法开始 |
| 文档随意生成、无关联 | 文档 schema 固定 + `docs/INDEX.md` 强制登记（S7 机检反查） |
| 阶段成果不固化 | `STATE.md` 快照（≤40 行，S7 机检行数），新会话 30 秒接上 |
| Python 不建 venv | S1 / S6 门禁由 `gate.sh` 硬检查 |
| 故障不记录、老毛病复发 | `docs/incidents/`（**预防**必填机检）+ S5/S5 两处**历史缺陷回灌** |
| 设计完不 review | **S5 独立阶段**，12 项评审清单 + 意图一致性复核 |
| 规则叠加烧 token | 分阶段按需加载 + 单一真相源派生物化 |
| **一上来就给方案，没讨论** | **S2 意图校准：两轮讨论 + checklist 前置** |
| **checklist 全是技术黑话** | **小白语言规则 + `gate.sh` 关键词黑名单** |
| **多任务混在一个分支** | **分支铁律 + `branch.sh` + 门禁检查** |
| **交付了但别人用不了** | **S8 强制冒烟验证，`RELEASE` 的「已知限制」写「无」会被拦** |

---

## 二、三轴模型

```
轴一 阶段：S1 立项 → S2 意图校准 → S3 构思 → S4 设计 → S5 验证 → S6 实现 → S5 校验 → S7 归档 → S8 交付
轴二 制品：每阶段有且仅有规定的产物，固定路径 + 固定 schema + 必须登记索引
轴三 门禁：每阶段出口有 Exit Criteria，不满足则状态机拒绝前进
```

---

## 三、六条铁律 + 分支铁律

1. **阶段不可跳** — 未过出口门禁，禁止进下一阶段
2. **设计前必须可视** — 前端没出 HTML demo 并确认，禁止写业务代码
3. **完成必须留证** — 说"完成"必须贴验证输出
4. **问题必须沉淀** — 调试超 15 分钟或试错 2 次以上，必须建 INC 且填「预防」
5. **单一真相源** — `.ai/` 是唯一真相，其余是派生物
6. **讨论前置** — 新要求禁止直接给方案，必须先走 S2 两轮讨论，每轮先建 checklist，用日常语言
7. **分支隔离** — 每个新任务必须建独立分支，禁止直接改 main

---

## 三之一、S2 意图校准（新增）

插在 S1 与 S3 之间的独立阶段。**它不是 S3 的一部分**，因为讨论发生在写需求之前。

| 轮次 | 目的 | 强制 |
|---|---|---|
| R1 复述轮 | 用大白话复述你的要求，你纠正 | 不可跳 |
| R2 深层轮 | 挖"为什么 / 什么算失败 / 什么情况例外" | 不可跳 |
| R3 边界轮 | 只在前两轮发现重大歧义时触发 | 条件 |

**每轮动作**：先写 checklist → 你确认清单本身 → 逐条选择 → 落 `ALIGN` 记录。

**选项式（核心形式）**：每条关键点由 agent 给出「从哪来 + 不问会怎样 + 你该怎么判断 +
3-4 个理解方向 + 其他兜底」，你只做选择。你的工作从"表达"降为"识别"。

```markdown
## 2. 你想解决的是这个麻烦吗？

**从哪来：** 你说「返工太多次」，我判断真正的麻烦在这里。
**不问会怎样：** 麻烦判断错了，方案会解决一个你其实不在意的问题。
**你该怎么判断：** 回想最近一次因为这件事烦的时候，烦的到底是什么。
> 依据：[推荐] 返工多源于"需求没对齐"（无出处，基于常见复盘）

**我可能理解错的地方：**
- A. 主要是返工太多次 → 后果：重点放在"一次做对"
- B. 更难受的是反复解释同一件事 → 后果：重点放在"结论沉淀"
- C. 不是，真正的麻烦是别的 → 后果：请说明
- D. 其他：_______________        ← 必须有
**我的倾向：** B
```

**五元素（按需取用，不求全）**：

| 元素 | 回答你的什么问题 | 省了会怎样 |
|---|---|---|
| **从哪来** | 这话是从我哪句说的 | 代入不进去，只能按字面选 |
| **不问会怎样** | 不回答会出什么事 | 不知道为什么值得答 |
| **你该怎么判断** | 我凭什么选 | 不知道从哪下手 |
| **选项 + 后果** | 每种选法的结果 | 只能凭感觉 |
| **我可能根本没问对** | 允许推翻整个问题 | 在错误框架里回答，越答越偏 |

判断标准是**你判断错的代价**，不是问题大小。可省，但要在文中写明为什么省——
`gate.sh` 会检查「从哪来」的覆盖数，一条都没有直接 FAIL。

两条必须遵守的原则：
1. **先给上下文或判断标准**，你据此回复
2. **列出可能的理解偏差**，你指认正确方向

**禁止**：开放式提问、选项缺「其他」、只给 2 个选项。`gate.sh` 会机检这三项。

**小白语言硬规则**：每条 checklist 必须让你在不需要技术知识的前提下回答。
`gate.sh` 内置技术词黑名单（API / 鉴权 / 缓存 / 事务 / 并发 …），出现即 FAIL。

**讨论结论**落 `docs/align/ALIGN-<任务>.md`，是 S3 写 PRD 的**唯一依据**。

---

## 三之三、第七维「参考同行」（v1.1.0 新增）

**为什么要有这一维**：agent 给 3 个选项，你以为选完了，其实漏了第 4 个真实存在的方向。

真实例子：做本地优先笔记应用，agent 给「纯本地 / 纯云端 / 本地+云同步」三个选项。
但市面上还有第四种——**CRDT 本地优先 + 设备间 P2P 直连**（Obsidian、Logseq、Actual Budget 都在用）。
你选了「本地+云」，做了两个月才发现有更合适的路。

**漏方向比编来源更隐蔽**：编来源你能查，漏方向你查不到。

### 顺序：先调研，再列清单

```
判定领域 → 征询你要不要查 → 调研 → 生成清单
```

不许先问一堆问题再去调研（方向已偏，白花 token）。不许不征询就烧 token 搜。

### 四级标注（降级链，不许跳级）

| 标记 | 含义 | 例子 |
|---|---|---|
| `[检索]` | 有出处的同行经验 | `[检索] 少数派 2025-03 八款笔记横评 —— 7 款默认本地` |
| `[推荐]` | 无出处的倾向 | `[推荐] 单人起步倾向纯本地（无出处）` |
| `[无参照]` | 既无事实也无倾向 | `[无参照] 未找到公开资料，以下为推断` |
| `[未覆盖]` | 知道有但没列入选项 | 写进末尾「未覆盖方向」一节 |

**允许混用**：同一关键点一部分 `[检索]`、一部分 `[推荐]`——你正需要知道哪部分是硬的。

### 没有联网能力时（顺序不可调换）

1. **先告知**：「我这边没有联网，拿不到专业文献。」
2. **再问**：「要不要我用训练数据里的印象给你参照？（无出处，可能过时）还是这次不需要同行经验？」
3. 你同意才用 `[推荐]`，**禁止**伪装成 `[检索]`
4. 你不需要 → 全用 `[无参照]`

**绝对禁止三种写法**：

- 没查却说「我查到了」——这是欺骗，不是失误
- 给 3 个选项不说「还有别的方向没列」
- 「业界普遍 / 通常认为 / 大家都」但不给具体出处——读起来像事实，其实是语气

### 清单末尾必须有「未覆盖方向」

| 方向 | 为什么没列为选项 | 要采用还需了解什么 |
|---|---|---|
| CRDT + P2P 直连 | 复杂度高，1 人 2 周做不完 | NAT 穿透、移动端后台保活限制 |

三列都要有。第三列帮你判断「**要不要回头去补**」。
**这一节不能为空**——空等于声称选项已穷尽，而那几乎总是假的。想不出来就写「我不确定是否还有别的方向」。

### 门禁怎么查

| 检查 | 强度 |
|---|---|
| 每条关键点是否有依据行（awk 逐条目扫，不看总数） | 拦截 |
| 「未覆盖方向」是否存在、非空、≥3 列 | 拦截（列数不足为提醒） |
| 「业界普遍/通常认为」类无出处断言 | 提醒 |

> 第二条的「逐条目」是重点：初版按总数判断，删掉一条依据仍能 PASS（集中写在开头也够数）。
> 这个漏洞由反向测试发现并修复。

样例见 `examples/align/CHECKLIST-dim7-example.md`。

---

## 三之二、分支策略（新增）

```bash
make branch NAME=user-login      # 建 feat/user-login
# ... S2 → S8 ...
make branch-finish NAME=user-login   # 过门禁 → 合并 → 清理
```

- 类型：`feat / fix / docs / refactor / test / chore / spike`
- 在 main 上有未提交改动 → `gate.sh` 拦截
- 分支名不合规 → `gate.sh` 拦截
- 合并前自动跑门禁

---

## 四、目录结构

### 4.1 框架本体（本仓库）

```
aegis/
├── VERSION                   版本号（语义化版本，唯一来源）
├── AGENTS.md                 入口（会话启动协议 + 六条铁律 + 指针）
├── STATE.md                  状态快照模板（≤40 行，新会话必读）
├── CHANGELOG.md              变更日志（语义化版本）
├── CLAUDE.md -> AGENTS.md    软链，兼容 Claude Code
├── GEMINI.md -> AGENTS.md    软链，兼容 Gemini CLI
├── Makefile                  setup / gate / status / sync / branch
│
├── .ai/                      规范真相源（唯一真相，按阶段拆分省 token）
│   ├── 00-core.md            核心原则与状态机总览（必读）
│   ├── 01-S1-init.md         立项
│   ├── 015-S2-align.md      意图校准（两轮讨论 + 小白语言）
│   ├── 02-S3-ideate.md       构思
│   ├── 03-S4-design.md       设计（HTML demo 硬要求）
│   ├── 04-S5-validate.md     验证（12 项 + 意图复核 + 历史回灌）
│   ├── 05-S6-implement.md    实现（TDD + INC 触发）
│   ├── 06-S5-verify.md       校验（三轮 review）
│   ├── 07-S7-archive.md      归档（STATE 重写 + CHANGELOG + tag）
│   ├── 17-S8-deliver.md      交付（冒烟验证 + RELEASE + 签收）（冒烟验证 + RELEASE + 签收）
│   ├── 90-preferences.md     用户偏好（必读）
│   └── 99-reference/         7 份 schema（按需加载）
│
├── .skills/                  9 个可执行 skill（Superpowers 格式，派生物）
│   ├── aegis-state/          会话开机自检 + 越界拦截
│   ├── aegis-s2-align/          S2 两轮选项式讨论
│   ├── aegis-s3-converge/       收敛 + 范围声明 + 失败定义
│   ├── aegis-s4-expand/         展开 + 权衡矩阵 + HTML demo 强制
│   ├── aegis-s5-falsify/        找破绽（设计/代码两检查点）
│   ├── aegis-s6-implement/      TDD + INC 记录
│   ├── aegis-s5-recheck/        复审 + INC 回灌
│   ├── aegis-s7-solidify/       状态固化 + tag
│   └── aegis-p7-deliver/     冒烟验证 + 交付说明
│
├── scripts/
│   ├── gate.sh               阶段出口门禁（S1–S8 + 框架自检）
│   ├── state.sh              状态快照读写 / 阶段切换 / 签字
│   ├── branch.sh             分支管理（start/finish/check）
│   └── sync.sh               派生物同步 + skill 完整性校验
│
├── templates/docs/           项目文档模板（拷到你项目的 docs/）
│   ├── INDEX.md              文档总索引（强制登记，S7 反查）
│   ├── prd.md                PRD 模板（六节）
│   ├── design/
│   │   ├── DESIGN.md         设计主文档（七节）
│   │   ├── STYLE.md          样式与交互规范
│   │   └── REVIEW-DESIGN.md  设计评审 12 项
│   ├── adr/ADR-0001-template.md
│   ├── incidents/INC-0001-template.md   反面教材模板（预防必填）
│   ├── reviews/REVIEW-CODE-template.md  代码评审模板（三轮）
│   ├── release/RELEASE-template.md      交付说明模板
│   └── align/README.md       两轮讨论文件命名与放法
│
├── examples/                 可运行样例（照抄即可）
│   ├── align/                CHECKLIST / ALIGN 真实样例（两轮）
│   └── design/demo/01-task-list.html   可交互 demo（5 态自包含）
│
├── adapters/                 跨 agent 适配壳（派生物，make sync 生成）
│   ├── cursor/rules.mdc      → .cursor/rules/aegis.mdc
│   ├── trae/rules.md         → .trae/rules/project_rules.md
│   ├── codex/AGENTS.md       → 仓库根 AGENTS.md
│   ├── claude-code/          仅软链，无额外文件
│   ├── reasonix/             直接读 AGENTS.md
│   ├── deepseek/             直接读 AGENTS.md
│   └── generic/              其它任意 agent
│
└── archive/                  归档区（scripts / fixtures / releases）
```

### 4.2 装到你的项目后长这样

```bash
your-project/
├── AGENTS.md                 ← 从 aegis/ 拷
├── STATE.md                  ← 从 aegis/ 拷，之后由 scripts/state.sh 维护
├── Makefile  scripts/  .ai/  .skills/  adapters/  archive/
├── CLAUDE.md -> AGENTS.md
├── docs/                     ← 由 templates/docs/ 初始化，之后是你的真实文档
│   ├── INDEX.md
│   ├── align/                CHECKLIST-*.md / ALIGN-*.md（每任务一套）
│   ├── prd.md  design/  adr/  incidents/  reviews/  release/
├── src/                      你的代码
└── tests/                    你的测试
```

### 4.3 交付物在哪

| 目录 | 放什么 | 能否删除 |
|---|---|---|
| `/workspace/aegis/` | **产品本体**（框架源码，只读参考）| 否 |
| `/workspace/out/` | **正式产物**：打好的 zip + 解包副本 + 版本索引 | 否（这是交付物）|
| `/workspace/temp/` | 中间产物：场景测试、评审草稿、临时脚本 | 是，随时可删 |

---

## 五、快速开始

```bash
# 1. 拷进你的项目（含隐藏目录）
cp -r aegis/. your-project/

# 2. 初始化项目文档（从模板）
mkdir -p docs
cp -r templates/docs/. docs/
rm docs/adr/ADR-0001-template.md docs/incidents/INC-0001-template.md   # 模板不入库

# 3. 建环境
make setup

# 4. 填项目信息
#    编辑 AGENTS.md 与 STATE.md（项目名、技术栈、当前阶段 S1）

# 5. 检查 S1 门禁
make gate S1

# 6. 同步派生物（生成 CLAUDE.md / adapters/ 下的壳）
make sync
```

---

## 六、核心命令

| 命令 | 作用 |
|---|---|
| `make branch NAME=x` | 建任务分支 |
| `make branch-finish NAME=x` | 合并回主分支 |
| `make br-check` | 检查分支命名 |
| `make setup` | 重建 Python 虚拟环境 |
| `make gate` | 检查当前阶段门禁 |
| `make gate S4` | 检查指定阶段 |
| `make status` | 查看 STATE.md |
| `make phase S3` | 切换阶段（**自动检查门禁，拒绝跳步**）|
| `make sign S3 "原话"` | 记录门禁签字 |
| `make next "a\|b"` | 更新下一步 |
| `make sync` | `.ai/` → `.skills/` 与 `adapters/` 同步 |
| `make demo` | 打开第一个 HTML demo |

---

## 七、与 Superpowers 的关系

**不是替代，是分层叠加 + 选择性覆盖。**

| Superpowers skill | Aegis 的处理 |
|---|---|
| `using-superpowers` | 保留，Aegis 的 `aegis-state` 在它之后接管 |
| `brainstorming` | **被 `aegis-p1-ideate` 覆盖**（产出必须落 PRD 六节） |
| `writing-plans` | **被 `aegis-p2-design` 覆盖**（必须出 demo） |
| `verification-before-completion` | **被 S5 三轮 review 覆盖** |
| `test-driven-development` | **保留**（通用，做得好） |
| `systematic-debugging` | **保留** + 接入 INC 库 |

覆盖 3 个、保留 3 个。加载量下降，token 省一半以上。

**仲裁规则**：Aegis 的 `.ai/` > 用户当前指令中的流程要求 > 通用 skills。冲突无法判断时，向用户指出，不自行裁决。

---

## 八、跨 agent 支持

| Agent | 接入方式 |
|---|---|
| Claude Code | 根目录 `CLAUDE.md`（软链到 AGENTS.md）|
| Gemini CLI | 根目录 `GEMINI.md`（软链）|
| Cursor | `adapters/cursor/rules.mdc` → `.cursor/rules/aegis.mdc` |
| Trae CN | `adapters/trae/rules.md` → `.trae/rules/project_rules.md` |
| Codex CLI/App | `AGENTS.md` + `adapters/codex/AGENTS.md` |
| CodeBuddy CN / Reasonix / 其他 | 直接读 `AGENTS.md`（L1 兜底，无需壳）|

> **保底原则**：任何 agent，哪怕不支持 skills，只要读 `AGENTS.md` + `STATE.md` 就能遵守规范。

---

## 九、Token 效率（实测，非估算）

用 UTF-8 字符数 ÷ 1.6 折算（中文约 1 token / 1.6 字符）：

| 加载内容 | 字符数 | ≈ tokens |
|---|---|---|
| `AGENTS.md` | 3547 | 2216 |
| `STATE.md` | 289 | 180 |
| `.ai/00-core.md` | 3817 | 2385 |
| `.ai/90-preferences.md` | 1839 | 1149 |
| **启动四件套合计** | **9492** | **≈5900** |
| 再加当前阶段文件（以最长的 `11-S2-align.md` 为例）| +6917 | ≈+4300 |
| `.ai/` 全量（11 份 + 7 份 schema） | 37424 | ≈23400 |

**诚实的结论**：

- 每次会话启动固定开销约 **5900 tokens**，进 S2 时约 **10200 tokens**。
- 相比「全量 `.ai/` 23400 tokens」，分阶段加载确实省一半以上，但**不是** 800 tokens 那个量级。
- 真实收益不在单次启动，而在**不必每轮重读全部规范**：进入 S6 之后，S2 的 4300 tokens 不再占上下文。

> 早期版本 README 曾写「~800 tokens / 降 90%」，那是错的，已按实测修正。

---

## 十、验证记录

本套方案已通过以下实测（均为注入缺陷后观察**是否被拦截**）：

| 测试 | 结果 |
|---|---|
| S1 门禁（缺 .venv 应拦） | ✅ 拦截 |
| S3 门禁（PRD 非目标为空） | ✅ 拦截 |
| S3 门禁（非目标填占位符 `<...>`） | ✅ 拦截 |
| S4 门禁（删除 demo 文件） | ✅ 拦截 |
| S4 门禁（demo 引用外部 CDN） | ✅ 拦截 |
| S4 门禁（无用户签字） | ✅ 拦截 |
| **S6 门禁：`src/` 里留 `print()` 调试** | ✅ 拦截（定位到文件:行） |
| **S6 门禁：硬编码 `API_KEY = "sk-live-..."`** | ✅ 拦截 |
| **S6 门禁：INC 的「预防」仍是 `<...>` 占位符** | ✅ 拦截（填实后放行） |
| **S6 门禁：干净代码 + 已填 INC** | ✅ 放行 |
| S5 门禁：今日 REVIEW-CODE 缺失 | ✅ 拦截 |
| **S7 门禁：STATE.md 涨到 48 行** | ✅ 拦截（>40） |
| **S7 门禁：「下一步」写"继续开发"** | ✅ 拦截（要求可执行） |
| **S7 门禁：CHANGELOG 写"优化若干细节"** | ✅ 拦截 |
| **S7 门禁：tag `v2.5.0` 与 CHANGELOG 版本不符** | ✅ 拦截 |
| **S7 门禁：新文档未登记 INDEX** | ✅ 拦截（13 条全部报出） |
| **S7 门禁：归档完成（tag+版本一致+INDEX 全登记）** | ✅ 放行 |
| **S7 门禁：分支内有 `.py` 改动** | ⚠️ 警告（不拦，因改动可能发生在 S6/S5） |
| **S8 门禁：无 `RELEASE-v*.md`** | ✅ 拦截 |
| **S8 门禁：已知限制写「无」** | ✅ 拦截 |
| **S8 门禁：验证证据写「已测试」** | ✅ 拦截 |
| **S8 门禁：内容填实但未签收** | ✅ 拦截 |
| **S8 门禁：内容填实 + 已签收** | ✅ 放行 |
| 阶段切换 S1 → S8（跳步） | ✅ 拒绝 |
| 阶段切换 S1 → S3（逐级） | ✅ 检查门禁后放行 |
| 阶段回退 S4 → S3 | ✅ 允许并提示 |
| 9 个 SKILL.md frontmatter 规范 | ✅ 全部合规（desc 147–174 字符，fm 183–210 字符）|
| 派生物同步一致性 | ✅ 一致（含反向检查未登记 skill）|
| **S2 门禁：删 R2 讨论记录** | ✅ 拦截 |
| **S2 门禁：R2 条目不足 6 条** | ✅ 拦截 |
| **S2 门禁：checklist 含技术词「鉴权/缓存」** | ✅ 拦截 |
| **S2 门禁：签字为空** | ✅ 拦截 |
| **S2 门禁：某条缺「其他」选项** | ✅ 拦截（5/6） |
| **S2 门禁：只给 A/B 两个方向** | ✅ 拦截（C:0） |
| **分支检查：在 master 上有改动** | ✅ 拦截 |
| **阶段跳步：S2 → S4** | ✅ 拒绝 |

---

## 十一、后续可扩展

九个阶段的规范、skill、门禁已全部就位。可继续加强的方向：

- git pre-commit hook 调用 `bash scripts/branch.sh check`（硬锁分支规范）
- CI 集成 `make check-sync` + `make gate`（每个 PR 自动跑）
- `.skills/` 打包成可分发插件（各 agent 各自安装）
- `gate.sh ALL` 用于发版前的全链路体检（已支持，未纳入默认流程）

> 注意：**不要为了"更完整"而增加阶段。** 九个阶段已经覆盖从"用户提一句"到"用户能用"的全链路，
> 再加阶段只会让门禁变成形式主义 —— 这是 Aegis 最想避免的结局。
