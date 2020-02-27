FROM library/alpine:20200122
RUN apk add --no-cache \
    nginx=1.16.1-r8

# App user
ARG APP_USER="http"
ARG	APP_UID=33
ARG APP_GROUP="http"
ARG	APP_GID=33
RUN sed -i "s|nginx:x:100:101|$APP_USER:x:$APP_UID:$APP_GID|" /etc/passwd && \
    sed -i "s|nginx:x:101|$APP_GROUP:x:$APP_GID|" /etc/group

# Volumes
ARG CONF_DIR="/etc/nginx/conf.d"
ARG SRV_DIR="/srv"
ARG LOG_DIR="/var/log/nginx"
RUN chown -R "$APP_USER":"$APP_GROUP" "$CONF_DIR" "$SRV_DIR" "$LOG_DIR"
VOLUME ["$CONF_DIR", "$SRV_DIR", "$LOG_DIR"]

# Configuration
RUN ln -s "$LOG_DIR" "$APP_DIR/logs" && \
    sed -i "s|user nginx|user $APP_USER|" /etc/nginx/nginx.conf

#      HTTP   HTTPS
EXPOSE 80/tcp 443/tcp

WORKDIR "$SRV_DIR"
ENTRYPOINT exec nginx -g 'daemon off; error_log stderr info; pid none;'
