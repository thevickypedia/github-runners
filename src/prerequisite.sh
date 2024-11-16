brew_check() {
  # Looks for brew installation and installs only if brew is not found
  if ! [ -x "$(command -v brew)" ]; then
    log "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  fi
}

darwin() {
  if ! [ -x "$(command -v jq)" ]; then
    brew_check
    log "Installing JQ"
    brew install jq
  fi
  if ! [ -x "$(command -v curl)" ]; then
    brew_check
    log "Installing Curl"
    brew install curl
  fi
  if ! [ -x "$(command -v realpath)" ]; then
    brew_check
    log "Installing coreutils"
    brew install coreutils
  fi
}

linux() {
  if ! [ -x "$(command -v jq)" ]; then
    log "Installing JQ"
    sudo apt-get install jq
  fi
  if ! [ -x "$(command -v curl)" ]; then
    log "Installing Curl"
    sudo apt-get install curl
  fi
}

windows() {
  if ! [ -x "$(command -v jq)" ]; then
    log "Installing JQ"
    winget install jqlang.jq
  fi
  if ! [ -x "$(command -v curl)" ]; then
    log "Installing Curl"
    winget install curl.curl
  fi
}

export EXTENSION="tar.gz"
export CONFIG_SCRIPT="config.sh"
export RUN_SCRIPT="run.sh"
if [[ "${OPERATING_SYSTEM}" == "darwin" ]]; then
  darwin
elif [[ "${OPERATING_SYSTEM}" == "linux" ]]; then
  linux
elif [[ "${OPERATING_SYSTEM}" == "windows" ]]; then
  windows
  export EXTENSION="zip"
  export CONFIG_SCRIPT="config.cmd"
  export RUN_SCRIPT="run.cmd"
else
  log "Unknown operating system: ${OPERATING_SYSTEM}"
  exit 1
fi

log "Prerequisites verified for ${OPERATING_SYSTEM}-${ARCHITECTURE}"
