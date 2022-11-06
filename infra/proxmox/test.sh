#!/bin/bash

########################################################################
# Script config & logging
########################################################################
set -eo pipefail
readonly LOG_FILE="$(pwd)/start.log"
touch $LOG_FILE
exec 2>&1 >$LOG_FILE

echo "LALALA" 1>&2