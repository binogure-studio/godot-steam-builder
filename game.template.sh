#!/bin/bash

arch=$(uname -m)
game_root="$(sh -c "cd \"${0%/*}\" && echo \"\$PWD\"")"

export LD_LIBRARY_PATH_TMP=${game_root}/lib32
export GAME_BINARY="__BINARY32__"

if [ "${arch}" == "x86_64" -o "${arch}" == "amd64" ]
then
  LD_LIBRARY_PATH_TMP=${game_root}/lib64
  GAME_BINARY="__BINARY64__"
fi

# Thank you NixOS user
LD_LIBRARY_PATH="${LD_LIBRARY_PATH_TMP}:${LD_LIBRARY_PATH}"

#!/bin/bash
if [ -z ${STEAM_RUNTIME} ]
then
	echo "WARNING: __GAME_NAME__ not launched within the steam runtime"
	echo "         This is likely incorrect and is not officially supported"
	echo "         Launching steam in 3 seconds with steam://rungameid/__APPLICATION_ID__"
	sleep 3
	steam "steam://rungameid/__APP_ID__"
	exit
fi


exec "${game_root}/${GAME_BINARY}" $@ > __GAME_NAME__.log
