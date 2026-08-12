# dotfiles — 我的配置文件集合

> 一站式管理个人开发环境的全部配置文件，支持多台机器一键部署与同步。

## 目录

- [项目简介](#项目简介)
- [技术方案](#技术方案)
- [目录结构](#目录结构)
- [快速开始（新机器部署）](#快速开始新机器部署)
- [日常使用](#日常使用)
- [敏感信息处理](#敏感信息处理)
- [支持的环境](#支持的环境)
- [常见问题](#常见问题)
- [License](#license)

---

## 项目简介

本仓库托管了作者日常开发环境的全部可迁移配置，涵盖：

| 类别 | 内容 |
|------|------|
| **Shell** | zsh（zinit 插件管理器 + 自定义提示符 + alias + 代理）、zprofile、zshenv |
| **Git** | 全局 gitconfig（用户信息、GitHub 代理）、gitignore 规则 |
| **编辑器** | Neovim（lazy.nvim 插件体系，options/keymaps/plugins/colorscheme/lsp 五模块） |
| **AI 工具** | opencode（MCP 服务：bark/webclaw/playwright）、codex（DeepSeek 提供商）、claude skills |
| **系统工具** | btop、htop 监控面板配置，fish shell 基础配置 |
| **软件清单** | `my-packages.txt` 完整 Homebrew 软件包列表（formula + cask） |

采用 **裸 git 仓库** 方案：`~/.dotfiles` 为 `git init --bare` 仓库，`work-tree` 直接指向 `$HOME`，通过 `dotfiles` alias 管理，**不产生任何符号链接**，配置文件就地版本管理。

## 技术方案

```
~/.dotfiles         裸 git 仓库（git init --bare）
    ↓ work-tree = $HOME
~/.zshrc ~/.gitconfig ~/.config/...   所有配置文件直接入库
```

核心 alias（已写入 `~/.zshrc`）：

```bash
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
```

> 为什么不使用 stow / 普通仓库 + 软链接？
> 裸仓库方案下配置文件就是真实文件本身，无需维护软链接关系，
> 新机器 `git checkout` 一键还原，且不会因软链接断链导致配置失效。

## 目录结构

```
.
├── .zshrc                     # zsh 主配置：zinit 插件、提示符、alias、PATH、代理
├── .zprofile                  # 登录 shell 配置
├── .zshenv                    # 环境变量
├── .profile / .tcshrc         # 兼容性配置
├── .gitconfig                 # git 全局配置（用户信息、GitHub 代理）
├── .gitignore                 # dotfiles 仓库忽略规则（排除私有/运行时数据）
├── .env                       # 【不入库】敏感配置（BARK_KEY、DEEPSEEK_API_KEY）
├── my-packages.txt            # Homebrew 软件包清单（部署时自动安装）
├── bin/
│   └── setup.sh               # 一键部署脚本（幂等，可重复执行）
├── .config/
│   ├── nvim/                  # Neovim 配置（lazy.nvim）
│   │   ├── init.lua
│   │   ├── lazy-lock.json
│   │   └── lua/               # options / keymaps / plugins / colorscheme / lsp
│   ├── opencode/
│   │   └── opencode.jsonc.template   # opencode 配置模板（BARK_KEY 为占位符）
│   ├── btop/                  # btop 系统监控配置 + 主题
│   ├── htop/htoprc            # htop 配置
│   ├── fish/config.fish       # fish shell 基础配置
│   └── git/ignore             # git 全局忽略规则
├── .codex/
│   └── config.toml.template   # codex 配置模板（DeepSeek API key 为占位符）
└── .agents/
    └── skills/agently-mail/   # Claude 技能：agently-mail（邮件助手）
```

## 快速开始（新机器部署）

### 1. 安装 Homebrew（macOS）

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. 一键部署

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Kylin233333/dotfiles/master/bin/setup.sh) https://github.com/Kylin233333/dotfiles.git
```

脚本会依次完成：

1. **克隆裸仓库** `~/.dotfiles`
2. **拉取最新配置**
3. **检出全部配置到 `$HOME`**（与已有文件冲突时自动备份为 `*.bak`）
4. **写入 `dotfiles` alias** 到 `~/.zshrc`
5. **生成敏感配置**（需要先创建 `~/.env`，见下文）
6. **安装 Homebrew 软件包**（读取 `my-packages.txt`，已安装的自动跳过）

### 3. 创建敏感配置 `~/.env`

```bash
cp ~/.env.example ~/.env   # 或手动创建
chmod 600 ~/.env
```

```bash
# ~/.env 内容示例
BARK_KEY=你的Bark推送密钥
DEEPSEEK_API_KEY=你的DeepSeek API Key
```

### 4. 重新加载 shell

```bash
source ~/.zshrc
```

## 日常使用

所有操作通过 `dotfiles` alias 完成（等价于在 `$HOME` 下操作一个普通 git 仓库）：

```bash
dotfiles status                  # 查看改动
dotfiles add ~/.zshrc            # 跟踪新文件（也支持目录，如 ~/.config/btop）
dotfiles add -A                  # 暂存所有已跟踪文件的改动
dotfiles commit -m "更新 zsh 配置"
dotfiles push                    # 推送
dotfiles pull --ff-only          # 拉取
dotfiles log --oneline -10       # 查看历史
dotfiles checkout -- <文件>      # 丢弃某文件的本地改动
```

> 提示：`status.showUntrackedFiles` 已设为 `no`，
> 因此 `dotfiles status` 不会显示 `$HOME` 下海量的未跟踪文件。

## 敏感信息处理

本项目采用 **模板 + 环境变量** 方案保护密钥：

1. **仓库内** 只存放带 `${占位符}` 的模板文件（`opencode.jsonc.template`、`config.toml.template`）
2. **真实密钥** 存放在 `~/.env`（已被 `.gitignore` 排除，权限 600）
3. **部署脚本** 读取 `~/.env` 并用 `sed` 将占位符替换为真实值，生成实际配置文件
4. 生成的配置文件（`opencode.jsonc`、`config.toml`）同样被 `.gitignore` 排除，**永不入库**

```
~/.env (真实密钥, 600)
   ↓ setup.sh 替换占位符
模板文件 ──→ 实际配置文件（不入库）
```

### 被排除的敏感路径

| 路径 | 原因 |
|------|------|
| `~/.ssh/` | SSH 私钥 |
| `~/.env` | API 密钥 |
| `~/.codex/config.toml` | DeepSeek API Key（模板见 `config.toml.template`） |
| `~/.config/opencode/opencode.jsonc` | Bark 推送密钥（模板见 `opencode.jsonc.template`） |
| `~/.claude/` | 会话数据、项目历史 |
| `~/.zsh_history`、`~/.zsh_sessions/` | 命令历史（可能含敏感命令） |
| `~/.gradle/`、`~/.cargo/`、`~/.rustup/`、`~/.npm/` 等 | 运行时缓存/凭证 |
| `~/.Trash/`、`~/.cache/`、`~/.local/` | 系统临时数据 |

## 支持的环境

- **macOS**：完整支持（Homebrew、zsh、Neovim、opencode、codex）
- **Linux (Arch 等)**：zsh / git / nvim 配置通用；`my-packages.txt` 为 Homebrew 格式，Arch 用户可参考 `bin/setup.sh` 逻辑自行适配 pacman

## 常见问题

### Q1: 检出时报 "error: The following untracked working tree files would be overwritten by checkout"

新机器上已有同名文件（如出厂自带的 `.zshrc`）。脚本会自动备份冲突文件为 `*.bak`；
若手动检出遇到此问题，可执行：

```bash
mv ~/.zshrc ~/.zshrc.bak
dotfiles checkout
```

### Q2: 换了机器/新装的配置如何生效？

重新执行部署脚本即可，幂等设计可重复运行：

```bash
bash ~/bin/setup.sh
```

### Q3: 想在另一台机器上修改配置并同步？

```bash
dotfiles pull --ff-only   # 先同步
# ... 修改配置 ...
dotfiles commit -m "说明" && dotfiles push
```

### Q4: 部署后 opencode / codex 无法启动？

检查 `~/.env` 是否存在且包含正确的 `BARK_KEY` / `DEEPSEEK_API_KEY`，
然后重新运行 `bash ~/bin/setup.sh` 重新生成配置。

## License

MIT
