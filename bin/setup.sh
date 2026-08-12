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
#   3. 写入 dotfiles / dotpush / dotbrew alias 到 ~/.zshrc
#   4. 扫描仓库中所有 ${占位符}，自动生成/补充 ~/.env
#      （新条目留空并注明来源文件，需手动填入真实值）
#   5. 由模板 + ~/.env 生成敏感配置（opencode / codex）
#   6. 按 my-packages.txt 安装缺失的 Homebrew 软件包
# ============================================================
set -euo pipefail

REPO_URL="${1:-https://github.com/Kylin233333/dotfiles.git}"
BARE="$HOME/.dotfiles"
DOT="git --git-dir=$BARE --work-tree=$HOME"

echo "==> 1/7 准备裸仓库 ($BARE)"
if [ ! -d "$BARE" ]; then
    git clone --bare "$REPO_URL" "$BARE"
else
    echo "    已存在，跳过克隆"
fi

echo "==> 2/7 拉取最新配置"
$DOT pull --ff-only 2>/dev/null || echo "    无远端更新或首次使用"

echo "==> 3/7 检出配置到 \$HOME"
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

echo "==> 4/7 写入 alias 到 ~/.zshrc"
if ! grep -q 'alias dotfiles=' "$HOME/.zshrc" 2>/dev/null; then
    cat >> "$HOME/.zshrc" <<'EOF'

# dotfiles 裸仓库管理（~/.dotfiles，work-tree=$HOME）
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# 一键同步：dotpush=保存配置改动，dotbrew=记录新装软件
alias dotpush='$HOME/bin/dotpush'
alias dotbrew='$HOME/bin/dotbrew'
EOF
    echo "    已追加 alias"
elif ! grep -q 'alias dotpush=' "$HOME/.zshrc" 2>/dev/null; then
    cat >> "$HOME/.zshrc" <<'EOF'

# 一键同步：dotpush=保存配置改动，dotbrew=记录新装软件
alias dotpush='$HOME/bin/dotpush'
alias dotbrew='$HOME/bin/dotbrew'
EOF
    echo "    已补充 dotpush / dotbrew alias"
else
    echo "    已存在，跳过"
fi

echo "==> 5/7 扫描配置中的占位符，生成/补充 ~/.env"
ENV_FILE="$HOME/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "# dotfiles 敏感配置（由 setup.sh 自动生成）" > "$ENV_FILE"
    echo "# 请为每个条目填入真实值，然后重新运行 setup.sh" >> "$ENV_FILE"
    echo >> "$ENV_FILE"
fi
# 遍历仓库中所有已跟踪文件，找出占位符（形如 花括号-变量名）
append=$(for f in $($DOT ls-files 2>/dev/null); do
    [ -f "$HOME/$f" ] || continue
    grep -oh '\${[A-Z_][A-Z0-9_]*}' "$HOME/$f" 2>/dev/null | sort -u | while IFS= read -r p; do
        var=$(printf '%s' "$p" | sed 's/^..//; s/.$//')
        if ! grep -q "^${var}=" "$ENV_FILE" 2>/dev/null; then
            echo "# [来源] $f"
            echo "${var}="
        fi
    done
done; true)
if [ -n "$append" ]; then
    echo "$append" >> "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    echo "    已在 ~/.env 追加以下条目（请填入真实值，来源见注释）:"
    echo "$append" | grep -v '^\#' | sed 's/^/      /'
else
    echo "    所有占位符均已在 ~/.env 中定义"
fi

echo "==> 6/7 生成敏感配置（模板 + ~/.env）"
if [ -f "$ENV_FILE" ]; then
    set -a; . "$ENV_FILE"; set +a
    if [ -f "$HOME/.config/opencode/opencode.jsonc.template" ]; then
        if [ -n "${BARK_KEY:-}" ]; then
            sed "s|\${BARK_KEY}|$BARK_KEY|g" \
                "$HOME/.config/opencode/opencode.jsonc.template" \
                > "$HOME/.config/opencode/opencode.jsonc"
            echo "    已生成 opencode.jsonc"
        else
            echo "    [跳过] BARK_KEY 为空，请先在 ~/.env 填写"
        fi
    fi
    if [ -f "$HOME/.codex/config.toml.template" ]; then
        if [ -n "${DEEPSEEK_API_KEY:-}" ]; then
            sed "s|\${DEEPSEEK_API_KEY}|$DEEPSEEK_API_KEY|g" \
                "$HOME/.codex/config.toml.template" \
                > "$HOME/.codex/config.toml"
            echo "    已生成 codex config.toml"
        else
            echo "    [跳过] DEEPSEEK_API_KEY 为空，请先在 ~/.env 填写"
        fi
    fi
    # 恢复 .claude/skills 软链接
    mkdir -p "$HOME/.claude/skills"
    ln -sfn ../../.agents/skills/agently-mail "$HOME/.claude/skills/agently-mail"
    echo "    已恢复 .claude/skills 软链接"
else
    echo "    未找到 ~/.env，跳过"
fi

echo "==> 7/7 安装 Homebrew 软件包"
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
echo "  dotpush     保存配置改动并推送"
echo "  dotbrew     记录新装软件并推送"
echo "  dotfiles status   查看改动"
echo "  dotfiles add <文件> 跟踪新配置"
echo "  （alias 已写入 ~/.zshrc，新开终端生效）"
echo "=========================================="
