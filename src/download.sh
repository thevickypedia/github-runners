#!/bin/bash

info "Fetching latest GitHub Actions Runner version..."
export LATEST_RUNNER_VERSION=$(curl -sL \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/actions/runner/releases/latest | jq .tag_name --raw-output)
info "Latest version is: ${LATEST_RUNNER_VERSION}"
export RUNNER_VERSION=${LATEST_RUNNER_VERSION#v}

latest_runner() {
    if [ ! -f ./actions-runner/bin/Runner.Listener ]; then
        info "GitHub Actions Runner is not installed."
        return 1
    fi
    # Outputs without the 'v' prefix
    CURRENT_VERSION=$(./actions-runner/bin/Runner.Listener --version)
    info "Current GitHub Actions Runner version is: ${CURRENT_VERSION}"
    if [ "${CURRENT_VERSION}" != "${LATEST_RUNNER_VERSION#v}" ]; then
        info "A new version of GitHub Actions Runner is available."
        return 1
    fi
    info "GitHub Actions Runner is up to date."
    # Return true
    return 0
}
