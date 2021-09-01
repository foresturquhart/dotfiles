# Load Powerlevel10k instant prompt cache if found
[[ -r "${HOME}/.cache/p10k-instant-prompt-${(%):-%n}.zsh" ]] && source "${HOME}/.cache/p10k-instant-prompt-${(%):-%n}.zsh"

# Load Python Version Manager
eval "$(pyenv init -)"

# Load GnuPG agent
unset SSH_AGENT_PID
if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
  export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
fi
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >/dev/null

# Load Oh My Zsh
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
export ZSH="${HOME}/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
source "${ZSH}/oh-my-zsh.sh"

# Load Powerlevel10k
source "${HOME}/.p10k.zsh"

# Load user-defined functions
source "${HOME}/.zfunctions"