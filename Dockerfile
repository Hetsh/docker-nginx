FROM amd64/alpine:20220715
RUN apk add --no-cache \
        nginx=1.22.0-r7

# App user
ARG OLD_USER="nginx"
ARG APP_USER="http"
ARG APP_UID=33
ARG OLD_GROUP="nginx"
ARG APP_GROUP="http"
ARG APP_GID=33
RUN sed -i "/:$APP_UID/d" /etc/passwd && \
    sed -i "s|$OLD_USER:x:[0-9]\+:[0-9]\+|$APP_USER:x:$APP_UID:$APP_GID|" /etc/passwd && \
    sed -i "/:$APP_GID/d" /etc/group && \
    sed -i "s|$OLD_GROUP:x:[0-9]\+:$OLD_USER|$APP_GROUP:x:$APP_GID:|" /etc/group

# Configuration
ARG SRV_DIR="/srv"
ARG HOST_DIR="/etc/nginx/http.d"
ARG NGINX_CONF="/etc/nginx/nginx.conf"
RUN sed -i "s|^user $OLD_USER|user $APP_USER|" "$NGINX_CONF" && \
    sed -i "s|^group $OLD_GROUP|group $APP_GROUP|" "$NGINX_CONF" && \
    chown -R "$APP_USER":"$APP_GROUP" "$SRV_DIR" "$HOST_DIR"

# Volumes
ARG CERT_DIR="/etc/certs"
ARG RUN_DIR="/run/nginx"
ARG LOG_DIR="/var/log/nginx"
RUN mkdir "$CERT_DIR" && \
    chown -R "$APP_USER":"$APP_GROUP" "$CERT_DIR" "$RUN_DIR" "$LOG_DIR"
VOLUME ["$CERT_DIR", "$RUN_DIR", "$LOG_DIR", "$SRV_DIR", "$HOST_DIR"]

#      HTTP   HTTPS
EXPOSE 80/tcp 443/tcp

WORKDIR "$SRV_DIR"
ENTRYPOINT ["nginx", "-g", "daemon off;"]
