# PATH-MAP · 分离前后路径与 git 历史的映射表

> **本文件只给 agent 看，供回溯 git 历史时解码旧路径用；人类用户不需要阅读。**
> v1.6.0（H-0019）起产物按「设计者 / 使用者」两维度物理分离，目录结构变了。
> **读 git 历史（旧 commit、旧 tag ≤ v1.5.0）时，路径按下表换算**；看新结构时反着换。

| v1.5.0 及更早（旧路径） | v1.6.0 起（新路径） | 维度 | 说明 |
|---|---|---|---|
| `docs/develop/CONCEPTS.md` | `docs/CONCEPTS.md` | 使用者 | 概念表搬家，内容不变 |
| `docs/develop/HANDOFF.md` | `dev/HANDOFF.md` | 设计者 | 交付包内不存在（被 deliver.sh 剔除）|
| `docs/develop/handoff/H-*.md` | `dev/handoff/H-*.md` | 设计者 | 同上 |
| `archive/` | `dev/archive/` | 设计者 | 同上 |
| `docs/develop/`（其余内容） | `dev/` | 设计者 | 均不在交付包内 |

## 三个口径

1. **旧 tag 工作树 = 旧结构**：`git checkout v1.5.0`（或更早）后，`dev/` 不存在，一切在旧路径——这不是坏了，是当时的结构。回退点功能不受分离影响。
2. **新交付包工作树 = 使用者维度**：没有 `dev/`；要查开发过程档案（handoff、归档），去设计者仓库或用旧 tag。
3. **历史 commit 里的 dev 文件对象仍存在**（.git 内），`git show v1.5.0:docs/develop/CONCEPTS.md` 这类命令照常可用——分离只改工作树打包，不改历史。

> 起因与决策见 `dev/handoff/H-0019`（设计者维度，交付包内不可见；本表是它在使用者侧的镜像）。
