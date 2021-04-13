#!/bin/bash

port_regex="^((6553[0-5])|(655[0-2][0-9])|(65[0-4][0-9]{2})|(6[0-4][0-9]{3})|([1-5][0-9]{4})|([1-9][0-9]{3})|([1-9][0-9]{2})|([1-9][0-9])|([1-9]))$"

ip_regex="^(((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){3})(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\/([0-9]$|[1-2][0-9]$|3[0-2])|$)"
ip6_regex="^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))(/[1-9][0-9])?$"

# Colors
cl_red='\033[0;31m'
cl_nc='\033[0m'
cl_cy='\e[36m'
cl_wh='\e[97m'
cl_lm='\e[95m'
cl_lg='\e[92m'

if [ -z "$nameserver" ]; then
    nameserver="1.1.1.1"
    echo "Nameserver is setted to \"$nameserver\""
else
    if [[ "$nameserver" =~ $ip_regex ]] || [[ "$nameserver" =~ $ip6_regex ]]; then
        echo "Nameserver is setted to \"$nameserver\""
    else
        echo -e "${cl_red}Nameserver is must be IPv4 or IPv6 address \"$nameserver\"${cl_nc}"
        exit 1
    fi
fi

if [ ! -z "$resolver_valid" ]; then
    if [[ "$resolver_valid" =~ [[:digit:]] ]]; then
        echo "DNS cache is setted to \"${resolver_valid}s\""
        resolver_valid="valid=${resolver_valid}s"
    else
        echo -e "${cl_red}resolver_valid is must be a number. \"${resolver_valid}\"${cl_nc}"
        exit 1
    fi
fi

port=${port-"8443"}

if [[ "$port" =~ $port_regex ]]; then
    if (lsof -i :$port | grep TCP); then
        echo -e "${cl_red}Port is already usage. Please select another port.${cl_nc}"
        exit 1
    else
        echo "Selected port is $port/tcp"
    fi
else
    echo -e "${cl_red}Port is must be between 0-65535${cl_nc}"
    exit 1
fi

if [ ! -z "$client_addr" ]; then
    if [[ "$client_addr" =~ $ip_regex ]] || [[ "$client_addr" =~ $ip6_regex ]]; then
        echo "Client addr is setted to \"$client_addr\" other requests will be deny"
        config_nginx_client_addr="
        allow $client_addr;
        deny all;
    "
    else
        echo -e "${cl_red}Client addr must be IPv4 or IPv6 address \"$client_addr\"${cl_nc}"
        exit 1
    fi
fi

source nginx/nginx.conf.sh

exit_trap() {
    echo -e "\t${cl_wh}Cheap tunnel service is closing.${cl_nc}"
    PGID=$(ps -o pgid= $$ | tr -d \ )
    kill -TERM -$PGID 2>/dev/null

    echo "Server is closed"
    exit 0
}
trap exit_trap INT EXIT

#Start nginx
echo "Starting nginx."
nginx &
NGINX_PID=$!
echo "Nginx started."
wait $NGINX_PID
if [ $? -eq 1 ]; then
    echo -e "${cl_red}\tNginx shutdown is not done in gracefully${cl_nc}"
    exit 1
fi
