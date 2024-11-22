#!/bin/bash

source ./backup_restore_lib.sh

BACKUP_DIR=$1
RESTORE_DIR=$2
DECRYPTION_KEY=$3

validate_restore_params "$@"
restore
