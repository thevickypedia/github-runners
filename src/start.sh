#!/bin/bash
# 'set -e' stops the execution of a script if a command or pipeline has an error.
# This is the opposite of the default shell behaviour, which is to ignore errors in scripts.
set -e

export RELEASE_URL="https://github.com/actions/runner/releases"

# Get current and working directory
current_dir="$(dirname "$(realpath "$0")")"
working_dir="$(pwd)"

# Functions for log, instance_id, latest_release_version and cleanup
source "${current_dir}/squire.sh"

# Source env_file file
ENV_FILE="${env_file:-${working_dir}/.env}"

if [ -f "${ENV_FILE}" ]; then
	log "Sourcing ${ENV_FILE}"
	# ShellCheck directive to ignore non-constant source
	# shellcheck source=${working_dir}/.env
	source "${ENV_FILE}"
fi
export ACTIONS_DIR="${ACTIONS_DIR:-${current_dir}/actions-runner}"

# Script for all GitHub related functions
source "${current_dir}/github.sh"

# Sets OPERATING_SYSTEM, ARCHITECTURE, TARGET_BIN
source "${current_dir}/detector.sh"

# Install the requirements
source "${current_dir}/prerequisite.sh"

# Script for all notification related functions
source "${current_dir}/notify.sh"

# Default runner version is the latest release set by squire.sh
export ARTIFACT_VERSION="${ARTIFACT_VERSION:-"$(latest_release_version)"}"

# Download artifact
download_artifact

# Load env vars or set default values for RUNNER_NAME, RUNNER_GROUP, WORK_DIR and LABELS
RUNNER_NAME="${RUNNER_NAME:-"$(instance_id)"}"
RUNNER_GROUP="${RUNNER_GROUP:-"default"}"
WORK_DIR="${WORK_DIR:-"_work"}"
LABELS="${LABELS:-"${OPERATING_SYSTEM}-${ARCHITECTURE}"}"
REUSE_EXISTING="${REUSE_EXISTING:-"false"}"

# ************************************************ #
filler
prints=("Runner OS: '${OPERATING_SYSTEM}'" "Runner Architecture: '${ARCHITECTURE}'" "Runner Name: '${RUNNER_NAME}'" "Labels: '${LABELS}'" "Reuse flag: '${REUSE_EXISTING}'")
width=$(tput cols)
for print in "${prints[@]}"; do
    len=${#print}
    padding=$(( (width - len) / 2 ))
    printf '%*s%s\n' "$padding" "" "$print"
done
filler
echo ""
# ************************************************ #

if [[ -d "${ACTIONS_DIR}" ]] &&
   [[ -f "${ACTIONS_DIR}/.credentials" ]] &&
   [[ -f "${ACTIONS_DIR}/.credentials_rsaparams" ]] &&
   [[ -f "${ACTIONS_DIR}/config.sh" ]] &&
   [[ -f "${ACTIONS_DIR}/run.sh" ]]; then
     if [[ "$REUSE_EXISTING" == "true" || "$REUSE_EXISTING" == "1" ]]; then
        log "Existing configuration found. Re-using it..."
        reused="reusing existing configuration"
        cd "${ACTIONS_DIR}" || exit 1
     else
        filler
        log "WARNING::Runner cannot start due to existing configuration present!!"
        log "WARNING::Please cleanup existing '${ACTIONS_DIR}' manually or set 'REUSE_EXISTING=true'"
        filler
     fi
else
  if [[ -n "$GIT_REPOSITORY" ]]; then
    log "Creating a repository level self-hosted runner ['${RUNNER_NAME}'] for ${GIT_REPOSITORY}"
    repo_level_runner
  else
    log "Creating an organization level self-hosted runner '${RUNNER_NAME}'"
    org_level_runner
  fi
  reused="creating a new configuration"
fi

ntfy_fn "Starting GitHub actions runner: '${RUNNER_NAME}' with ${reused}" &
telegram_fn "Starting GitHub actions runner: '${RUNNER_NAME}' with ${reused}" &

# Cleanup and exit
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# Start the runner
./run.sh & wait $!
