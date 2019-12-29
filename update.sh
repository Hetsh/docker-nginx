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

# Alpine
CURRENT_ALPINE_VERSION=$(cat Dockerfile | grep "FROM alpine:")
CURRENT_ALPINE_VERSION="${CURRENT_ALPINE_VERSION#*:}"
ALPINE_VERSION=$(curl -L -s 'https://registry.hub.docker.com/v2/repositories/library/alpine/tags' | jq '."results"[]["name"]' | grep -m 1 -P -o "(\d+\.)+\d+")
if [ "$CURRENT_ALPINE_VERSION" != "$ALPINE_VERSION" ]
then
	echo "Alpine $ALPINE_VERSION available!"

	RELEASE="${CURRENT_VERSION#*-}"
	NEXT_VERSION="${CURRENT_VERSION%-*}-$((RELEASE+1))"
fi

# NGINX
NGINX_PKG="nginx"
CURRENT_NGINX_VERSION=$(cat Dockerfile | grep "$NGINX_PKG=")
CURRENT_NGINX_VERSION="${CURRENT_NGINX_VERSION#*=}"
NGINX_VERSION=$(curl -L -s "https://pkgs.alpinelinux.org/package/v${ALPINE_VERSION%.*}/main/x86_64/$NGINX_PKG" | grep -m 1 -P -o "(\d+\.)+\d+-r\d+" )
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
	read -p "Save changes? [y/n]" -n 1 -r && echo
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		if [ "$CURRENT_ALPINE_VERSION" != "$ALPINE_VERSION" ]
		then
			sed -i "s|FROM alpine:.*|FROM alpine:$ALPINE_VERSION|" Dockerfile
		fi

		if [ "$CURRENT_NGINX_VERSION" != "$NGINX_VERSION" ]
		then
			sed -i "s|$NGINX_PKG=.*|$NGINX_PKG=$NGINX_VERSION|" Dockerfile
		fi

		read -p "Commit changes? [y/n]" -n 1 -r && echo
		if [[ $REPLY =~ ^[Yy]$ ]]
		then
			git add Dockerfile
			git commit -m "Version bump to $NEXT_VERSION"
			git push
			git tag "$NEXT_VERSION"
			git push origin "$NEXT_VERSION"
		fi
	fi
fi
