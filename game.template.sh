#!/bin/bash

arch=$(uname -m)
game_root="$(sh -c "cd \"${0%/*}\" && echo \"\$PWD\"")"

export LD_LIBRARY_PATH=${game_root}/lib32
export GAME_BINARY="__BINARY32__"

if [ "${arch}" == "x86_64" -o "${arch}" == "amd64" ]
then
  LD_LIBRARY_PATH=${game_root}/lib64
  GAME_BINARY="__BINARY64__"
fi

exec "${game_root}/${GAME_BINARY}" $@
