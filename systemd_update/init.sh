#!/bin/bash
folder_name=systemd_update
file_name=update-minecraft

cat $folder_name/$file_name.service | sudo tee /etc/systemd/system/$file_name.service

cat $folder_name/$file_name.timer | sudo tee /etc/systemd/system/$file_name.timer

cat $folder_name/$file_name.sh | sudo tee /usr/bin/$file_name.sh
sudo chmod +x /usr/bin/$file_name.sh

sudo systemd-analyze verify /etc/systemd/system/$file_name.*
sudo systemctl start $file_name.timer
sudo systemctl enable $file_name.timer
sudo systemctl daemon-reload