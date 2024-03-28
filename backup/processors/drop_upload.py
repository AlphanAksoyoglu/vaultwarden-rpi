import argparse
import os
import sys

from datetime import datetime, timedelta

import dropbox

REFRESH_TOKEN = os.environ["DBOX_REFRESH_TOKEN"]
APP_KEY= os.environ["DBOX_APP_KEY"]
APP_SECRET= os.environ["DBOX_APP_SECRET"]
APP_FOLDER= os.environ["DBOX_APP_FOLDER"]
DBOX_RETAIN_DAYS = int(os.environ["DBOX_RETAIN_DAYS"])


parser = argparse.ArgumentParser(description='Upload and/or Clean Dropbox')
parser.add_argument('backup_folder', type=str, help='The folder containing compressed backup')
parser.add_argument('backup_label', type=str, help='THe label for the backup, which is the timestamp')
parser.add_argument('method', type=str, help='upload or clean')
args = parser.parse_args()

backup_folder = args.backup_folder
backup_label = args.backup_label
method = args.method


backup_path = f"{backup_folder}/data-{backup_label}.tar.gz.gpg"

# Destination path in Dropbox (including the filename)
dropbox_file_path = f'/{APP_FOLDER}/data-{backup_label}.tar.gz.gpg'

# Create a Dropbox client
dbx = dropbox.Dropbox(
    app_key=APP_KEY,
    app_secret=APP_SECRET,
    oauth2_refresh_token=REFRESH_TOKEN
    )

# Upload the file
if method == "upload":
    with open(backup_path, 'rb') as f:
        dbx.files_upload(f.read(), dropbox_file_path)

    print(f"File uploaded to Dropbox (File Timestamp): {backup_label}")

if method == "clean":
    print(f"Cleaning up old backups from dropbox...")

    threshold_date = datetime.now() - timedelta(days=DBOX_RETAIN_DAYS)

    # Get a list of files in a specific folder (replace '/path/to/folder' with the desired folder)
    folder_path = f'/{APP_FOLDER}'
    result = dbx.files_list_folder(folder_path)

    # Loop through each file and delete files older than the specified date
    for entry in result.entries:
        if isinstance(entry, dropbox.files.FileMetadata):
            file_modified_time = entry.server_modified
            if file_modified_time < threshold_date:
                # Delete the file
                dbx.files_delete_v2(entry.path_display)
                print(f"Deleted: {entry.name}")