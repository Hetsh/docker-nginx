#!/usr/bin/env bash


# Abort on any error
set -e -u

# Simpler git usage, relative file paths
CWD=$(dirname "$0")
cd "$CWD"

# Load helpful functions
source libs/common.sh
source libs/docker.sh

# Check access to docker daemon
assert_dependency "docker"
if ! docker version &> /dev/null; then
	echo "Docker daemon is not running or you have unsufficient permissions!"
	exit -1
fi

# Build the image
APP_NAME="nginx"
IMG_NAME="hetsh/$APP_NAME"
docker build --tag "$IMG_NAME:latest" --tag "$IMG_NAME:$_NEXT_VERSION" .

case "${1-}" in
	# Test with default configuration
	"--test")
		# Set up temporary directory
		TMP_DIR=$(mktemp -d "/tmp/$APP_NAME-XXXXXXXXXX")
		add_cleanup "rm -rf $TMP_DIR"
		echo "server {
	listen 80 default_server;
	listen [::]:80 default_server;
	server_name _;

	root /srv;
	index index.html;

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
		mkdir "$TMP_DIR/logs"


		# Apply permissions, UID & GID matches process user
		extract_var APP_UID "./Dockerfile" "\K\d+"
		extract_var APP_GID "./Dockerfile" "\K\d+"
		chown -R "$APP_UID":"$APP_GID" "$TMP_DIR"

		# Start the test
		extract_var HOST_DIR "./Dockerfile" "\"\K[^\"]+"
		extract_var SRV_DIR "./Dockerfile" "\"\K[^\"]+"
		extract_var LOG_DIR "./Dockerfile" "\"\K[^\"]+"
		docker run \
		--rm \
		--tty \
		--interactive \
		--publish 80:80/tcp \
		--publish 443:443/tcp \
		--mount type=bind,source="$TMP_DIR/test.conf",target="$HOST_DIR/test.conf" \
		--mount type=bind,source="$TMP_DIR",target="$SRV_DIR" \
		--mount type=bind,source="$TMP_DIR/logs",target="$LOG_DIR" \
		--mount type=bind,source=/etc/localtime,target=/etc/localtime,readonly \
		--name "$APP_NAME" \
		"$IMG_NAME"
	;;
	# Push image to docker hub
	"--upload")
		if ! tag_exists "$IMG_NAME"; then
			docker push "$IMG_NAME:latest"
			docker push "$IMG_NAME:$_NEXT_VERSION"
		fi
	;;
esac