#!/usr/bin/zsh

if [ ! -d "playdate" ]; then
  wget https://download.panic.com/playdate_sdk/Linux/PlaydateSDK-latest.tar.gz &&
  tar -xzf PlaydateSDK-latest.tar.gz
  cp -r PlaydateSDK-*/ ./playdate && rm -R PlaydateSDK-*/
  rm -rf *.tar.gz
fi

cmake ./CMakeLists.txt -B cmake-build-debug
cmake --build ./cmake-build-debug --target PlaydateTemplate -- -j 6