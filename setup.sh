#!/usr/bin/env zsh

mkdir -p ~/.gnupg
chown -R $(whoami) ~/.gnupg/
chmod 700 ~/.gnupg
cp .gnupg ~/.gnupg/gpg.conf
chmod 600 ~/.gnupg/*
