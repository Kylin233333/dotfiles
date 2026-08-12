# ============================================================================
# zinit 初始化
# ============================================================================
### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# ============================================================================
# 插件加载
# ============================================================================

# Git 别名（来自 ohmyzsh 的 git 插件）
zinit snippet OMZ::plugins/git/git.plugin.zsh

# sudo 插件：双击 ESC 添加 sudo
zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh

# 自动建议（zsh-autosuggestions）
zinit light zsh-users/zsh-autosuggestions

# 语法高亮（fast-syntax-highlighting）
zinit light zdharma-continuum/fast-syntax-highlighting

# ============================================================================
# 自定义提示符
# ============================================================================

setopt prompt_subst

autoload -Uz vcs_info
precmd() { vcs_info }

# 设置 vcs_info 格式（仅在 git 仓库中显示）
zstyle ':vcs_info:git:*' formats       ' %{%F{red}%}(%{%F{blue}%}%b%{%F{red}%})%{%f%}'
zstyle ':vcs_info:git:*' actionformats ' %{%F{red}%}(%{%F{blue}%}%b%{%F{red}%}|%{%F{yellow}%}%a%{%F{red}%})%{%f%}'

# 主要提示符：用户名@主机名 路径 (分支) 换行 状态符
PROMPT='%{%F{green}%}%n%{%f%} @ %{%F{cyan}%}%m%{%f%} in %{%F{yellow}%}%~%{%f%}${vcs_info_msg_0_}
%(?.%{%F{green}%}$%{%f%} .%{%F{red}%}$%{%f%} )'

# 右侧提示符：时间
RPROMPT='%{%F{cyan}%}[%*]%{%f%}'

#============================================================================
# 个人配置（alias、PATH）
# ============================================================================

#alias
alias python="python3"
alias pip="pip3"
alias vim="nvim"
alias ls="ls -G" 
alias ll="ls -lhG"
alias la="ls -laG"


## PATH
# HomeBrew-TsingHua
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"

# Proxy
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export all_proxy=http://127.0.0.1:7892


# dotfiles 裸仓库管理（~/.dotfiles，work-tree=$HOME）
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# 一键同步：dotpush=保存配置改动，dotbrew=记录新装软件
alias dotpush='$HOME/bin/dotpush'
alias dotbrew='$HOME/bin/dotbrew'
