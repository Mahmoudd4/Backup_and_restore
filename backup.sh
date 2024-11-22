#!/bin/bash
source ./backup_restore_lib.sh

# Validate input parameters
validate_backup_params "$@"

# Assign command-line arguments to variables
SOURCE_DIR=$1
DEST_DIR=$2
ENCRYPTION_KEY=$3
DAYS=$4


# Perform the backup
backup
