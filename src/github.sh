#!/bin/bash

download_artifact() {
  # Navigate to ACTIONS_DIR directory, download and extract the runner
  log "Downloading artifact [v${ARTIFACT_VERSION}] to '${ACTIONS_DIR}'"
  mkdir -p "${ACTIONS_DIR}" && cd "${ACTIONS_DIR}"
  # TODO: Implement re-using the same artifact (zipped)
  if [[ "${SHOW_PROGRESS}" == "true" ]]; then
    flag="-OL"
  else
    flag="-sOL"
  fi
  download_url="${RELEASE_URL}/download/v${ARTIFACT_VERSION}/actions-runner-${TARGET_BIN}-${ARTIFACT_VERSION}.${EXTENSION}"
  log "Download link: ${download_url}"
  start_time=$(date +%s)
  curl "$flag" "${download_url}"
  end=$(date +%s)
  time_taken=$((end - start))
  log "Downloaded artifact in ${time_taken} seconds"
  tar xzf "./actions-runner-${TARGET_BIN}-${ARTIFACT_VERSION}.${EXTENSION}"
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
