#!/bin/bash

echo "Creating nginx.conf"
cat <<\EOF > /etc/nginx/nginx.conf
#user nginx;
daemon off;
worker_processes auto;
pcre_jit on;
error_log /var/log/nginx/error.log warn;
include /etc/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
EOF
if [ ! -z "$nameserver" ]; then
    echo -e "\tresolver $nameserver;" >> /etc/nginx/nginx.conf
fi
cat <<\EOF >> /etc/nginx/nginx.conf
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    server_tokens off;
    client_max_body_size 0;
    keepalive_timeout 65;
    sendfile on;
    tcp_nodelay on;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:2m;
    gzip_vary off;
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
    '$status $body_bytes_sent "$http_referer" '
    '"$http_user_agent" "$http_x_forwarded_for"';
    #access_log /var/log/nginx/access.log main;
    access_log /dev/null ;
    server {
        listen unix:/tmp/http.socket default_server;
        # Everything it can be proxied service
        location / {
            proxy_pass http://$host;
        }
    }
}


stream {
    # Specifies the main log format.
    log_format main 'host $ssl_preread_server_name client $remote_addr time $time_local '
    'proto $protocol stat $status sent $bytes_sent recv $bytes_received '
    'ses_time $session_time remote "$upstream_addr" '
    '"$upstream_bytes_sent" "$upstream_bytes_received" "$upstream_connect_time"';

    # access_log /var/log/nginx/stream.log main;
    #include allow.list;

    # Is HTTPS or not
    map $ssl_preread_protocol $upstream_hs {
        default unix:/tmp/http.socket;
        "TLSv1.3" $ssl_preread_server_name:443;
        "TLSv1.2" $ssl_preread_server_name:443;
        "TLSv1.1" $ssl_preread_server_name:443;
        "TLSv1" $ssl_preread_server_name:443;
    }
    # Check is request local service or not

    server {
EOF
echo -e "\tlisten ${port} reuseport so_keepalive=on;" >> /etc/nginx/nginx.conf

if [ ! -z "$nameserver" ]; then
    echo -e "\tresolver $nameserver;" >> /etc/nginx/nginx.conf
fi
cat <<\EOF >>       /etc/nginx/nginx.conf
        proxy_connect_timeout 1s;
        proxy_timeout 300m;
        preread_timeout 10m;
        proxy_socket_keepalive on;
        proxy_pass $upstream_hs;
        ssl_preread on;
    }
}
EOF