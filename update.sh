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
ALPINE_VERSION=$(curl -L -s 'https://registry.hub.docker.com/v2/repositories/library/alpine/tags' | jq '."results"[]["name"]' | grep -P -o "(\d+\.)+\d+" | head -n 1)
if [ "$CURRENT_ALPINE_VERSION" != "$ALPINE_VERSION" ]
then
    echo "Alpine $ALPINE_VERSION available!"

    RELEASE="${CURRENT_VERSION#*-}"
    NEXT_VERSION="${CURRENT_VERSION%-*}-$((RELEASE+1))"
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
