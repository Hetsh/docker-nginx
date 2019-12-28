FROM alpine:3.11.2
RUN apk add --no-cache nginx

EXPOSE 80/tcp 443/tcp
#      HTTP   HTTPS

ENTRYPOINT exec nginx -g 'daemon off; error_log stderr info; pid /run/nginx.pid;'
