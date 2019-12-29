#!/usr/bin/env bash

set -e
trap "exit" SIGINT

if ! docker version &> /dev/null
then
    echo "Docker daemon is not running or you have unsufficient permissions!"
    exit -1
fi

WORK_DIR="${0%/*}"
cd "$WORK_DIR"

APP_NAME="nginx"
docker build --tag "$APP_NAME" .

read -p "Test image? [y/n]" -n 1 -r && echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	TMP_DIR=$(mktemp -d "/tmp/$APP_NAME-XXXXXXXXXX")
	trap "rm -rf $TMP_DIR" EXIT
	echo "server {
	listen 80 default_server;
	listen [::]:80 default_server;

	root /srv;
	index index.html;

	server_name _;

	location / {
		try_files \$uri \$uri/ =404;
	}
}" > "$TMP_DIR/test.conf"
	echo "<html>
	<head>
		<title>Test</title>
	</head>
	<body>
		<h1>Success!</h1>
	</body>
</html>" > "$TMP_DIR/index.html"

	APP_UID=100
	APP_GID=101
	chown -R "$APP_UID":"$APP_GID" "$TMP_DIR"

	docker run \
	--rm \
	--interactive \
	--publish 80:80/tcp \
	--publish 443:443/tcp \
	--mount type=bind,source="$TMP_DIR",target="/etc/nginx/conf.d" \
	--mount type=bind,source="$TMP_DIR/index.html",target="/srv/index.html" \
	"$APP_NAME"
fi