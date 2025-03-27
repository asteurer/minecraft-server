#!/bin/bash
folder_name=systemd_backup
file_name=backup-minecraft

cat $folder_name/$file_name.sh | sudo tee /usr/bin/$file_name.sh
cat $folder_name/$file_name.service | sudo tee /etc/systemd/system/$file_name.service
cat $folder_name/$file_name.timer | sudo tee /etc/systemd/system/$file_name.timer

# !!!IMPORTANT!!!
# The following env vars are required:
# - B2_ID: the b2 applcation id
# - B2_KEY: the b2 application key

cat <<EOF | sudo tee /etc/sysconfig/$file_name
B2_ID=$B2_ID
B2_KEY=$B2_KEY
EOF