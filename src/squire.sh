#!/bin/bash

instance_id() {
  # Use randomly generated instance IDs without /dev/urandom (AWS format) as default runner names
  chars=({a..z})
  digits=({0..9})
  id_parts=()

  # Add 4 random lowercase letters
  for _ in {1..4}; do
    id_parts+=("${chars[RANDOM % ${#chars[@]}]}")
  done

  # Add 12 random digits
  for _ in {1..12}; do
    id_parts+=("${digits[RANDOM % ${#digits[@]}]}")
  done

  # Shuffle the array manually
  for ((i = ${#id_parts[@]} - 1; i > 0; i--)); do
    j=$((RANDOM % (i + 1)))
    tmp=${id_parts[i]}
    id_parts[i]=${id_parts[j]}
    id_parts[j]=$tmp
  done

  eid=$(IFS=; echo "${id_parts[*]}")
  echo "i-0$eid"
}

# # Prints one character at a time
# filler() {
# 	for ((j=0; j<$(tput cols); j++)); do
# 		printf '*'
# 	done
# }

filler() {
  local width
  if [[ -t 1 && -n "$TERM" ]]; then
    width=$(tput cols)
  else
    width=120
  fi
  printf '%*s\n' "$width" '' | tr ' ' '*'
}
