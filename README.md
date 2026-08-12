# dotfiles — 我的电脑配置备份

> 把你的电脑设置「云备份 + 恢复出厂」，换新电脑一条命令还原，配置改坏了一键回滚。

## 目录

- [这是什么？能做什么？](#这是什么能做什么)
- [技术方案：裸 git 仓库](#技术方案裸-git-仓库)
- [目录结构](#目录结构)
- [快速开始（新机器部署）](#快速开始新机器部署)
- [日常使用](#日常使用)
- [换新 Mac 后的 Token 配置](#换新-mac-后的-token-配置)
- [改坏了怎么办（回滚）](#改坏了怎么办回滚)
- [常见问题](#常见问题)
- [License](#license)

---

## 这是什么？能做什么？

这是作者**全部电脑配置的备份仓库**，托管在 GitHub 上。你电脑上那些「改起来很麻烦、丢了很心疼」的配置文件，都在这里有一份带版本历史的记录：

| 类别 | 内容 |
|------|------|
| **Shell** | zsh 配置（插件、提示符、别名、代理） |
| **Git** | git 全局配置、忽略规则 |
| **编辑器** | Neovim 完整配置（插件、快捷键、LSP） |
| **AI 工具** | opencode、codex（DeepSeek）、Claude 技能 |
| **系统工具** | btop、htop 监控面板 |
| **软件清单** | 你装过的所有软件（Homebrew） |

**能做什么：**

1. **换电脑 / 重装系统**：一条命令，所有配置和软件自动还原，新电脑 = 旧电脑
2. **改配置不怕改坏**：每次改动先存一个「存档」，改坏了随时回到上一个存档
3. **软件搬家**：`my-packages.txt` 记着你装的所有软件，新电脑自动装齐

**简单说：这是你电脑设置的「时光机 + 云同步」。**

## 技术方案：裸 git 仓库

### 为什么不用普通 git 仓库？

| | 普通仓库 | 裸仓库（本项目） |
|---|---|---|
| 是什么 | 一个「项目文件夹」+ 藏在里面的 .git 记录 | **只有** .git 记录，没有项目文件夹 |
| 常见用途 | 写代码（比如你的其他项目） | 专门追踪「散落在各处的文件」 |
| 配置存在哪 | 仓库文件夹内（副本） | **原地不动**（就是真实文件本身） |

**打个比方：**

- **普通仓库** = 一个行李箱。你必须把东西**装进箱子**（复制文件进去），箱子里是副本，改了要手动同步回来。
- **裸仓库** = 一个**记账本**。它不复制你的配置，而是记录你电脑里真实存在的配置文件（`.zshrc`、`.config/nvim/`...）的内容和每次改动。

你的配置散落在 `~/.zshrc`、`~/.config/nvim/`、`~/.codex/` 等不同位置，裸仓库可以让它们**原地**被管理：`git checkout` 一条命令在新电脑原位还原，不用复制、不用建软链接。

### `~/.dotfiles` 目录里是什么？

它是**这个项目的「档案室」**——里面只有 git 的账本（提交历史、版本记录），**不含你的任何配置文件**。

- `~/.zshrc`、`~/.config/nvim/` 是「被保管的物品」，待在原处不动
- `~/.dotfiles` 是「保管员的账本」，只记录每个物品的内容和每次改动
- 账本是整套备份系统的核心

### 核心命令

```bash
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
```

这行已经自动写入 `~/.zshrc`，之后的 `dotfiles` 命令就相当于「对账本说话」。

## 目录结构

```
.
├── .zshrc                     # zsh 主配置：插件、提示符、别名、PATH、代理
├── .zprofile / .zshenv        # 登录配置、环境变量
├── .profile / .tcshrc         # 兼容性配置
├── .gitconfig                 # git 全局配置（用户信息、GitHub 代理）
├── .gitignore                 # 仓库忽略规则（排除私有/运行时数据）
├── .env                       # 【不入库】敏感配置（Token 填在这里）
├── my-packages.txt            # Homebrew 软件包清单（dotbrew 自动维护）
├── README.md                  # 本文件
├── bin/
│   ├── setup.sh               # 一键部署脚本（新机器用）
│   ├── dotpush                # 保存配置改动并推送（alias: dotpush）
│   └── dotbrew                # 记录新装软件并推送（alias: dotbrew）
├── .config/
│   ├── nvim/                  # Neovim 配置（插件、快捷键、LSP）
│   ├── opencode/              # opencode AI 工具（含 MCP 服务配置模板）
│   ├── btop/  htop/           # 系统监控面板
│   ├── fish/  git/            # fish shell、git 忽略规则
│   └── ...
├── .codex/
│   └── config.toml.template   # codex 配置模板（Token 为占位符）
└── .agents/
    └── skills/agently-mail/   # Claude 技能：agently-mail（邮件助手）
```

## 快速开始（新机器部署）

### 第 1 步：安装 Homebrew（macOS）

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 第 2 步：一键部署

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Kylin233333/dotfiles/master/bin/setup.sh) https://github.com/Kylin233333/dotfiles.git
```

脚本会自动完成：

1. **克隆裸仓库** 到 `~/.dotfiles`
2. **拉取最新配置**
3. **检出全部配置到 `$HOME`**（与已有文件冲突时自动备份为 `*.bak`）
4. **写入 alias**（`dotfiles` / `dotpush` / `dotbrew`）到 `~/.zshrc`
5. **扫描所有需要填写的 Token**，自动生成/补充 `~/.env`（见下节）
6. **生成实际配置**（opencode / codex 等）
7. **安装全部软件**（读取 `my-packages.txt`，已装自动跳过）

### 第 3 步：重新加载 shell

```bash
source ~/.zshrc
```

## 日常使用

只有两个场景需要记：

### 场景 A：改了配置（比如改了 `~/.zshrc`）

```bash
dotpush
```

一条命令完成：暂存改动 → 提交 → 推送到 GitHub。没有改动时会提示「无需提交」。

> 安全设计：`dotpush` 只处理**已跟踪的配置文件**，绝不会把你桌面上的照片、文档等个人文件误传上去。

### 场景 B：新装了软件（`brew install xxx`）

```bash
dotbrew
```

一条命令完成：重新生成软件清单 `my-packages.txt` → 提交 → 推送。软件没变化时会提示「无需提交」。

### 高级操作（可选）

```bash
dotfiles status                  # 查看改了哪些配置
dotfiles log --oneline -10       # 查看最近 10 次存档记录
dotfiles checkout -- ~/.zshrc    # 丢弃 .zshrc 的本地改动
dotfiles pull --ff-only          # 手动拉取其他机器的改动
```

## 换新 Mac 后的 Token 配置

**Token（密钥）永远不会出现在 GitHub 仓库里**——仓库是公开网页，放上去等于把密码贴在公告栏。所以每次换新机器，Token 需要在新机器上手动填一次，流程如下：

### 1. 部署脚本会自动创建 `~/.env`

运行部署脚本后，它会在 `~/.env` 中自动写入所有需要填写的条目，每条都带注释说明**来自哪个配置文件**：

```bash
# 例如自动生成的 ~/.env（Token 留空，等待你填写）
BARK_KEY=                       # 来自 .config/opencode/opencode.jsonc.template
DEEPSEEK_API_KEY=               # 来自 .codex/config.toml.template
GITHUB_TOKEN=                   # 来自 .agents/skills/agently-mail/SKILL.md
```

> 之后若在配置里新增了其他占位符（形如 花括号-变量名，如 `SOME_NEW_KEY`），重新运行一次 `setup.sh`，新条目会自动追加到 `~/.env`。

### 2. 手动填入真实值

用编辑器打开 `~/.env`，把每个 Token 填进去，保存：

```bash
vim ~/.env   # 或任何编辑器
```

### 3. 重新运行部署脚本生成实际配置

```bash
bash ~/bin/setup.sh
```

脚本读取 `~/.env`，把配置模板中的占位符替换为真实 Token，生成实际配置文件（这些生成的文件同样不会入库）。

> Token 从哪来？
> - **BARK_KEY**：Bark App（iOS 推送）设置页
> - **DEEPSEEK_API_KEY**：platform.deepseek.com → API Keys
> - **GITHUB_TOKEN**：GitHub → Settings → Developer settings → Personal access tokens

## 改坏了怎么办（回滚）

每次 `dotpush` 都是一次「存档」，改坏了随时回退：

```bash
dotfiles log --oneline          # 先看有哪些存档（提交记录）
dotfiles checkout -- <文件>     # 把单个文件恢复到上次存档
# 或整体回退到某次存档：
dotfiles reset --hard <存档号>
```

## 常见问题

### Q1: 部署时报 "untracked working tree files would be overwritten"

新机器上已有同名文件（如出厂自带的 `.zshrc`），脚本会自动备份为 `*.bak`。手动处理：

```bash
mv ~/.zshrc ~/.zshrc.bak
dotfiles checkout
```

### Q2: 换了新机器，配置和软件如何全部还原？

```bash
# 1. 安装 Homebrew（见快速开始）
# 2. 部署（自动装全部软件 + 还原配置）
bash <(curl -fsSL .../bin/setup.sh) https://github.com/Kylin233333/dotfiles.git
# 3. 填写 ~/.env 的 Token，再跑一次 setup.sh
bash ~/bin/setup.sh
```

### Q3: opencode / codex 无法启动？

多半是 `~/.env` 里的 Token 没填或填错。填好后重新运行 `bash ~/bin/setup.sh`。

### Q4: `dotpush` 和 `dotfiles add` 什么区别？

- `dotpush`：**一键保存改动**，适合日常（只处理已跟踪文件）
- `dotfiles add <文件>`：**把新文件纳入管理**，适合首次加入一个新配置文件（如 `dotfiles add ~/.config/mpv/`）

## License

MIT
