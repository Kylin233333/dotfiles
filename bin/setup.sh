#!/usr/bin/env bash
# ============================================================
# dotfiles 一键部署脚本（幂等，可重复执行）
#
# 用法:
#   新机器:  bash <(curl -fsSL <raw-url>/bin/setup.sh) <仓库地址>
#   已有配置: ~/bin/setup.sh
#
# 功能:
#   1. 克隆/更新 ~/.dotfiles 裸仓库
#   2. 检出全部配置到 $HOME（冲突文件自动备份）
#   3. 写入 dotfiles alias 到 ~/.zshrc
#   4. 由模板 + ~/.env 生成敏感配置（opencode / codex）
#   5. 按 my-packages.txt 安装缺失的 Homebrew 软件包
# ============================================================
set -euo pipefail

REPO_URL="${1:-https://github.com/Kylin233333/dotfiles.git}"
BARE="$HOME/.dotfiles"
DOT="git --git-dir=$BARE --work-tree=$HOME"

echo "==> 1/6 准备裸仓库 ($BARE)"
if [ ! -d "$BARE" ]; then
    git clone --bare "$REPO_URL" "$BARE"
else
    echo "    已存在，跳过克隆"
fi

echo "==> 2/6 拉取最新配置"
$DOT pull --ff-only 2>/dev/null || echo "    无远端更新或首次使用"

echo "==> 3/6 检出配置到 \$HOME"
if ! $DOT checkout 2>/dev/null; then
    echo "    检出冲突，自动备份冲突文件..."
    $DOT checkout 2>&1 | sed -n 's/.*would be overwritten by checkout: \([^ ]*\).*/\1/p' \
        | sort -u | while IFS= read -r f; do
            if [ -e "$HOME/$f" ]; then
                mv "$HOME/$f" "$HOME/$f.bak"
                echo "    已备份 $f -> $f.bak"
            fi
        done
    $DOT checkout
fi
$DOT config status.showUntrackedFiles no

echo "==> 4/6 写入 dotfiles alias 到 ~/.zshrc"
if ! grep -q 'alias dotfiles=' "$HOME/.zshrc" 2>/dev/null; then
    cat >> "$HOME/.zshrc" <<'EOF'

# dotfiles 裸仓库管理（~/.dotfiles，work-tree=$HOME）
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
EOF
    echo "    已追加 alias"
else
    echo "    已存在，跳过"
fi

echo "==> 5/6 生成敏感配置（模板 + ~/.env）"
if [ -f "$HOME/.env" ]; then
    set -a; . "$HOME/.env"; set +a
    if [ -f "$HOME/.config/opencode/opencode.jsonc.template" ]; then
        sed "s|\${BARK_KEY}|$BARK_KEY|g" \
            "$HOME/.config/opencode/opencode.jsonc.template" \
            > "$HOME/.config/opencode/opencode.jsonc"
        echo "    已生成 opencode.jsonc"
    fi
    if [ -f "$HOME/.codex/config.toml.template" ]; then
        sed "s|\${DEEPSEEK_API_KEY}|$DEEPSEEK_API_KEY|g" \
            "$HOME/.codex/config.toml.template" \
            > "$HOME/.codex/config.toml"
        echo "    已生成 codex config.toml"
    fi
    # 恢复 .claude/skills 软链接
    mkdir -p "$HOME/.claude/skills"
    ln -sfn ../../.agents/skills/agently-mail "$HOME/.claude/skills/agently-mail"
    echo "    已恢复 .claude/skills 软链接"
else
    echo "    未找到 ~/.env，跳过（请参考 README 手动创建）"
fi

echo "==> 6/6 安装 Homebrew 软件包"
if command -v brew >/dev/null 2>&1 && [ -f "$HOME/my-packages.txt" ]; then
    installed=0
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        case "$line" in \#*) continue ;; esac
        case "$line" in
            cask:*)
                pkg="${line#cask:}"
                brew list --cask "$pkg" >/dev/null 2>&1 || { brew install --cask "$pkg"; installed=$((installed+1)); } ;;
            *)
                brew list --formula "$line" >/dev/null 2>&1 || { brew install "$line"; installed=$((installed+1)); } ;;
        esac
    done < "$HOME/my-packages.txt"
    echo "    本次新安装 $installed 个包"
else
    echo "    未安装 Homebrew 或缺少 my-packages.txt，跳过"
fi

echo ""
echo "=========================================="
echo "部署完成！常用操作:"
echo "  dotfiles status   查看改动"
echo "  dotfiles add <文件> 跟踪新配置"
echo "  dotfiles commit -m '...'  提交"
echo "  dotfiles push / pull   同步"
echo "  （alias 已写入 ~/.zshrc，新开终端生效）"
echo "=========================================="
