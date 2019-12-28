#!/usr/bin/env bash

set -e
trap "exit" SIGINT

if ! docker version &> /dev/null
then
    echo "Docker daemon is not running or you have unsufficient permissions!"
    exit 1
fi

APP_NAME="nginx"
docker build --tag "$APP_NAME" .

read -p "Test image? [y/n]" -n 1 -r && echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	docker run \
	--rm \
	--interactive \
	--publish 80:80 \
	--publish 443:443 \
	"$APP_NAME"
fi