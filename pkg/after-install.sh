#!/bin/bash

if ! [[ -e "/usr/local/bin/bork" ]]; then
  ln -s /usr/local/src/bork/bin/bork /usr/local/bin/bork
fi