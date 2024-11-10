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

if [[ "$OPERATING_SYSTEM" == "darwin" ]]; then
  darwin
elif [[ "$OPERATING_SYSTEM" != "linux" ]]; then
  linux
else
  log "github-runners is only supported in macOS or Linux distros"
  exit 1
fi

log "Prerequisites verified for ${OPERATING_SYSTEM}-${ARCHITECTURE}"
