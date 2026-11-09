# Aegis

> 给 AI agent 加一层「**说得清、接得上、留得下**」的约束。

**版本 3.0.0** ｜ 平台：Reasonix（Claude Code / Trae 格式已知，未实现）

---

## 为什么做

现在的 agent 能力不缺，缺的是三件事：

| 症状 | 表现 |
|---|---|
| **说完就忘** | 换个会话，它从零开始问"你想做什么" |
| **说了没做** | 自称"用了第一性原理"，输出里找不到一点痕迹 |
| **做错不认** | 把没做完的说成做完了，你没证据反驳 |

Aegis **不教 agent 怎么做工程**（那是 Superpowers / BMAD 的事），只保证上面三件事**有据可查、有据可拦**。

---

## 它做什么

### 两层设计

| 层 | 内容 | 作用 |
|---|---|---|
| **约束层**（监管） | 4 个维度：认知 · 事实 · 语义 · 时间<br>+ 项目级 ≤3 条 | 审计 + 否决权，**不是控制权** |
| **能力层**（内置） | 16 个思维模型（第一性原理、逆向、Kano、双环反思…） | 只在需求含糊时触发，三层按需加载 |

### 三个强制点（Reasonix 上已实测）

```
会话开始   SessionStart 注入 4 条约束            ✅ 生效
动手时     PreToolUse：无 NOTES 不许写文件        ✅ 生效
           PreToolUse：main 上不许 commit/merge/push  ✅ 生效
收尾时     Stop 提醒更新 NOTES                    ⚠️ 平台不允许阻断
```

**为什么用 hook 而不是写文档**：把约束放到模型外面执行。
实测对比——9720 字节的文本规范**没拦住** agent 写文件，20 行 hook **拦住了**。

---

## 快速开始

```bash
git clone https://github.com/Jacsean/Aegis.git
cd Aegis
bash scripts/install-v3.sh /path/to/your-project
```

**六步，全部不覆盖你已有的东西**：

| 步 | 做什么 | 冲突处理 |
|:--:|---|---|
| 1 | 探测宿主能力（hook / 子智能体 / 记忆） | — |
| 2 | 装 `aegis-think` 到 `.agents/skills/` | 只新增 |
| 3 | 装入口 `AGENTS.md` / `preferences.md` | **标记追加**，原文保留 |
| 4 | 初始化 `NOTES.md` / `CORE-CHECKLIST.md` / `constraints.md` 等 | 已存在则保留 |
| 5 | 挂 hooks 到 `.reasonix/settings.json` | **合并**，原有 hook 保留 |
| 6 | 生成 `AEGIS-分工.md`（探测已有 skills） | 每次重新生成 |

装完重开 agent 会话。Windows 上 Git Bash 冷启动慢，`timeout` 要给足 **15 秒**。

---

## 实测结果（诚实版）

以下都有真实运行记录，不是设计意图。

### 有效的

| 能力 | 结果 | 证据 |
|---|:--:|---|
| 缺 `NOTES.md` 时拦写文件 | ✅ | `⊘ write_file blocked by PreToolUse hook`，文件确实没建成 |
| main 上拦提交 | ✅ | 给出「先建分支」的解，agent 照做了 |
| **认知维度** | ✅ | 抓到"对话里说用了第一性原理，文档里一个字没提" |
| **事实维度** | ✅ | 抓到"标了 `[检索]` 却一条来源都没给" |
| **语义维度** | ✅ | 抓到"自造术语，不用概念表里的词" |
| **时间维度** | ✅ | 新会话只收到「接着做」，主动读 NOTES、**没重提被否定的方案** |
| 被拦后 agent 行为 | ✅ | 不是放弃，而是**去读 hook 脚本搞清楚原因**，然后补上前置条件 |

### 边界（**这些它做不到，别指望**）

| 做不到 | 说明 |
|---|---|
| **判断你的判断对不对** | 它能查"言行是否一致"，查不了"想得是否正确" |
| 拦「已加载的 skill 指令被执行」 | 那不是工具调用，没有事件可挂 |
| 拦「模型不调用工具直接回答」 | 没有动作可拦 |
| Stop 阶段阻断 | Reasonix 只允许 PreToolUse / UserPromptSubmit 返回 exit 2 |

**一句话**：**Aegis 能保证你不骗人，不能保证你没错。**

最能说明问题的一次实测：让它评估 Aegis 自己（自指任务，四问全中），
它把产物放错了地方——**4 个维度一个都没抓到**，因为那是"判断质量"问题，不是"言行不一"。
后来靠"强制二次独立判断"才补上，这条已写进 `aegis-think`。

---

## 和其他工具什么关系

**不是替代品，是叠加层**——装在任何已有 skills / rules 之上，只管底线。

| 关系 | 例子 |
|---|---|
| **让路**（11 个） | 测试、调试、写计划、分支管理、worktree、子智能体、版本规范、变更日志、做 skill —— Aegis 完全不碰 |
| **并列**（5 个） | verification、code-review、security-review、thinking-model-workflows —— 各查各的 |
| **串联**（3 个） | brainstorming（Aegis 判断在前）、knowledge-handbook（NOTES 是源）、find-skills（装完记账） |
| **外接** | 三头管控：调用前定验收 / 调用中不管 / 调用后验收记账；**单任务 ≤2 个** |

装完会生成 `AEGIS-分工.md`，**自动探测你已装的能力**并列出关系，含「规则文件冲突怎么办」一节。

---

## 目录结构

```
docs/
├── guides/         任务导向：装、配、用
├── reference/      参考：术语表
├── explanation/    理解导向：为什么这样设计
├── adr/            架构决策记录
├── incidents/      故障记录（含「预防」必填）
├── release/        发布说明
├── rfc/            提案与讨论        ← 设计者维度，交付时剔除
└── internal/       开发过程记录      ← 设计者维度，交付时剔除
```

遵循 **Diátaxis**（Django / Ubuntu / Cloudflare / Kubernetes 采用）+ **ADR** + **SRE** 的行业约定。

---

## 已修的坑（13 条，都有实测记录）

最严重的一条：**hook 的 `match` 是锚定正则**——配 `write` 匹配不到实际工具名 `write_file`，
导致拦截层**从头到尾没触发过**。等于有一层是假的，而文档里写得好好的。

全部记录在 [`docs/internal/reasonix/FINDINGS.md`](docs/internal/reasonix/FINDINGS.md)，含专门的「能力边界」一节。

---

## 版本

当前 **v3.0.0** —— 相对 v2 是一次重写，不兼容（目录、安装方式、hook 格式全变）。见 [CHANGELOG](CHANGELOG.md)。

---

## 许可

[MIT](LICENSE)
