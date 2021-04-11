#!/bin/bash

port_regex="^((6553[0-5])|(655[0-2][0-9])|(65[0-4][0-9]{2})|(6[0-4][0-9]{3})|([1-5][0-9]{4})|([1-9][0-9]{3})|([1-9][0-9]{2})|([1-9][0-9])|([1-9]))$"

# Colors
cl_red='\033[0;31m'
cl_nc='\033[0m'
cl_cy='\e[36m'
cl_wh='\e[97m'
cl_lm='\e[95m'
cl_lg='\e[92m'

if [[ "$listen_port" =~ $port_regex ]]; then
    if (lsof -i :$listen_port | grep TCP); then
        echo -e "${cl_red}Port is already usage. Please select another port.${cl_nc}"
        exit 1
    else
        echo -e "\tSelected port is $listen_port/tcp"
    fi
else
    echo -e "${cl_red}Port is must be between 0-65535${cl_nc}"
    exit 1
fi

exit_trap() {
    echo -e "\t${cl_wh}Cheap tunnel service is closing.${cl_nc}"
    PGID=$(ps -o pgid= $$ | tr -d \ )
    kill -TERM -$PGID 2>/dev/null

    echo "Server is closed"
    exit 0
}
trap exit_trap INT EXIT

#Start nginx
nginx &
NGINX_PID=$!
wait $NGINX_PID
if [ $? -eq 1 ]; then
    echo -e "${cl_red}\tNginx shutdown is not done in gracefully${cl_nc}"
    exit 1
fi