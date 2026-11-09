# 贡献指南

> 这个项目自己遵守自己的规矩。改动前先读 [`AGENTS.md`](AGENTS.md) 和
> [`docs/reference/concepts.md`](docs/reference/concepts.md)（术语在这里定义，别自造词）。

---

## 一、环境

| 需要 | 说明 |
|---|---|
| Git Bash | Windows 上脚本用 bash 写；`C:\Program Files\Git\bin\bash.exe` |
| Node.js | 只用于合并 `.reasonix/settings.json`（hook 安装） |
| Python 3.10+ | 可选，`make setup` 会建 `.venv` |

**没有 `make`**：Windows 上直接用 `bash scripts/xxx.sh`，`make` 只是便捷封装。

---

## 二、动手前

```bash
bash scripts/gate.sh          # 看当前阶段门禁过没过
bash scripts/branch.sh feat/<短名>   # 每个任务独立分支，禁止在 main 上改
```

**分支命名**：`feat/` `fix/` `docs/` `refactor/` `test/` `chore/` `spike/`

---

## 三、改动时的规矩

### 文档放哪（按行业约定，别自造目录）

```
docs/guides/       任务导向（怎么装、怎么用）
docs/reference/    参考（术语表）
docs/explanation/  理解导向（为什么这么设计）
docs/adr/          架构决策（一份决策一个文件）
docs/incidents/    故障记录（「预防」必填）
docs/release/      发布说明
docs/rfc/          提案与讨论        ← 设计者维度
docs/internal/     开发过程记录      ← 设计者维度
```

交付包会自动剔除 `docs/rfc/` 和 `docs/internal/`，其余随包发。

### 提交信息

```
<类型>(<范围>): <一句话说清做了什么>

<为什么改，不是改了什么——改了什么看 diff 就知道>
```

类型：`feat` `fix` `docs` `refactor` `test` `chore`

### 修 bug 必须留证据

**"应该可以"不算。** 说"修好了"要贴运行输出；说"测过了"要贴测试结果。

若是调试超过 15 分钟、或试错两次以上才解决的问题，必须在
`docs/incidents/INC-*.md` 建一条记录，**「预防」一栏必填**——
不然下次还会踩同一个坑。

---

## 四、改 hook 的特别注意

`templates/v3/reasonix/hooks/` 里四个脚本是真的会拦人操作的，改之前请先看
[`docs/internal/reasonix/FINDINGS.md`](docs/internal/reasonix/FINDINGS.md)——
那里记着 13 条踩过的坑，最严重的一条是 **`match` 是锚定正则**，
配 `write` 匹配不到 `write_file`，导致整层从来没触发过。

**改完必须实测**：

```bash
# 造一个 payload 喂给它，看 exit code
echo '{"toolName":"write_file","toolArgs":{"path":"x","content":"y"}}' \
  | bash templates/v3/reasonix/hooks/aegis-guard-write.sh
echo $?   # 0 = 放行, 2 = 阻断
```

---

## 五、不要做的事

| 别做 | 为什么 |
|---|---|
| 自造目录名（`dev/`、`docs/public/`） | 已统一到行业标准，加回去等于开倒车 |
| 自造术语 | 先看 `docs/reference/concepts.md`，要加新词就在那里定义，别在别处随手造 |
| 把约束写成更长的文档 | 实测过：9720 字节的文本规范拦不住 agent，20 行 hook 能拦住 |
| 声称"独有/首创"而不说为什么别人没做 | 独有可能意味着"没人需要" |
| 只修被指出的那一处 | 系统性检查 > 修可见问题（这个项目栽过两次） |

---

## 六、提 PR 前

```bash
bash scripts/gate.sh          # 门禁必须过
bash scripts/sync.sh --check  # 派生物（.skills/ adapters/）要一致
```

然后在 PR 描述里写清：**改了什么、为什么、怎么验证的**。
