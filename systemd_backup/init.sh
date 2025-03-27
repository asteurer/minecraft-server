#!/bin/bash
folder_name=systemd_backup
file_name=backup-minecraft

cat $folder_name/$file_name.sh | sudo tee /usr/bin/$file_name.sh
cat $folder_name/$file_name.service | sudo tee /etc/systemd/system/$file_name.service
cat $folder_name/$file_name.timer | sudo tee /etc/systemd/system/$file_name.timer

source b2.env # This assumes the file is in the project root

cat <<EOF | sudo tee /etc/sysconfig/$file_name
B2_ID=$B2_ID
B2_KEY=$B2_KEY
EOF

sudo systemd-analyze verify /etc/systemd/system/$file_name.*
sudo systemctl start $file_name.timer
sudo systemctl enable $file_name.timer
sudo systemctl daemon-reload