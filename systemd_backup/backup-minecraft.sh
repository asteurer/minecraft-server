#!/bin/bash

data_dir=/home/asteurer/minecraft-server/minecraft-data
file_name=$(date +%Y-%m-%d).tar.xz
bucket_name=asteurer-minecraft-backups

tar --xz -cf $file_name --exclude=bedrock_server-* $data_dir

B2_APPLICATION_KEY_ID=$B2_ID B2_APPLICATION_KEY=$B2_KEY b2 file upload $bucket_name $file_name $file_name