#!/bin/bash -e

script_root="$(sh -c "cd \"${0%/*}\" && echo \"\$PWD\"")"

function usage() {
  echo -e "\033[1m$(basename $0 .sh)\033[0m - build and upload your game on steam"
  echo -e ""
  echo -e "\033[1mExample:\033[0m"
  echo -e "\t$0 -linux-depot-id=1001 -osx-depot-id=1002 -windows-depot-id=1003 -appid=1000 -game-path=/home/user/my-awesome-game -game-name=my-awesome-game -steam-username=username"
  echo -e ""
  echo -e "\033[1mOptions:\033[0m"
  echo -e "\t-game-name=GAME_NAME"
  echo -e "\t\tThe name of the game (without extension)"
  echo -e ""
  echo -e "\t-appid=APP_ID"
  echo -e "\t\tThe app id"
  echo -e ""
  echo -e "\t-game-path=GAME_PATH"
  echo -e "\t\tAbsolute path to the game directory (engine.cfg file)"
  echo -e ""
  echo -e "\t-linux-depot-id=LINUX_DEPOT_ID"
  echo -e "\t\tThe depot id for GNU/Linux platform"
  echo -e ""
  echo -e "\t-osx-depot-id=OSX_DEPOT_ID"
  echo -e "\t\tThe depot id for OSX platform"
  echo -e ""
  echo -e "\t-windows-depot-id=WINDOWS_DEPOT_ID"
  echo -e "\t\tThe depot id for Windows platform"
  echo -e ""
  echo -e "\t-steam-username=STEAM_USERNAME"
  echo -e "\t\tYour steam username"
  echo -e ""
  echo -e "\t-linux-lib32=LINUX_LIB32"
  echo -e "\t\tPath to your linux lib32 directory (optional)"
  echo -e ""
  echo -e "\t-linux-lib64=LINUX_LIB64"
  echo -e "\t\tPath to your linux lib64 directory (optional)"
}

export LINUX_DEPOT_ID
export OSX_DEPOT_ID
export WINDOWS_DEPOT_ID
export APP_ID
export GAME_PATH
export GAME_NAME
export STEAM_USERNAME
export LINUX_LIB32
export LINUX_LIB64

