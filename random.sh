#!/bin/bash

# Check if the number of arguments is correct
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <number_of_pods>"
    exit 1
fi

# Check if the argument is a number and within the range
if ! [[ "$1" =~ ^[0-5]$ ]]; then
    echo "Error: The argument must be a number between 0 and 5."
    exit 1
fi

# Source the .env file if it exists
if [ -f .env ]; then
    echo "Sourcing .env file..."
    source .env
else
    echo "Warning: .env file not found. Proceeding without it."
fi

# Unset the RUNNER_NAME environment variable
unset RUNNER_NAME

# Create logs directory
mkdir -p logs

# Loop to start the specified number of pods
for ((i = 1; i <= $1; i++)); do
    log_file="logs/pod_${i}.log"
    echo "Starting pod $i, logging to $log_file"
    ARTIFACT_DIR="$(pwd)/actions-runner-${i}"
    export ARTIFACT_DIR
    ./src/start.sh > "$log_file" 2>&1 &
done

# Wait for all background processes to finish
wait

echo "Started $1 pods."
