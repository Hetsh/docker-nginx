FROM library/alpine:20200428
RUN apk add --no-cache \
    nginx=1.18.0-r0

# App user
ARG OLD_USER="nginx"
ARG APP_USER="http"
ARG	OLD_UID=100
ARG	APP_UID=33
ARG OLD_GROUP="nginx"
ARG APP_GROUP="http"
ARG	OLD_GID=101
ARG	APP_GID=33
RUN sed -i "/:$APP_UID/d" /etc/passwd && \
    sed -i "s|$OLD_USER:x:$OLD_UID:$OLD_GID|$APP_USER:x:$APP_UID:$APP_GID|" /etc/passwd && \
    sed -i "/:$APP_GID/d" /etc/group && \
    sed -i "s|$OLD_GROUP:x:$OLD_GID:$OLD_USER|$APP_GROUP:x:$APP_GID:|" /etc/group

# Volumes
ARG MODULE_DIR="/etc/nginx/modules"
ARG HOSTS_DIR="/etc/nginx/conf.d"
ARG SRV_DIR="/srv"
ARG LOG_DIR="/var/log/nginx"
RUN rm "$HOSTS_DIR/default.conf" && \
    chown -R "$APP_USER":"$APP_GROUP" "$HOSTS_DIR" "$SRV_DIR" "$LOG_DIR"
VOLUME ["$MODULE_DIR", "$HOSTS_DIR", "$SRV_DIR", "$LOG_DIR"]

# Configuration
ARG RUN_DIR="/run/nginx"
RUN ln -s "$LOG_DIR" "$APP_DIR/logs" && \
    mkdir "$RUN_DIR" && \
    chown -R "$APP_USER":"$APP_GROUP" "$RUN_DIR" && \
    sed -i "s|user $OLD_USER|user $APP_USER|" /etc/nginx/nginx.conf && \
    sed -i "s|group $OLD_GROUP|group $APP_GROUP|" /etc/nginx/nginx.conf

#      HTTP   HTTPS
EXPOSE 80/tcp 443/tcp

WORKDIR "$SRV_DIR"
ENTRYPOINT ["nginx", "-g", "daemon off;"]
