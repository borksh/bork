#!/bin/bash

if [ -L "/usr/local/bin/bork" ]; then
  rm /usr/local/bin/bork
fi

## Shell completions

if [ -L "/usr/share/bash-completion/completions/bork" ]; then
  rm /usr/share/bash-completion/completions/bork
fi
install_platform=$(uname -s)
if [ $install_platform = "Darwin" ]; then
  if [ -L "/usr/local/share/zsh/site-functions/_bork" ]; then
    rm /usr/local/share/zsh/site-functions/_bork
  fi
else
  if [ -L "/usr/share/zsh/site-functions/_bork" ]; then
    rm /usr/share/zsh/site-functions/_bork
  fi
fi