for arg in "$@"
do
  case "$arg" in
  -steam-username=*)
    STEAM_USERNAME=${arg//-steam-username=/}
    echo "Reading steam-username ${STEAM_USERNAME}"
    ;;
  -linux-depot-id=*)
    LINUX_DEPOT_ID=${arg//-linux-depot-id=/}
    echo "Reading linux-depot-id ${LINUX_DEPOT_ID}"
    ;;
  -linux-lib32=*)
    LINUX_LIB32=${arg//-linux-lib32=/}
    echo "Reading linux-lib32 ${LINUX_LIB32}"
    ;;
  -linux-lib64=*)
    LINUX_LIB64=${arg//-linux-lib64=/}
    echo "Reading linux-lib64 ${LINUX_LIB64}"
    ;;
  -osx-depot-id=*)
    OSX_DEPOT_ID=${arg//-osx-depot-id=/}
    echo "Reading osx-depot-id ${OSX_DEPOT_ID}"
    ;;
  -windows-depot-id=*)
    WINDOWS_DEPOT_ID=${arg//-windows-depot-id=/}
    echo "Reading windows-depot-id ${WINDOWS_DEPOT_ID}"
    ;;
  -appid=*)
    APP_ID=${arg//-appid=/}
    echo "Reading appid ${APP_ID}"
    ;;
  -game-path=*)
    GAME_PATH=${arg//-game-path=/}
    echo "Reading game-path ${GAME_PATH}"
    ;;
  -game-name=*)
    GAME_NAME=${arg//-game-name=/}
    echo "Reading game-name ${GAME_NAME}"
    ;;
  esac
done

if [ -z "${LINUX_DEPOT_ID}" -o -z "${OSX_DEPOT_ID}" -o -z "${WINDOWS_DEPOT_ID}" -o -z "${APP_ID}" -o -z "${GAME_PATH}" -o -z "${GAME_NAME}" -o -z "${STEAM_USERNAME}" ]
then
  usage
  exit -1
fi

# Preparing variables
STEAM_UPLOADER_CWD=${script_root}/steam-uploader/builder
STEAM_UPLOADER_SCRIPTS=${script_root}/steam-uploader/scripts
STEAM_UPLOADER_BINARY=${STEAM_UPLOADER_CWD}/steamcmd.sh
LINUX_SHELL_TEMPLATE=${script_root}/game.template.sh

OUTPUT=${script_root}/output/${APP_ID}
OUTPUT_LINUX=${OUTPUT}/${LINUX_DEPOT_ID}
LINUX_BINARY32=${OUTPUT_LINUX}/${GAME_NAME}32
LINUX_BINARY64=${OUTPUT_LINUX}/${GAME_NAME}64

LINUX_BINARY32_NAME=$(basename ${LINUX_BINARY32})
LINUX_BINARY64_NAME=$(basename ${LINUX_BINARY64})

LINUX_SHELL=${OUTPUT_LINUX}/${GAME_NAME}.sh

OUTPUT_OSX=${OUTPUT}/${OSX_DEPOT_ID}
OSX_BINARY=${OUTPUT_OSX}/${GAME_NAME}.app

OSX_BINARY_NAME=$(basename ${OSX_BINARY})

OUTPUT_WINDOWS=${OUTPUT}/${WINDOWS_DEPOT_ID}
WINDOWS_BINARY32=${OUTPUT_WINDOWS}/${GAME_NAME}32.exe
WINDOWS_BINARY64=${OUTPUT_WINDOWS}/${GAME_NAME}64.exe

WINDOWS_BINARY32_NAME=$(basename ${WINDOWS_BINARY32})
WINDOWS_BINARY64_NAME=$(basename ${WINDOWS_BINARY64})


ENGINE_FILE=${GAME_PATH}/engine.cfg
EXPORT_FILE=${GAME_PATH}/export.cfg
SDK_LINUX64=${script_root}/sdk/redistributable_bin/linux64
SDK_LINUX32=${script_root}/sdk/redistributable_bin/linux32
SDK_OSX=${script_root}/sdk/redistributable_bin/osx32/libsteam_api.dylib
SDK_WIN64=${script_root}/sdk/redistributable_bin/win64/steam_api64.dll
SDK_WIN64_LIB=${script_root}/sdk/redistributable_bin/win64/steam_api64.lib
SDK_WIN32=${script_root}/sdk/redistributable_bin/steam_api.dll
SDK_WIN32_LIB=${script_root}/sdk/redistributable_bin/steam_api.lib

LOG_DIR=${script_root}/logs
GODOT_BUILD_LOGS=${LOG_DIR}/godot-build.log

if [ ! -f "${ENGINE_FILE}" ]
then
  usage

  echo -e ""
  echo -e "\033[1mWARNING\033[0m - The directory does not contain 'engine.cfg' (or missing permission)"
  echo -e "\t\033[1m${GAME_PATH}\033[0m"
  echo -e ""

  exit -1
fi

if [ -n "${LINUX_LIB32}" -a ! -d "${LINUX_LIB32}" ]
then
  echo -e ""
  echo -e "\033[1mWARNING\033[0m - invalid linux lib32 directory (or missing permission)"
  echo -e "\t${LINUX_LIB32}"
fi

if [ -n "${LINUX_LIB64}" -a ! -d "${LINUX_LIB64}" ]
then
  echo -e ""
  echo -e "\033[1mWARNING\033[0m - invalid linux lib64 directory (or missing permission)"
  echo -e "\t${LINUX_LIB64}"
fi

if [ ! -d "${SDK_LINUX64}" -o ! -d "${SDK_LINUX32}" -o ! -f "${SDK_OSX}" -o ! -f "${SDK_WIN64}" -o ! -f "${SDK_WIN64_LIB}" -o ! -f "${SDK_WIN32}" -o ! -f "${SDK_WIN32_LIB}" ]
then
  echo -e ""
  echo -e "\033[1mWARNING\033[0m - sdk is not present (or missing permission)"
  echo -e "Following files should exist"
  echo -e "\t${SDK_LINUX32}"
  echo -e "\t${SDK_LINUX64}"
  echo -e "\t${SDK_OSX}"
  echo -e "\t${SDK_WIN64}"
  echo -e "\t${SDK_WIN64_LIB}"
  echo -e "\t${SDK_WIN32}"
  echo -e "\t${SDK_WIN32_LIB}"
  echo -e ""

  exit -1
fi

echo -e "Preparing output directory (${OUTPUT})"
rm -rf ${OUTPUT}

# vdf files
mkdir -p ${OUTPUT}
mkdir -p ${OUTPUT}/content
mkdir -p ${OUTPUT}/output
mkdir -p ${OUTPUT}/scripts

# Directory for linux
mkdir -p ${OUTPUT_LINUX}
mkdir -p ${OUTPUT_LINUX}/lib32
mkdir -p ${OUTPUT_LINUX}/lib64

if [ -n "${LINUX_LIB32}" ]
then
  cp -a ${LINUX_LIB32}/* ${OUTPUT_LINUX}/lib32
fi

if [ -n "${LINUX_LIB64}" ]
then
  cp -a ${LINUX_LIB64}/* ${OUTPUT_LINUX}/lib64
fi

# Directory for OSX
mkdir -p ${OUTPUT_OSX}

# Directory for Windows
mkdir -p ${OUTPUT_WINDOWS}

cat ${STEAM_UPLOADER_SCRIPTS}/app_build_template.vdf | sed \
  -e 's@__APPID__@'${APP_ID}'@gi' \
  -e 's@__GAME_DESCRIPTION__@'${GAME_NAME}'@gi' \
  -e 's@__LINUXDEPOTID__@'${LINUX_DEPOT_ID}'@gi' \
  -e 's@__OSXDEPOTID__@'${OSX_DEPOT_ID}'@gi' \
  -e 's@__WINDOWSDEPOTID__@'${WINDOWS_DEPOT_ID}'@gi' > ${OUTPUT}/scripts/app_build_${APP_ID}.vdf

cat ${STEAM_UPLOADER_SCRIPTS}/depot_build_template_linux.vdf | sed \
  -e 's@__CONTENT_ROOT__@'${OUTPUT_LINUX}'@gi' \
  -e 's@__BINARY32__@'${LINUX_BINARY32_NAME}'@gi' \
  -e 's@__BINARY64__@'${LINUX_BINARY64_NAME}'@gi' \
  -e 's@__SHELL__@'${LINUX_SHELL_NAME}'@gi' \
  -e 's@__DEPOTID__@'${LINUX_DEPOT_ID}'@gi' > ${OUTPUT}/scripts/depot_build_${LINUX_DEPOT_ID}.vdf

cat ${LINUX_SHELL_TEMPLATE} | sed \
  -e 's@__BINARY32__@'${LINUX_BINARY32_NAME}'@gi' \
  -e 's@__BINARY64__@'${LINUX_BINARY64_NAME}'@gi' > ${LINUX_SHELL}

chmod a+x ${LINUX_SHELL}

cat ${STEAM_UPLOADER_SCRIPTS}/depot_build_template_osx.vdf | sed \
  -e 's@__CONTENT_ROOT__@'${OUTPUT_OSX}'@gi' \
  -e 's@__BINARY__@'${OSX_BINARY_NAME}'@gi' \
  -e 's@__DEPOTID__@'${OSX_DEPOT_ID}'@gi' > ${OUTPUT}/scripts/depot_build_${OSX_DEPOT_ID}.vdf

cat ${STEAM_UPLOADER_SCRIPTS}/depot_build_template_windows.vdf | sed \
  -e 's@__CONTENT_ROOT__@'${OUTPUT_WINDOWS}'@gi' \
  -e 's@__BINARY32__@'${WINDOWS_BINARY32_NAME}'@gi' \
  -e 's@__BINARY64__@'${WINDOWS_BINARY64_NAME}'@gi' \
  -e 's@__DEPOTID__@'${WINDOWS_DEPOT_ID}'@gi' > ${OUTPUT}/scripts/depot_build_${WINDOWS_DEPOT_ID}.vdf

echo -e ""
echo -e "\033[1m>>> Building game binaries\033[0m using \033[1mGodot Engine\033[0m"
echo -e ""
echo -e "\033[1m>>> GNU/Linux 32/64bits\033[0m"
echo -e ""

# Put it in 32bits
sed -i -e 's@binary/64_bits=true@binary/64_bits=false@gi' "${EXPORT_FILE}"

echo -e "godot -path ${GAME_PATH} -export \"Linux X11\" \"${LINUX_BINARY32}\" 1> ${GODOT_BUILD_LOGS} 2>&1"
godot -path ${GAME_PATH} -export "Linux X11" "${LINUX_BINARY32}" 1>${GODOT_BUILD_LOGS} 2>&1

# Put it in 64bits
sed -i -e 's@binary/64_bits=false@binary/64_bits=true@gi' "${EXPORT_FILE}"

echo -e "godot -path ${GAME_PATH} -export \"Linux X11\" \"${LINUX_BINARY64}\" 1> ${GODOT_BUILD_LOGS} 2>&1"
godot -path ${GAME_PATH} -export "Linux X11" "${LINUX_BINARY64}" 1>${GODOT_BUILD_LOGS} 2>&1
cp -a ${SDK_LINUX64} ${OUTPUT_LINUX}/
cp -a ${SDK_LINUX32} ${OUTPUT_LINUX}/
echo ${APP_ID} > ${OUTPUT_LINUX}/steam_appid.txt

echo -e "Creating the shell script launcher (to include custom libraries)"

echo -e ""
echo -e "\033[1m>>> Mac OSX\033[0m"
echo -e ""

echo -e "godot -path ${GAME_PATH} -export \"Mac OSX\" \"${OSX_BINARY}\" 1>> ${GODOT_BUILD_LOGS} 2>&1"
godot -path ${GAME_PATH} -export "Mac OSX" "${OSX_BINARY}" 1>>${GODOT_BUILD_LOGS} 2>&1
cp -a ${SDK_OSX} ${OUTPUT_OSX}/
echo ${APP_ID} > ${OUTPUT_OSX}/steam_appid.txt

echo -e ""
echo -e "\033[1m>>> Windows Desktop 32/64bits\033[0m"
echo -e ""

# Put it in 32bits
sed -i -e 's@binary/64_bits=true@binary/64_bits=false@gi' "${EXPORT_FILE}"

echo -e "godot -path ${GAME_PATH} -export \"Windows Desktop\" \"${WINDOWS_BINARY32}\" 1>> ${GODOT_BUILD_LOGS} 2>&1"
godot -path ${GAME_PATH} -export "Windows Desktop" "${WINDOWS_BINARY32}" 1>>${GODOT_BUILD_LOGS} 2>&1

# Put it in 64bits
sed -i -e 's@binary/64_bits=false@binary/64_bits=true@gi' "${EXPORT_FILE}"

echo -e "godot -path ${GAME_PATH} -export \"Windows Desktop\" \"${WINDOWS_BINARY64}\" 1>> ${GODOT_BUILD_LOGS} 2>&1"
godot -path ${GAME_PATH} -export "Windows Desktop" "${WINDOWS_BINARY64}" 1>>${GODOT_BUILD_LOGS} 2>&1

cp -a ${SDK_WIN64} ${OUTPUT_WINDOWS}/
cp -a ${SDK_WIN64_LIB} ${OUTPUT_WINDOWS}/
cp -a ${SDK_WIN32} ${OUTPUT_WINDOWS}/
cp -a ${SDK_WIN32_LIB} ${OUTPUT_WINDOWS}/
echo ${APP_ID} > ${OUTPUT_WINDOWS}/steam_appid.txt

cd ${STEAM_UPLOADER_CWD}
echo -e ""
echo -e "\033[1m>>> Uploading binaries\033[0m using \033[1mSteam runtime\033[0m"
echo -e ""

${STEAM_UPLOADER_BINARY} +login ${STEAM_USERNAME} +run_app_build ${OUTPUT}/scripts/app_build_${APP_ID}.vdf +quit

cd -

echo "Application uploaded"


