[[ -r "${HOME}/.cache/p10k-instant-prompt-${(%):-%n}.zsh" ]] && source "${HOME}/.cache/p10k-instant-prompt-${(%):-%n}.zsh"

export HOMEBREW_PREFIX="/opt/homebrew";
export HOMEBREW_CELLAR="${HOMEBREW_PREFIX}/Cellar";
export HOMEBREW_REPOSITORY="${HOMEBREW_PREFIX}";
export MANPATH="${HOMEBREW_PREFIX}/share/man${MANPATH+:$MANPATH}:";
export INFOPATH="${HOMEBREW_PREFIX}/share/info:${INFOPATH:-}";

export PATH="${HOME}/.composer/vendor/bin:${HOME}/bin:${HOMEBREW_PREFIX}/bin:${HOMEBREW_PREFIX}/sbin:${PATH}"

unset SSH_AGENT_PID
if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
  export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
fi
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >/dev/null

export ZSH="${HOME}/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source "${ZSH}/oh-my-zsh.sh"

[[ ! -f "${HOME}/.p10k.zsh" ]] || source "${HOME}/.p10k.zsh"