FROM python:3-slim

RUN pip install dropbox

# We need cron, msmtp, sqlite3 and gnupg for backups
# gpg --list-keys is there to initiate gnupg, not required
RUN apt-get update \
    && apt-get install -y cron \
    && apt-get install -y msmtp \
    && apt-get install -y sqlite3 \
    && apt-get install -y gnupg  \
    && gpg --list-keys \ 
    && rm -rf /var/lib/apt/lists/*

COPY ./configs/backup_cron /etc/cron.d/backup_cron

RUN crontab /etc/cron.d/backup_cron

CMD ["cron", "-f"]
