#!/bin/bash

if ! [ -d "/usr/local/bin" ]; then
  mkdir /usr/local/bin
fi
if ! [ -e "/usr/local/bin/bork" ]; then
  ln -s /usr/local/src/bork/bin/bork /usr/local/bin/bork
fi

## Shell completions

if [ -d "/usr/share/bash-completion/completions/" ]; then
  ln -s /usr/local/src/bork/pkg/bash_completions.sh /usr/share/bash-completion/completions/bork
fi
install_platform=$(uname -s)
if [ $install_platform = "Darwin" ]; then
  if ! [ -d "/usr/local/share/zsh/site-functions" ]; then
    mkdir -p /usr/local/share/zsh/site-functions
  fi
  ln -s /usr/local/src/bork/pkg/zsh_completions.sh /usr/local/share/zsh/site-functions/_bork
else
  if [ -d "/usr/share/zsh/site-functions/" ]; then
    ln -s /usr/local/src/bork/pkg/zsh_completions.sh /usr/share/zsh/site-functions/_bork
  fi
fi