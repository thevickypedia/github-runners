log() {
  dt_stamp=$(date -u +"%Y-%m-%d %H:%M:%SZ")
  echo "${dt_stamp}: $1"
}

instance_id() {
  # Use randomly generated instance IDs (AWS format) as default runner names
  # Set to a UTF-8 compatible locale if possible
  export LC_ALL=C.UTF-8

  # Attempt to generate random letters and digits
  if command -v pwgen &>/dev/null; then
    random_string=$(pwgen -A 4 1)
    random_digits=$(pwgen -0 12 1)
  elif [[ -e /dev/urandom ]]; then
  	random_string=$(tr -dc '[:lower:]' < /dev/urandom | head -c 4)
  	random_digits=$(tr -dc '0-9' < /dev/urandom | head -c 12)
  else
    # Fallback to Python for random generation
    random_string=$(python3 -c "import random, string; print(''.join(random.choices(string.ascii_lowercase, k=4)))")
    random_digits=$(python3 -c "import random; print(''.join(random.choices('0123456789', k=12)))")
  fi

  # Combine letters and digits
  eid="$random_string$random_digits"

  # Shuffle the combined string
  if command -v shuf &>/dev/null; then
    shuffled_eid=$(echo "$eid" | fold -w1 | shuf | tr -d '\n')
  else
    # Fallback to sorting for shuffling
    shuffled_eid=$(echo "$eid" | fold -w1 | sort -R | tr -d '\n')
  fi
  echo "i-0$shuffled_eid"
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
