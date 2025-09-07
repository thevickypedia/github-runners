debug() {
  if [[ "${VERBOSE}" == "true" ]]; then
    dt_stamp=$(date -u +"%Y-%m-%d %H:%M:%SZ")
    echo "${dt_stamp}    DEBUG: $1"
  fi
}

info() {
  dt_stamp=$(date -u +"%Y-%m-%d %H:%M:%SZ")
  echo "${dt_stamp}    INFO: $1"
}

warn() {
  dt_stamp=$(date -u +"%Y-%m-%d %H:%M:%SZ")
  echo "${dt_stamp}    WARN: $1"
}

error() {
  dt_stamp=$(date -u +"%Y-%m-%d %H:%M:%SZ")
  echo "${dt_stamp}    ERROR: $1"
  exit 1
}
