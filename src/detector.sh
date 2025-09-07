#!/bin/bash

# NOTE: `uname -m` is more accurate and universal than `arch`
# See https://en.wikipedia.org/wiki/Uname
unamem="$(uname -m)"
case $unamem in
x86_64|amd64)
    architecture="x64";;
arm64)
    architecture="arm64";;
arm)
    architecture="arm";;
*)
    error "Unsupported architecture: $unamem"
    ;;
esac

unameu="$(tr '[:lower:]' '[:upper:]' <<< "$(uname)")"
if [[ $unameu == *DARWIN* ]]; then
    os_name="darwin"
    binary="osx-$architecture"
elif [[ $unameu == *LINUX* ]]; then
    os_name="linux"
    binary="linux-$architecture"
elif [[ $unameu == *WIN* || $unameu == MSYS* ]]; then
    # Should catch cygwin
    os_name="windows"
    binary="win-$architecture"
else
    error "Unsupported OS: $(uname)"
fi
export ARCHITECTURE="${architecture}"
export OPERATING_SYSTEM="${os_name}"
export TARGET_BIN="${binary}"
