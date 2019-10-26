#!/bin/bash

# handle arguments
isUpload=0
isPush=0
isClean=0
isSilent=0
while getopts ":upcs" opt; do
  case $opt in
    u )
    echo 'User build!'
    isUpload=1
    ;;
    p )
    isPush=1
    ;;
    c )
    isClean=1
    ;;
    s )
    isSilent=1
    ;;
  esac
done

# build
source ./build/envsetup.sh
if [[ $isClean == 1 ]]; then
  echo 'Cleanning build'
  make clobber
fi
lunch aosip_dumpling-userdebug
if [[ $isSilent == 0 ]]; then
  telegram-send "Build started"
fi
mka kronic

# handle build file
if [[ $? = '0' ]]; then # if build succeeded
  if [[ $isSilent == 0 ]]; then
    telegram-send "Build done"
  fi
  if [[ $isUpload == 1 ]]; then
    if [[ $isSilent == 0 ]]; then
      telegram-send "Uploading build"
    fi
    echo "Uploading..."
    rclone move -v ~/Android/derp/out/target/product/dumpling/AOSiP*.zip 'GDrive:/builds'
    rclone move -v ~/Android/derp/out/target/product/dumpling/AOSiP*.zip.md5sum 'GDrive:/builds'
    if [ $? = '0' ]; then
      if [[ $isSilent == 0 ]]; then
        telegram-send "Upload done"
      fi
      dolphin 'gdrive:/idoybh2/builds/' &> /dev/null &
      disown
      exit 0
    fi
  elif [[ $isPush == 1 ]]; then
    read -p "Recovery push? y/[n] > " isRec
    echo "Pushing..."
    adb kill-server
    adb start-server
    if [[ $isRec = 'y' ]]; then
      adb push ~/Android/derp/out/target/product/dumpling/AOSiP*.zip /sdcard/Flash/Derp/
    else
      adb push ~/Android/derp/out/target/product/dumpling/AOSiP*.zip /storage/emulated/0/Flash/Derp/
    fi
    if [[ $? = '0' ]]; then
      rm ~/Android/derp/out/target/product/dumpling/AOSiP*.zip
      rm ~/Android/derp/out/target/product/dumpling/AOSiP*.zip.md5sum
      exit 0
    fi
  fi
  # Should only reach here if not handled yet
  mv ~/Android/derp/out/target/product/dumpling/AOSiP*.zip ~/Desktop/
  rm ~/Android/derp/out/target/product/dumpling/AOSiP*.zip.md5sum
  dolphin ~/Desktop/ &> /dev/null &
  disown
  exit 0
fi
# If build fails:
if [[ $isSilent == 0 ]]; then
  telegram-send "Build failed"
fi
exit $?
