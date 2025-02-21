# Overview

This contains a script for running a Minecraft server on Fedora, as well as an appliction called `uptimeinator`.

### `uptimeinator`
    This is an application that both backs up the game data to Backblaze, and updates my Cloudflare DNS records to point to my public IP. It runs once every 24 hours, and performs exponential backoff in case of failure.

### Maintaining the server

If you want to customize the Minecraft server, here are the unofficial docs: [Bedrock Dedicated Server](https://minecraft.fandom.com/wiki/Bedrock_Dedicated_Server)