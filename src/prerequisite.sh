#!/bin/bash

brew_check() {
  # Looks for brew installation and installs only if brew is not found
  if ! [ -x "$(command -v brew)" ]; then
    info "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  fi
}

darwin() {
  export HOMEBREW_NO_AUTO_UPDATE=1
  if ! [ -x "$(command -v jq)" ]; then
    brew_check
    info "Installing JQ"
    brew install jq
  fi
  if ! [ -x "$(command -v curl)" ]; then
    brew_check
    info "Installing Curl"
    brew install curl
  fi
  if ! [ -x "$(command -v realpath)" ]; then
    brew_check
    info "Installing coreutils"
    brew install coreutils
  fi
  if ! [ -x "$(command -v gh)" ]; then
    brew_check
    info "Installing gh"
    brew install gh
  fi
}

linux() {
  if ! [ -x "$(command -v jq)" ]; then
    info "Installing JQ"
    sudo apt-get install jq
  fi
  if ! [ -x "$(command -v curl)" ]; then
    info "Installing Curl"
    sudo apt-get install curl
  fi
  if ! [ -x "$(command -v gh)" ]; then
    info "Installing gh"
    sudo apt-get install gh
  fi
}

windows() {
  if ! [ -x "$(command -v jq)" ]; then
    info "Installing JQ"
    winget install jqlang.jq
  fi
  if ! [ -x "$(command -v curl)" ]; then
    info "Installing Curl"
    winget install curl.curl
  fi
  if ! [ -x "$(command -v gh)" ]; then
    info "Installing gh"
    winget install GitHub.cli
  fi
}

export EXTENSION="tar.gz"
export CONFIG_SCRIPT="config.sh"
export RUN_SCRIPT="run.sh"
if [[ "${CURRENT_PLATFORM}" == "darwin" ]]; then
  darwin
elif [[ "${CURRENT_PLATFORM}" == "linux" ]]; then
  linux
elif [[ "${CURRENT_PLATFORM}" == "windows" ]]; then
  windows
  export EXTENSION="zip"
  export CONFIG_SCRIPT="config.cmd"
  export RUN_SCRIPT="run.cmd"
else
  info "Unknown operating system: ${CURRENT_PLATFORM}"
  exit 1
fi

info "Prerequisites verified for ${CURRENT_PLATFORM}-${CPU_NAME}"
