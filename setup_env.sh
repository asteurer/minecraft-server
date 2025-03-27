#!/bin/bash

# !!!IMPORTANT!!!
# The following env vars must be stored in './b2.env':
# - B2_ID: the b2 applcation id
# - B2_KEY: the b2 application key

sudo dnf -y update

# Install and set up Docker
sudo dnf -y install dnf-plugins-core
sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo docker compose up -d

# Install Backblaze B2 CLI
curl -Lo b2 https://github.com/Backblaze/B2_Command_Line_Tool/releases/latest/download/b2-linux
chmod +x b2
sudo mv b2 /usr/local/bin

# Run the systemd service initialization scripts
bash systemd_backup/init.sh
bash systemd_update/init.sh