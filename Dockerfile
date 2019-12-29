FROM alpine:3.11.2
RUN apk add --no-cache nginx=1.16.1-r4

VOLUME ["/etc/nginx/conf.d"]
EXPOSE 80/tcp 443/tcp
#      HTTP   HTTPS

ENTRYPOINT exec nginx -g 'daemon off; error_log stderr info; pid /run/nginx.pid;'
