FROM alpine
WORKDIR /container
COPY . .
LABEL org.opencontainers.image.source="https://github.com/ahmetozer/cheap-web-tunnel"
RUN apk add bash nginx nginx-mod-stream nginx-mod-http-lua && \
    mkdir -p /run/nginx/ && \
    chmod +x /container/entrypoint.sh
ENTRYPOINT ["/container/entrypoint.sh"]