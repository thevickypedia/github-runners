#!/bin/bash
# 'set -e' stops the execution of a script if a command or pipeline has an error.
# This is the opposite of the default shell behaviour, which is to ignore errors in scripts.
set -e

# Get to the current directory
current_dir="$(dirname "$(realpath "$0")")"
export SOURCE_DIR="${current_dir}/actions-runner"

source "${current_dir}/.env.sh"
source "${current_dir}/config.sh"
source "${current_dir}/detector.sh"
source "${current_dir}/squire.sh"

RUNNER_VERSION="${RUNNER_VERSION:-2.319.1}"
RELEASE_URL="https://github.com/actions/runner/releases"

mkdir actions-runner && cd actions-runner \
&& curl -O -L "${RELEASE_URL}/download/v${RUNNER_VERSION}/actions-runner-${TARGET_BIN}-${RUNNER_VERSION}.tar.gz" \
&& tar xzf "./actions-runner-${TARGET_BIN}-${RUNNER_VERSION}.tar.gz"

RUNNER_NAME="${RUNNER_NAME:-"$(instance_id)"}"
RUNNER_GROUP="${RUNNER_GROUP:-"default"}"
WORK_DIR="${WORK_DIR:-"_work"}"
LABELS="${LABELS:-"${OPERATING_SYSTEM}-${ARCHITECTURE}"}"
if [[ -n "$GIT_REPOSITORY" ]]; then
	log "Creating a repository level self-hosted runner ['${RUNNER_NAME}'] for ${GIT_REPOSITORY}"
	repo_level_runner
else
	log "Creating an organization level self-hosted runner '${RUNNER_NAME}'"
	org_level_runner
fi

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!
