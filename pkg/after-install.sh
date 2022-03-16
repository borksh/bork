#!/bin/bash

if ! [ -d "/usr/local/bin" ]; then
  mkdir /usr/local/bin
fi
if ! [ -e "/usr/local/bin/bork" ]; then
  ln -s /usr/local/src/bork/bin/bork /usr/local/bin/bork
fi