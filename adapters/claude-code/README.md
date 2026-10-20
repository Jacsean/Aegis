# Claude Code 适配

## 接入方式

Claude Code 读仓库根目录的 `CLAUDE.md`。Aegis 把它做成**指向 `AGENTS.md` 的软链**，因此只需维护一份。

```
CLAUDE.md -> AGENTS.md
```

由 `make sync` 自动建立；若 zip 解包把软链摊成了实体副本，`make sync` 会自动转回软链。

## 不需要额外文件

Claude Code 原生支持：
- 项目级记忆 = `CLAUDE.md`（已由软链解决）
- skills = `.skills/`（Aegis 的 9 个 skill 放在这里，Claude Code 可直接加载）

## 验证

```bash
ls -l CLAUDE.md          # 应显示 -> AGENTS.md
make check-sync          # 应输出「同步状态：一致」
```
