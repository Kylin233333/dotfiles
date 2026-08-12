# dotfiles

个人开发环境配置文件集合，基于裸 git 仓库管理，支持多机部署与同步。

## 特性

- **裸仓库方案**：`~/.dotfiles` 为 `git init --bare` 仓库，work-tree 指向 `$HOME`，配置文件原地纳入版本管理，无需符号链接
- **一键部署**：`bin/setup.sh` 幂等脚本，新机器自动克隆、检出、写入 alias、生成敏感配置、安装 Homebrew 软件包
- **敏感信息隔离**：密钥以 `${占位符}` 形式存于模板文件，真实值保存在本地 `~/.env`（不入库）；部署脚本自动扫描仓库中所有占位符并生成/补充 `~/.env`
- **配置同步**：`dotpush` 一键保存配置改动，`dotbrew` 一键同步 Homebrew 软件清单
- **多平台**：macOS 完整支持，Linux 部分兼容

## 前置条件

- macOS（完整支持）或 Linux
- [Homebrew](https://brew.sh)（macOS）
- git

## 快速开始

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Kylin233333/dotfiles/master/bin/setup.sh) https://github.com/Kylin233333/dotfiles.git
```

部署完成后重新加载 shell：

```bash
source ~/.zshrc
```

详细部署与 Token 配置流程见[使用手册](doc/manual.md)。

## 目录结构

```
.
├── .zshrc                     # zsh 主配置
├── .gitconfig                 # git 全局配置
├── my-packages.txt            # Homebrew 软件包清单（dotbrew 维护）
├── bin/
│   ├── setup.sh               # 一键部署脚本
│   ├── dotpush                # 保存配置改动并推送
│   └── dotbrew                # 记录新装软件并推送
├── doc/
│   └── manual.md              # 使用手册
├── .config/                   # 各工具配置（nvim/opencode/btop/htop 等）
├── .codex/                    # codex 配置模板
└── .agents/                   # Claude 技能
```

## 日常使用

| 命令 | 用途 |
|------|------|
| `dotpush` | 保存全部已跟踪配置的改动并推送 |
| `dotbrew` | 重新生成软件清单并推送 |
| `dotfiles status` | 查看配置改动 |
| `dotfiles log --oneline` | 查看存档历史 |
| `dotfiles checkout -- <文件>` | 回滚单个配置 |

## 文档

- [使用手册](doc/manual.md)：部署、同步、Token 配置、回滚、FAQ

## License

[MIT](LICENSE)
