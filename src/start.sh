#!/bin/bash
# NOTE: This script should not be sourced
# 'set -e' stops the execution of a script if a command or pipeline has an error.
# This is the opposite of the default shell behaviour, which is to ignore errors in scripts.
set -e

export RELEASE_URL="https://github.com/actions/runner/releases"

# Get current, parent and working directory
script_path="$(realpath "$0")"
current_dir="$(dirname "$script_path")"
parent_dir="$(dirname "$current_dir")"
working_dir="$(pwd)"

# Functions for instance_id, latest_release_version and cleanup
source "${current_dir}/squire.sh"

# Functions for logging
unset VERBOSE
source "${current_dir}/log.sh"

arg_parser() {
  # Manual option parsing
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -e|--env)
        if [[ -n "$2" && "$2" != -* ]]; then
          env_file="$2"
          shift 2
          if [[ -f "$env_file" ]]; then
            info "Sourcing ${env_file}"
            source "${env_file}"
          else
            error "File does not exist -> $env_file"
          fi
        else
          error "Argument expected for $1"
        fi
        ;;
      -v|--verbose)
        export VERBOSE="true"
        # Re-source log script
        source "${current_dir}/log.sh"
        debug "Verbose mode enabled"
        shift
        ;;
      -h|--help)
        info "Usage: $0 [-e|--env <path/to/file>]"
        exit 0
        ;;
      *)
        warn "Use -h or --help for usage."
        error "Unknown option: $1"
        ;;
    esac
  done
}

# Source env_file file
ENV_FILE="${env_file:-${working_dir}/.env}"

if [[ $# -eq 0 ]]; then
  if [ -f "${ENV_FILE}" ]; then
    info "Sourcing ${ENV_FILE}"
    # ShellCheck directive to ignore non-constant source
    # shellcheck source=${working_dir}/.env
    source "${ENV_FILE}"
  fi
else
  arg_parser "$@"
fi

# Check mandatory flags required to spin up actions
if [[ -z "${GIT_REPOSITORY}" && -z "${GIT_OWNER}" ]]; then
  error "Environment variable missing: Please set either GIT_REPOSITORY or GIT_OWNER"
fi

if [[ -z "${GIT_TOKEN}" ]]; then
  error "Environment variable missing: GIT_TOKEN is required for authentication"
fi

# Normalize path
actions_dir="${ACTIONS_DIR:-${current_dir}/actions-runner}"
export ACTIONS_DIR="${actions_dir%/}"

# Script for all GitHub related functions
source "${current_dir}/github.sh"

# Sets OPERATING_SYSTEM, ARCHITECTURE, TARGET_BIN
source "${current_dir}/detector.sh"

# Install the requirements
# Sets EXTENSION, CONFIG_SCRIPT, RUN_SCRIPT
source "${current_dir}/prerequisite.sh"

# Script for all notification related functions
source "${current_dir}/notify.sh"

# Default runner version is the latest release set by squire.sh
export ARTIFACT_VERSION="${ARTIFACT_VERSION:-"$(latest_release_version)"}"

# Load env vars or set default values for RUNNER_NAME, RUNNER_GROUP, WORK_DIR and LABELS
RUNNER_NAME="${RUNNER_NAME:-"$(instance_id)"}"
RUNNER_GROUP="${RUNNER_GROUP:-"default"}"
# Normalize path
work_dir="${WORK_DIR:-"_work"}"
WORK_DIR="${WORK_DIR%/}"
LABELS="${LABELS:-"${OPERATING_SYSTEM}-${ARCHITECTURE}"}"

# ************************************************ #
filler
prints=("Runner OS: '${OPERATING_SYSTEM}'" "Runner Architecture: '${ARCHITECTURE}'" "Runner Name: '${RUNNER_NAME}'" "Labels: '${LABELS}'")
if [[ -t 1 && -n "$TERM" ]]; then
  width=$(tput cols)
else
  width=120
fi
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
   [[ -f "${ACTIONS_DIR}/${CONFIG_SCRIPT}" ]] &&
   [[ -f "${ACTIONS_DIR}/${RUN_SCRIPT}" ]]; then
  info "Existing configuration found. Re-using it..."
  reused="reusing existing configuration"
  cd "${ACTIONS_DIR}" || exit 1
else
  # Download artifact
  download_artifact
  if [[ -n "${GIT_REPOSITORY}" ]]; then
    info "Creating a repository level self-hosted runner ['${RUNNER_NAME}'] for ${GIT_REPOSITORY}"
    repo_level_runner
  else
    info "Creating an organization level self-hosted runner '${RUNNER_NAME}'"
    org_level_runner
  fi
  reused="creating a new configuration"
fi

ntfy_fn "Starting GitHub actions runner: '${RUNNER_NAME}' with ${reused}" &
telegram_fn "Starting GitHub actions runner: '${RUNNER_NAME}' with ${reused}" &

# Cleanup and exit
trap 'echo "Caught INT signal"; cleanup; exit 130' INT
trap 'echo "Caught TERM signal"; cleanup; exit 143' TERM

# Start the runner
"./${RUN_SCRIPT}" & wait $!
