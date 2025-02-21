#!/bin/bash

# You must have the following environment variables defined in a .env file:
# CLOUDFLARE_API_KEY
# CLOUDFLARE_DNS_NAME
# CLOUDFLARE_DNS_RECORD_ID
# CLOUDFLARE_ZONE_ID
# BACKBLAZE_KEY_ID
# BACKBLAZE_KEY
# BACKBLAZE_BUCKET_NAME

set +a
source .env
set -a

local_mount_path=minecraft-data


# Install and enable Docker
sudo dnf -y update
sudo dnf -y install dnf-plugins-core
sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker

cat <<EOF > compose.yaml
name: minecraft-asteurer-com
services:
  minecraft-server:
    image: itzg/minecraft-bedrock-server
    ports:
      - 19132:19132/udp
    volumes:
      - ./$local_mount_path:/data
    environment:
      - EULA=TRUE
      - GAMEMODE=survival
      - DIFFICULTY=normal
    tty: true
    stdin_open: true
    restart: unless-stopped
  uptimeinator:
    image: ghcr.io/asteurer/minecraft-server-uptimeinator
    volumes:
      - ./$local_mount_path:/data
    environment:
      - CLOUDFLARE_API_KEY=$CLOUDFLARE_API_KEY
      - CLOUDFLARE_DNS_NAME=$CLOUDFLARE_DNS_NAME
      - CLOUDFLARE_DNS_RECORD_ID=$CLOUDFLARE_DNS_RECORD_ID
      - CLOUDFLARE_ZONE_ID=$CLOUDFLARE_ZONE_ID
      - BACKBLAZE_KEY_ID=$BACKBLAZE_KEY_ID
      - BACKBLAZE_KEY=$BACKBLAZE_KEY
      - BACKBLAZE_BUCKET_NAME=$BACKBLAZE_BUCKET_NAME
      - VOLUME_MOUNT_PATH=/data
EOF

sudo docker compose up -d