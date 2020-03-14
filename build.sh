#!/usr/bin/env bash


# Abort on any error
set -e -u

# Simpler git usage, relative file paths
CWD=$(dirname "$0")
cd "$CWD"

# Load helpful functions
source libs/common.sh

# Check access to docker daemon
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
	TMP_HOSTS_DIR=$(mktemp -d "/tmp/$APP_NAME-HOSTS-XXXXXXXXXX")
	add_cleanup "rm -rf $TMP_HOSTS_DIR"
	echo "server {
	listen 80 default_server;
	listen [::]:80 default_server;

	root /srv;
	index index.html;

	server_name _;

	location / {
		try_files \$uri \$uri/ =404;
	}
}" > "$TMP_HOSTS_DIR/test.conf"

	TMP_SRV_DIR=$(mktemp -d "/tmp/$APP_NAME-SRV-XXXXXXXXXX")
	add_cleanup "rm -rf $TMP_SRV_DIR"
	echo "<html>
	<head>
		<title>Test</title>
	</head>
	<body>
		<h1>Success!</h1>
	</body>
</html>" > "$TMP_SRV_DIR/index.html"

	# Apply permissions, UID & GID matches process user
	extract_var APP_UID "./Dockerfile" "\K\d+"
	extract_var APP_GID "./Dockerfile" "\K\d+"
	chown -R "$APP_UID":"$APP_GID" "$TMP_HOSTS_DIR" "$TMP_SRV_DIR"

	# Start the test
	extract_var HOSTS_DIR "./Dockerfile" "\"\K[^\"]+"
	extract_var SRV_DIR "./Dockerfile" "\"\K[^\"]+"
	docker run \
	--rm \
	--interactive \
	--publish 80:80/tcp \
	--publish 443:443/tcp \
	--mount type=bind,source="$TMP_HOSTS_DIR",target="$HOSTS_DIR" \
	--mount type=bind,source="$TMP_SRV_DIR",target="$SRV_DIR" \
	--mount type=bind,source=/etc/localtime,target=/etc/localtime,readonly \
	--name "$APP_NAME" \
	"$APP_NAME"
fi