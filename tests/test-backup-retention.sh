#!/bin/bash
# Script to create directories for each day in the last year.
# This script is used to test backup-retention.sh functionality.

base_dir="/tmp/test"
current_time=$(date "+%s")
one_year_ago=$((current_time - 365*24*60*60))

while [ "$current_time" -ge "$one_year_ago" ]; do
    dir_name=$(date -d "@$current_time" "+%Y%m%d")
    mkdir -p "$base_dir/testing-$dir_name"
    touch -t "${dir_name}0000" "$base_dir/testing-$dir_name" # Set the timestamp for the directory to match the directory name
    current_time=$((current_time - 24*60*60)) # Decrement the current_time by one day (in seconds)
done

echo "Directories created for each day in the last year."
