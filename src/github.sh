#!/bin/bash

download_artifact() {
  # Navigate to ACTIONS_DIR directory, download (if not already available) and extract the runner
  # Checks script's current and parent directory in addition to the user's working directory
  log "Downloading artifact [v${ARTIFACT_VERSION}] to '${ACTIONS_DIR}'"
  artifact_file="actions-runner-${TARGET_BIN}-${ARTIFACT_VERSION}.${EXTENSION}"
  # TODO: Simplify this with an env var
  if [[ -f "${current_dir}/${artifact_file}" ]]; then
    artifact_path="${current_dir}/${artifact_file}"
    log "Existing artifact found at: ${artifact_path}"
  elif [[ -f "${parent_dir}/${artifact_file}" ]]; then
    artifact_path="${parent_dir}/${artifact_file}"
    log "Existing artifact found at: ${artifact_path}"
  elif [[ -f "${working_dir}/${artifact_file}" ]]; then
    artifact_path="${working_dir}/${artifact_file}"
    log "Existing artifact found at: ${artifact_path}"
  else
    if [[ "${SHOW_PROGRESS}" == "true" ]]; then
      flag="-OL"
    else
      flag="-sOL"
    fi
    download_url="${RELEASE_URL}/download/v${ARTIFACT_VERSION}/${artifact_file}"
    log "Download link: ${download_url}"
    start=$(date +%s)
    curl "$flag" "${download_url}"
    end=$(date +%s)
    time_taken=$((end - start))
    log "Downloaded artifact in ${time_taken} seconds"
    artifact_path="${artifact_file}"
  fi
  mkdir -p "${ACTIONS_DIR}" || { log "Failed to create ${ACTIONS_DIR}"; return 1; }
  cp "${artifact_path}" "${ACTIONS_DIR}" || { log "Failed to copy ${artifact_file} to ${ACTIONS_DIR}"; return 1; }
  cd "${ACTIONS_DIR}" || { log "Unable to cd into ${ACTIONS_DIR}"; return 1; }
  log "Extracting ${artifact_file} ..."
  tar xzf "./${artifact_file}" || { log "Failed to extract ${ACTIONS_DIR}"; return 1; }
}

cleanup() {
  # Sends notification (when env vars are set) and removes the runner from local and GitHub
  log "Removing runner..."
  ntfy_fn "Removing runner: '${RUNNER_NAME}'"
  telegram_fn "Removing runner: '${RUNNER_NAME}'"
  "./${CONFIG_SCRIPT}" remove --token "${REG_TOKEN}"
}

repo_level_runner() {
    # https://docs.github.com/en/rest/actions/self-hosted-runners#create-a-registration-token-for-a-repository
    REG_TOKEN=$(curl -sX POST \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: Bearer ${GIT_TOKEN}" \
        "https://api.github.com/repos/${GIT_OWNER}/${GIT_REPOSITORY}/actions/runners/registration-token" \
        | jq .token --raw-output)
    cd "$ACTIONS_DIR" || exit 1
    "./${CONFIG_SCRIPT}" --unattended \
        --work "${WORK_DIR}" \
        --labels "${LABELS}" \
        --token "${REG_TOKEN}" \
        --name "${RUNNER_NAME}" \
        --runnergroup "${RUNNER_GROUP}" \
        --url "https://github.com/${GIT_OWNER}/${GIT_REPOSITORY}"
}

org_level_runner() {
    # https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners#restricting-the-use-of-self-hosted-runners
    # https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners#self-hosted-runner-security
    # https://docs.github.com/en/rest/actions/self-hosted-runners#create-a-registration-token-for-an-organization
    REG_TOKEN=$(curl -sX POST \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: Bearer ${GIT_TOKEN}" \
        "https://api.github.com/orgs/${GIT_OWNER}/actions/runners/registration-token" \
        | jq .token --raw-output)
    cd "$ACTIONS_DIR" || exit 1
    "./${CONFIG_SCRIPT}" \
        --work "${WORK_DIR}" \
        --labels "${LABELS}" \
        --token "${REG_TOKEN}" \
        --name "${RUNNER_NAME}" \
        --runnergroup "${RUNNER_GROUP}" \
        --url "https://github.com/${GIT_OWNER}"
}
