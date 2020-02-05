#!/usr/bin/env bash


# Abort on any error
set -eu

# Simpler git usage, relative file paths
CWD=$(dirname "$0")
cd "$CWD"

# Load helpful functions
source libs/common.sh

# Check acces do docker daemon
assert_dependency "docker"
if ! docker version &> /dev/null; then
    echo "Docker daemon is not running or you have unsufficient permissions!"
    exit -1
fi

# Build the image
APP_NAME="nginx"
docker build --tag "$APP_NAME" .

if confirm_action "Test image?"; then
	# Set up temporary directory
	TMP_DIR=$(mktemp -d "/tmp/$APP_NAME-XXXXXXXXXX")
	add_cleanup "rm -rf $TMP_DIR"
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

	# Apply permissions, UID & GID matches process user
	APP_UID=100
	APP_GID=101
	chown -R "$APP_UID":"$APP_GID" "$TMP_DIR"

	# Start the test
	docker run \
	--rm \
	--interactive \
	--publish 80:80/tcp \
	--publish 443:443/tcp \
	--mount type=bind,source="$TMP_DIR",target="/etc/nginx/conf.d" \
	--mount type=bind,source="$TMP_DIR/index.html",target="/srv/index.html" \
	--name "$APP_NAME" \
	"$APP_NAME"
fi