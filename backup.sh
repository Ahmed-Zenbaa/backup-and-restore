#!/bin/bash

# Get the directory of the currently executing script
script_dir="$(dirname "$0")"

# Source the backup_restore_lib.sh script using the absolute path
source "$script_dir/backup_restore_lib.sh"

# Run the function to validate backup parameters
validate_backup_params "$@"

# Run the function to perform the backup
backup "$@"
