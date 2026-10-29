# RELEASE · v2.0.0（八阶段落地）

## 一、交付了什么
Aegis 流程骨架切换：九阶段（P0/P0.5/P1~P7）→ 八阶段（S1 立题→S2 对齐→S3 收敛→S4 展开→S5 找破绽→S6 实现→S7 固化→S8 交付）+ 场景决断入口分诊。

## 二、怎么用
解压后读 `AGENTS.md` → 启动协议 → 场景决断（`.ai/09`）→ 按 `STATE.md` 阶段加载 `.ai/1X-Sn-*.md`；门禁 `bash scripts/gate.sh S1~S8` 或 `make gate-s1`…`gate-s8`。

## 三、验证证据
- 3 场景推演走通（dev/eight-stage-plan/simulation-findings.md）
- 仓库侧门禁 S1~S6 PASS；S7 待合并打 tag；S8 待本签收
- U1~U12 经用户定稿；M1~M11 移植有出处

## 四、已知限制
- 门禁内部检查块仍用旧名（P0~P7），S 是别名——读脚本源码会看到（回溯层，不影响使用）
- 场景字典仅 4 类初始场景，领域扩展（消费电子/物流等）待同行检索
- `.skills` 的 S5 拆成 falsify（查设计）/recheck（查代码）两个入口

## 五、适用场景
所有用 Aegis 的项目。旧项目回溯用 tag v1.6.1 及更早。
