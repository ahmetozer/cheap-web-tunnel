FROM alpine
WORKDIR /container

LABEL org.opencontainers.image.source="https://github.com/ahmetozer/cheap-web-tunnel"
RUN apk add bash nginx nginx-mod-stream  && \
    mkdir -p /run/nginx/ 
COPY . .
RUN chmod +x /container/entrypoint.sh
ENTRYPOINT ["/container/entrypoint.sh"]