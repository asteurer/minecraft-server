#!/bin/bash

sudo tee /usr/bin/update-minecraft.sh <<'EOF'
#!/bin/bash

log_file=/var/log/journal/update-minecraft.log
compose_file=/home/asteurer/compose.yaml

check_exit_code() {
    command_name=$1
    result=$2
    exit_code=$3
    if [ $exit_code -ne 0 ]; then
        echo "ERROR: '$command_name' failed with exit code $exit_code" >> $log_file
        echo result >> $log_file
        exit $exit_code
    else
        echo "SUCCESS: '$command_name'" >> $log_file
    fi
}

echo "##############################################" >> $log_file

echo $(date) >> $log_file

echo "Running 'docker compose down'..." >> $log_file
result=$(sudo docker compose -f $compose_file down 2>&1)
check_exit_code "docker compose down" $result $?

echo "Removing the 'itzg/minecraft-bedrock-server' docker image..." >> $log_file
result=$(sudo docker image rm -f itzg/minecraft-bedrock-server)
check_exit_code "docker rm itzg/minecraft-bedrock-server" $result $?

echo "Re-pulling and starting minecraft..." >> $log_file
result=$(sudo docker compose -f $compose_file up -d 2>&1)
check_exit_code "docker compose up" $result $?

echo >> $log_file
EOF

sudo tee /etc/systemd/system/update-minecraft.service << EOF
[Unit]
Description="Run the /usr/bin/update-minecraft.sh file"
After=network.target

[Service]
ExecStart=/usr/bin/update-minecraft.sh

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/update-minecraft.timer << EOF
[Unit]
Description="Run update-minecraft.service at 9AM UTC (4AM Central) on Wednesdays"

[Timer]
OnCalendar=Wed *-*-* 09:00:00

[Install]
WantedBy=multi-user.target
EOF

sudo chmod +x /usr/bin/update-minecraft.sh
sudo systemd-analyze verify /etc/systemd/system/update-minecraft.*
sudo systemctl start update-minecraft.timer
sudo systemctl enable update-minecraft.timer
sudo systemctl daemon-reload