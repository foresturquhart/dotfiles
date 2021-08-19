#!/usr/bin/env zsh

touch ~/.hushlogin

cp .gitignore ~/.gitignore
cp .gitconfig ~/.gitconfig
cp .dockerignore ~/.dockerignore

cp .zshrc ~/.zshrc

cp .curlrc ~/.curlrc
cp .editorconfig ~/.editorconfig
cp .inputrc ~/.inputrc
cp .screenrc ~/.screenrc
cp .tmux.conf ~/.tmux.conf
cp .wgetrc ~/.wgetrc

cp -R .ssh/ ~/.ssh

cp -R .gnupg/ ~/.gnupg
chown -R $(whoami) ~/.gnupg/
chmod 700 ~/.gnupg
chmod 600 ~/.gnupg/*

unset SSH_AGENT_PID
if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
  export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
fi
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >/dev/null

/opt/homebrew/bin/gpg --import < gpg.pub