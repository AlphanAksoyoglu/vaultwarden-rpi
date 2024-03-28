#!/bin/bash

# We rm -rf on BACKUP_FOLDER, this is to prevent disasters in case the variable is not set
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/services/backup}"
BACKUP_FOLDER="${BACKUP_FOLDER:-$BACKUP_ROOT/backup}"

log "STARTING EMAIL PROCESS..."

smtp_logfile="$HOME/.msmtp.log"

if [ "$BACKUP_EXIT_STATUS" -eq 0 ]; then
    log "BACKUP WAS SUCCESSFUL..."

    log "PREPARING MESSAGE..."
    mail_header="Subject: [SUCCESS] Backup On $TIMESTAMP\n\nTodays Backup Completed Successfully\n"
    echo -e "$mail_header" > "$BACKUP_FOLDER/message.txt"
    cat "$BACKUP_FOLDER/passphrase-$TIMESTAMP.txt" >> "$BACKUP_FOLDER/message.txt"

    log "SENDING E-MAIL..."
    msmtp -a gmail $EMAIL < "$BACKUP_FOLDER/message.txt"

else
    log "BACKUP WAS NOT SUCCESSFUL..."
    log "PREPARING MESSAGE..."
    mail_header="Subject: [FAILED] Backup On $TIMESTAMP\n\nTodays Backup Was Not Successful\n"
    echo -e "$mail_header" > "$BACKUP_FOLDER/message.txt"
    cat "$BACKUP_ROOT/logs/backup_ephem.log" >> "$BACKUP_FOLDER/message.txt"
    
    log "SENDING E-MAIL..."
    msmtp -a gmail $EMAIL < "$BACKUP_FOLDER/message.txt"
fi

log "CHECKING STATUS..."
last_line=$(tail -n 1 "$smtp_logfile")
smtpstatus_line=$(echo "$last_line" | grep -o 'smtpstatus=[0-9]*')
smtpstatus_value=$(echo "$smtpstatus_line" | cut -d'=' -f2)

if [ "$smtpstatus_value" -eq 250 ]; then
    log "SMTP Status is 250. Mail sent..."
else
    log "SMTP Status is not 250. The last line is: $last_line"
fi

log "CLEANING BACKUP FOLDER..."

rm -rf $BACKUP_ROOT/backup/*






