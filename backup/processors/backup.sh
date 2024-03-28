#!/bin/bash

# Source environment variables
. $HOME/services/backup/processors/backup.env

# Logging Function
log() {
    local timestamp=$(date +"%Y-%m-%d %T")

    # Check if there is any input from a pipe
    if [ $# -eq 0 ]; then
        while IFS= read -r line; do
            echo "[$timestamp] $line"
        done
    else
        # No input from a pipe, just log the provided message
        local log_message="$*"
        echo "[$timestamp] $log_message"
    fi
}

# Shared Timestamp between tasks
export TIMESTAMP=$(date '+%Y%m%d-%H%M')

log "STARTING BACKUP $TIMESTAMP"

# We rm -rf on BACKUP_FOLDER, this is to prevent disasters in case the variable is not set
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/services/backup}"
BACKUP_FOLDER="${BACKUP_FOLDER:-$BACKUP_ROOT/backup}"


# Set up the trap to call the handle_exit function on script termination
# We execute send_email.sh regardless if backup.sh fails or not
function handle_exit() {
    exit_status=$?
    log "BACKUP EXITED WITH: $exit_status"
    export BACKUP_EXIT_STATUS=$exit_status 
    source $BACKUP_ROOT/processors/send_email.sh
}
trap 'handle_exit' EXIT

log "CREATING PASSPHRASE..."
openssl rand -base64 -out "$BACKUP_FOLDER/passphrase-$TIMESTAMP.txt" 32 2>&1 | log
#openssl rand -base64 -n 32 -out "$BACKUP_FOLDER/passphrase-$TIMESTAMP.txt" 
log "DONE..."

log "BACKING UP DATABASE..."
sqlite3 "$DATA_FOLDER/db.sqlite3" ".backup '$BACKUP_FOLDER/db-$TIMESTAMP.sqlite3'" 2>&1 | log
log "DONE..."

log "BACKING UP DATA FOLDER..." 
# Specify files to exclude
exclude_files=("db.sqlite3" "db.sqlite3-shm" "db.sqlite3-wal")
# Check if the folder exists
if [ -d "$DATA_FOLDER" ]; then
    tar --exclude="${exclude_files[0]}" --exclude="${exclude_files[1]}" --exclude="${exclude_files[2]}" -czf "$BACKUP_FOLDER/data-$TIMESTAMP.tar.gz" "$DATA_FOLDER" "$BACKUP_FOLDER/db-$TIMESTAMP.sqlite3" 2>&1 | log
    log "DONE..."
else
    log "WARNING: '$DATA_FOLDER' does not exist."
fi

log "ENCRYPTING..."
gpg --symmetric --batch --no-tty --cipher-algo AES256 -o "$BACKUP_FOLDER/data-$TIMESTAMP.tar.gz.gpg" --passphrase-file "$BACKUP_FOLDER/passphrase-$TIMESTAMP.txt" "$BACKUP_FOLDER/data-$TIMESTAMP.tar.gz" 2>&1 | log
log "DONE..."

log "UPLOADING TO DROPBOX..."
python $BACKUP_ROOT/processors/drop_upload.py $BACKUP_FOLDER $TIMESTAMP upload 2>&1 | log


if [ ${PIPESTATUS[0]} -eq 0 ]; then
    log "SUCCESS..."
    log "CLEANING OLD FILES IN DROPBOX"
    python $BACKUP_ROOT/processors/drop_upload.py $BACKUP_FOLDER $TIMESTAMP clean 2>&1 | log
else
    log "ERROR: UPLOAD FAILED"
    log "CLEANING BACKUP FOLDER..."
    rm -rf $BACKUP_ROOT/backup/*
    exit 1
fi



