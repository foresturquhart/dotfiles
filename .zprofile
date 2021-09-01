# Define defaults
export LANG=en_GB.UTF-8
export EDITOR="nano"
export NODE_ENV="development"

# Define Homebrew environment
export HOMEBREW_PREFIX="/opt/homebrew";
export HOMEBREW_CELLAR="${HOMEBREW_PREFIX}/Cellar";
export HOMEBREW_REPOSITORY="${HOMEBREW_PREFIX}";
export HOMEBREW_SHELLENV_PREFIX="${HOMEBREW_PREFIX}";
export PATH="${HOMEBREW_PREFIX}/opt/llvm/bin:${HOMEBREW_PREFIX}/opt/curl/bin:${HOMEBREW_PREFIX}/bin:${HOMEBREW_PREFIX}/sbin${PATH+:$PATH}";
export MANPATH="${HOMEBREW_PREFIX}/share/man${MANPATH+:$MANPATH}:";
export INFOPATH="${HOMEBREW_PREFIX}/share/info:${INFOPATH:-}";

# Define headers
export PKG_CONFIG_PATH="${HOMEBREW_PREFIX}/opt/curl/lib/pkgconfig"
export LDFLAGS="-L${HOMEBREW_PREFIX}/opt/curl/lib -I${HOMEBREW_PREFIX}/opt/curl/include -L${HOMEBREW_PREFIX}/opt/llvm/lib -Wl,-rpath,${HOMEBREW_PREFIX}/opt/llvm/lib -L${HOMEBREW_PREFIX}/opt/llvm/lib"
export CPPFLAGS="-I${HOMEBREW_PREFIX}/opt/llvm/include"

# Define user-defined paths
export PATH="${HOME}/bin:${HOME}/go/bin:${HOME}/.composer/vendor/bin:${PATH}"

# Load Python Version Manager
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"

# Load Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Autoselect Node version
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc