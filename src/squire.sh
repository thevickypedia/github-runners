log() {
  dt_stamp=$(date -u +"%Y-%m-%d %H:%M:%SZ")
  echo "${dt_stamp}: $1"
}

instance_id() {
  # Use randomly generated instance IDs (AWS format) as default runner names
  # Set to a UTF-8 compatible
  export LC_ALL=C.UTF-8
  # If this doesn't work for some reason, try using the below OR run 'locale -a' and use one that's available
  # export LC_ALL=en_US.UTF-8
  letters=$(tr -dc '[:lower:]' < /dev/urandom | head -c 4)
  digits=$(tr -dc '0-9' < /dev/urandom | head -c 12)
  eid=$(echo "$letters$digits" | fold -w1 | shuf | tr -d '\n')
  echo "i-0$eid"
}

latest_release_version() {
  version=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name)
  refined="${version#v}"
  echo "$refined"
}

filler() {
	for ((j=0; j<$(tput cols); j++)); do
		printf '*'
	done
}
