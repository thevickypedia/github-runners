#!/bin/bash
# 'set -e' stops the execution of a script if a command or pipeline has an error.
# This is the opposite of the default shell behaviour, which is to ignore errors in scripts.
set -e

# todo: Add notification options (ntfy and telegram)
# todo: Update readme with env vars and usage

RELEASE_URL="https://github.com/actions/runner/releases"

# Get current directory
current_dir="$(dirname "$(realpath "$0")")"

# Functions for log, instance_id, latest_release_version and cleanup
source "${current_dir}/squire.sh"

# Source .env.sh file
if [ -f "${current_dir}/.env.sh" ]; then
	log "Sourcing .env.sh"
	source "${current_dir}/.env.sh"
fi
export ACTIONS_DIR="${ACTIONS_DIR:-${current_dir}/actions-runner}"

# Functions for repo_level_runner and org_level_runner
source "${current_dir}/config.sh"

# Sets OPERATING_SYSTEM, ARCHITECTURE, TARGET_BIN
source "${current_dir}/detector.sh"

# Default runner version is the latest release set by squire.sh
RUNNER_VERSION="${RUNNER_VERSION:-"$(latest_release_version)"}"

# Navigate to ACTIONS_DIR directory, download and extract the runner
log "Downloading artifact [v${RUNNER_VERSION}] to '${ACTIONS_DIR}'"

mkdir -p "${ACTIONS_DIR}" && cd "${ACTIONS_DIR}" \
&& curl -O -sL "${RELEASE_URL}/download/v${RUNNER_VERSION}/actions-runner-${TARGET_BIN}-${RUNNER_VERSION}.tar.gz" \
&& tar xzf "./actions-runner-${TARGET_BIN}-${RUNNER_VERSION}.tar.gz"

# Load env vars or set default values for RUNNER_NAME, RUNNER_GROUP, WORK_DIR and LABELS
RUNNER_NAME="${RUNNER_NAME:-"$(instance_id)"}"
RUNNER_GROUP="${RUNNER_GROUP:-"default"}"
WORK_DIR="${WORK_DIR:-"_work"}"
LABELS="${LABELS:-"${OPERATING_SYSTEM}-${ARCHITECTURE}"}"

# ************************************************ #
filler
prints=("Runner OS: '${OPERATING_SYSTEM}'" "Runner Architecture: '${ARCHITECTURE}'" "Runner Name: '${RUNNER_NAME}'" "Labels: '${LABELS}'")
width=$(tput cols)
for print in "${prints[@]}"; do
    len=${#print}
    padding=$(( (width - len) / 2 ))
    printf '%*s%s\n' "$padding" "" "$print"
done
filler
echo ""
# ************************************************ #

# Create a repository level self-hosted runner or an organization level self-hosted runner
if [[ -n "$GIT_REPOSITORY" ]]; then
	log "Creating a repository level self-hosted runner ['${RUNNER_NAME}'] for ${GIT_REPOSITORY}"
	repo_level_runner
else
	log "Creating an organization level self-hosted runner '${RUNNER_NAME}'"
	org_level_runner
fi

# todo: restarts - fix with different exit code
# Cleanup and exit
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# Start the runner
./run.sh & wait $!
