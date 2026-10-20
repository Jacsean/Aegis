---
name: aegis-p6-archive
description: Use when verification has passed and the work is about to be declared done, or when project state, changelog, index, or version tag may be out of date
---

# Aegis P6 Archive

## Overview

把"这次干成了什么"固化成**下一次能直接用**的东西。

核心原则：**归档的读者是三个月后完全忘了这事的自己。**

P6 不产出新功能，只做一件事：让下一个会话、下一个任务能在 30 秒内接上。

## When to Use

- P5 三轮 review 已通过，Critical 清零
- 准备合并分支或发布版本
- 发现 STATE.md 写的阶段与实际不符

## 铁律：P6 只写文档，不改代码

P6 期间禁止修改 `src/` 和 `tests/`。

原因：P5 评审的是改前的代码。归档时再改一行，评审结论就失效了。

发现代码问题 → 记进 STATE.md「已知限制」，或另开分支修。

## 动作

### 1. 先看事实，再写字

```bash
git log --oneline main..HEAD          # 本分支做了什么
git diff --stat main...HEAD           # 改了哪些文件
git log --oneline main..HEAD -- docs/incidents/   # 涉及哪些 INC
```

凭记忆写 CHANGELOG 必然漏项。

### 2. 整体重写 STATE.md（最重要）

不是改阶段号。按 `.ai/99-reference/state-schema.md` 逐节过：

| 小节 | 做什么 |
|---|---|
| 当前迭代 | 改成这次的名字 |
| 已完成 | 追加本迭代，旧的压成一行 |
| 进行中 | 清空本迭代项 |
| 下一步 | 重写为可执行动作，不写"继续开发" |
| 门禁签字 | 补 P5 |
| 最近决策 | 追加 ADR / INC 编号，最多留 5 条 |
| 已知限制 | 从 P5 的 Major/Minor 登记搬进来 |

**全文仍 ≤ 40 行。** 细节进 CHANGELOG，STATE 只留大类。

### 3. 更新 CHANGELOG.md

语义化版本，分「新增 / 变更 / 修复 / 移除」。

每条必须可追溯到 ADR 或 INC 编号。禁止写"优化若干细节"。

### 4. INDEX 完整性检查

```bash
for f in $(find docs -name '*.md' -o -name '*.html' | sort); do
  grep -q "$(basename "$f")" docs/INDEX.md || echo "未登记: $f"
done
```

同时查可追溯性：ALIGN 被 PRD 引用？INC 被 STATE 引用？ADR 被 DESIGN 引用？
孤立文档 = 死了的文档。

### 5. 归档垃圾产物

- 一次性调试脚本 → `archive/scripts/`
- 大体积测试数据 → `archive/fixtures/`
- **demo 不要删**（用户确认过的设计证据）

源码、测试、正式文档不进 archive。

### 6. 打 tag（在 main 上，不在功能分支）

```bash
git tag -a v1.3.0 -m "v1.3.0 用户登录"
```

tag 版本号必须与 CHANGELOG 一致。

## 完成标准

- [ ] STATE.md 整体更新，≤ 40 行，「下一步」可执行
- [ ] CHANGELOG 有本版本条目，可追溯
- [ ] INDEX 无未登记文件
- [ ] tag 已打且在 HEAD
- [ ] **P6 提交里没有代码文件改动**
- [ ] `bash scripts/gate.sh P6` PASS

## 给用户的归档摘要

不要问"可以吗"，要问"有没有写错"：

```
P6 归档完成，v1.3.0。
本迭代交付：<功能 1>、<功能 2>
记录沉淀：INC 新增 3 条，ADR 新增 1 条
已更新 STATE / CHANGELOG / INDEX，tag v1.3.0
有哪里写错了请指出。没问题就可以进入 P7。
```

## Common Mistakes

| 错误 | 纠正 |
|---|---|
| STATE.md 只改阶段号 | 下个会话读到过期信息，白读 |
| STATE.md 越写越长 | 50 行 80 行，token 优势消失 |
| CHANGELOG 写"优化若干细节" | 三个月后查不到任何东西 |
| 忘记打 tag | 无法定位哪个 commit 是这版 |
| 在功能分支上打 tag | tag 指向未合并状态 |
| 归档时顺手改代码 | P5 结论失效 |
| 删掉 demo | 丢失设计证据 |

## Red Flags — STOP

- "STATE.md 改个阶段号就行" → 下个会话会被误导
- "CHANGELOG 发版时一起写" → 到那时细节全忘了
- "这个改动太小不用记" → 小改动堆起来就是"这功能哪来的"
- "顺手把这行也改了" → P6 禁止改代码
- "tag 下次补" → 下次就找不到这个 commit 了
