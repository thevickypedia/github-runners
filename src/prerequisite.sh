brew_check() {
  # Looks for brew installation and installs only if brew is not found
  if ! [ -x "$(command -v brew)" ]; then
    echo "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  fi
}

darwin() {
  if ! [ -x "$(command -v jq)" ]; then
    brew_check
    brew install jq
  fi
  if ! [ -x "$(command -v curl)" ]; then
    brew_check
    brew install curl
  fi
  if ! [ -x "$(command -v realpath)" ]; then
    brew_check
    brew install coreutils
  fi
}

linux() {
  if ! [ -x "$(command -v jq)" ]; then
    sudo apt-get install jq
  fi
  if ! [ -x "$(command -v curl)" ]; then
    sudo apt-get install curl
  fi
}

export EXTENSION="tar.gz"
export CONFIG_SCRIPT="config.sh"
export RUN_SCRIPT="run.sh"
if [[ "$OPERATING_SYSTEM" == "darwin" ]]; then
  darwin
elif [[ "$OPERATING_SYSTEM" == "linux" ]]; then
  linux
else
  # todo: Add windows validations
  export EXTENSION="zip"
  export CONFIG_SCRIPT="config.cmd"
  export RUN_SCRIPT="run.cmd"
fi

log "Prerequisites verified for ${OPERATING_SYSTEM}-${ARCHITECTURE}"
