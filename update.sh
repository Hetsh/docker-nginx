#!/usr/bin/env bash

set -e
trap "exit" SIGINT

if [ "$USER" == "root" ]
then
	echo "Must not be executed as user \"root\"!"
	exit -1
fi

if ! [ -x "$(command -v jq)" ]
then
	echo "JSON Parser \"jq\" is required but not installed!"
	exit -2
fi

if ! [ -x "$(command -v curl)" ]
then
	echo "\"curl\" is required but not installed!"
	exit -3
fi

WORK_DIR="${0%/*}"
cd "$WORK_DIR"

CURRENT_VERSION=$(git describe --tags --abbrev=0)
NEXT_VERSION="$CURRENT_VERSION"

# Base Image
IMAGE_NAME="alpine"
CURRENT_IMAGE_VERSION=$(cat Dockerfile | grep "FROM $IMAGE_NAME:")
CURRENT_IMAGE_VERSION="${CURRENT_IMAGE_VERSION#*:}"
IMAGE_VERSION=$(curl -L -s "https://registry.hub.docker.com/v2/repositories/library/$IMAGE_NAME/tags" | jq '."results"[]["name"]' | grep -m 1 -P -o "(\d+\.)+\d+")
if [ "$CURRENT_IMAGE_VERSION" != "$IMAGE_VERSION" ]
then
	echo "Alpine $IMAGE_VERSION available!"

	RELEASE="${CURRENT_VERSION#*-}"
	NEXT_VERSION="${CURRENT_VERSION%-*}-$((RELEASE+1))"
fi

# NGINX
NGINX_PKG="nginx"
CURRENT_NGINX_VERSION=$(cat Dockerfile | grep "$NGINX_PKG=")
CURRENT_NGINX_VERSION="${CURRENT_NGINX_VERSION#*=}"
NGINX_VERSION=$(curl -L -s "https://pkgs.alpinelinux.org/package/v${IMAGE_VERSION%.*}/main/x86_64/$NGINX_PKG" | grep -m 1 -P -o "(\d+\.)+\d+-r\d+")
if [ "$CURRENT_NGINX_VERSION" != "$NGINX_VERSION" ]
then
	echo "NGINX $NGINX_VERSION available!"

	if [ "${CURRENT_NGINX_VERSION%-*}" != "${NGINX_VERSION%-*}" ]
	then
		NEXT_VERSION="${NGINX_VERSION%-*}-1"
	else
		RELEASE="${CURRENT_VERSION#*-}"
		NEXT_VERSION="${CURRENT_VERSION%-*}-$((RELEASE+1))"
	fi
fi

if [ "$CURRENT_VERSION" == "$NEXT_VERSION" ]
then
	echo "No updates available."
else
	if [ "$1" == "--noconfirm" ]
	then
		SAVE="y"
	else
		read -p "Save changes? [y/n]" -n 1 -r SAVE && echo
	fi
	
	if [[ $SAVE =~ ^[Yy]$ ]]
	then
		if [ "$CURRENT_IMAGE_VERSION" != "$IMAGE_VERSION" ]
		then
			sed -i "s|FROM $IMAGE_NAME:.*|FROM $IMAGE_NAME:$IMAGE_VERSION|" Dockerfile
		fi

		if [ "$CURRENT_NGINX_VERSION" != "$NGINX_VERSION" ]
		then
			sed -i "s|$NGINX_PKG=.*|$NGINX_PKG=$NGINX_VERSION|" Dockerfile
		fi

		if [ "$1" == "--noconfirm" ]
		then
			COMMIT="y"
		else
			read -p "Commit changes? [y/n]" -n 1 -r COMMIT && echo
		fi

		if [[ $COMMIT =~ ^[Yy]$ ]]
		then
			git add Dockerfile
			git commit -m "Version bump to $NEXT_VERSION"
			git push
			git tag "$NEXT_VERSION"
			git push origin "$NEXT_VERSION"
		fi
	fi
fi
