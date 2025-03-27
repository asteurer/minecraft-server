# Overview

This contains a script for running a Minecraft server on Fedora, as well as `systemd` services and timers that update and backup the server periodically.

### Restoring the backups
- Download the desired `.tar.xz` from BackBlaze
- Place the file in the root of the `minecraft-server` directory
- Rename the file to `minecraft-data.tar.xz`
- Run `tar -xf minecraft-data.tar.xz`
- Run `docker compose up -d`

### Maintaining the server

If you want to customize the Minecraft server, here are the unofficial docs: [Bedrock Dedicated Server](https://minecraft.fandom.com/wiki/Bedrock_Dedicated_Server)