# ── Cyrodiil zshrc ───────────────────────────────────────────────────────────

# ── PATH ─────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# ── Editor ────────────────────────────────────────────────────────────────────
export EDITOR=nvim
export VISUAL=nvim

# ── History ───────────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# ── Completion ────────────────────────────────────────────────────────────────
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'  # case-insensitive

# ── Plugins ───────────────────────────────────────────────────────────────────
# (reinstalled separately — install with: sudo pacman -S zsh-autosuggestions zsh-syntax-highlighting)
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

[[ -f /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh && \
    bindkey '^[[A' history-substring-search-up   && \
    bindkey '^[[B' history-substring-search-down

# ── Prompt ────────────────────────────────────────────────────────────────────
autoload -Uz vcs_info
setopt PROMPT_SUBST

# Git: show branch, dirty marker
zstyle ':vcs_info:*'     enable git
zstyle ':vcs_info:git:*' formats      ' %F{#7a6a60}on%f %F{#c4845a}󰊢 %b%f%u%c'
zstyle ':vcs_info:git:*' actionformats ' %F{#7a6a60}on%f %F{#c4845a}󰊢 %b%f %F{#c45040}(%a)%f%u%c'
zstyle ':vcs_info:git:*' unstagedstr  ' %F{#c4904f}●%f'   # dirty
zstyle ':vcs_info:git:*' stagedstr    ' %F{#7a9a50}●%f'   # staged
zstyle ':vcs_info:git:*' check-for-changes true

precmd() { vcs_info }

# Prompt symbol: terracotta normally, red on failure
_prompt_symbol() {
    if [[ $? -eq 0 ]]; then
        echo '%F{#c4845a}❯%f'
    else
        echo '%F{#c45040}❯%f'
    fi
}

# Dir: shorten to last 2 segments, home as ~
# Dir icon: home or folder
_prompt_dir() {
    local full="${(%):-%~}"
    if [[ "$full" == "~" ]]; then
        echo "%F{#9a8a7a}󰋜 ~%f"
    else
        echo "%F{#9a8a7a}󰉋 $full%f"
    fi
}

# Two-line prompt: full path + git on line 1, ❯ on line 2
PROMPT='$(_prompt_dir)${vcs_info_msg_0_}
$(_prompt_symbol) '

# ── Keybinds ──────────────────────────────────────────────────────────────────
bindkey -e                        # emacs-style line editing
bindkey '^[[H'  beginning-of-line # Home
bindkey '^[[F'  end-of-line       # End
bindkey '^[[3~' delete-char       # Delete

# ── Aliases ───────────────────────────────────────────────────────────────────
alias ..='cd ..'
alias c='clear'
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias v='$EDITOR'
alias vim='$EDITOR'
alias wifi='nmtui'
alias lock='hyprlock'
alias update='sudo pacman -Syu'
alias shutdown='systemctl poweroff'
alias reboot='systemctl reboot'

# ── SSH — use xterm-256color so remote servers render correctly ───────────────
# Keeps xterm-ghostty locally; only overrides TERM for the remote session
ssh() { TERM=xterm-256color command ssh "$@" }

# nvm (optional)
[[ -f /usr/share/nvm/init-nvm.sh ]] && source /usr/share/nvm/init-nvm.sh
