# RELEASE · v2.0.1

## 一、交付了什么

Aegis 工程流程系统，八阶段骨架（S1 立题 → S2 对齐 → S3 收敛 → S4 展开 → S5 找破绽 → S6 实现 → S7 固化 → S8 交付）+ 场景决断入口分诊。本版修正：

1. 流程规范全文统一为 S 编号体系，无历史遗留编号
2. 新增 `scripts/check-no-legacy.sh`：交付包自检判据，命中即失败
3. `gate.sh` 在交付包内只跑框架自检，在项目内跑项目级门禁（以 `.aegis-package` 标记区分）
4. `deliver.sh` 出包后 git 工作区干净、STATE 为新项目起始态，新 agent 可直接开工

## 二、怎么用

1. 解包，读 `AGENTS.md`（启动协议 + 七条铁律）
2. 每次会话：读 `STATE.md` → 场景决断（`.ai/09`）→ 按阶段加载 `.ai/1X-Sn-*.md`
3. 门禁：`make gate-s1`…`gate-s8`；建分支 `make branch NAME=<短名>`
4. 新项目把 `templates/docs/` 复制为你的 `docs/`

## 三、验证证据

- 三轮零上下文 agent 模拟：按包内指引走「新建项目」场景，均走出 S1~S8，S1 制品一次写通，无历史遗留流程诱导
- 包内 `gate.sh` PASS、`check-no-legacy.sh` 0 命中、`git status` 干净、`branch.sh` 一步通过

## 四、已知限制

- 场景字典初始 4 类，领域扩展留检索扩展点
- `.skills` 的 S5 拆为 `aegis-s5-falsify`（查设计）/ `aegis-s5-recheck`（查代码）两个入口，属同一阶段
- Windows 软链（CLAUDE.md → AGENTS.md）需开发者模式

## 五、适用场景

所有使用 Aegis 的项目。
