#!/usr/bin/env bash


# Abort on any error
set -e -u

# Simpler git usage, relative file paths
CWD=$(dirname "$0")
cd "$CWD"

# Load helpful functions
source libs/common.sh
source libs/docker.sh

# Check dependencies
assert_dependency "jq"
assert_dependency "curl"

# Alpine Linux
update_image "library/alpine" "Alpine" "(\d+\.)+\d+"

# NGINX
update_pkg "nginx" "NGINX" "true" "https://pkgs.alpinelinux.org/package/v${_NEW_IMG_VERSION%.*}/main/x86_64" "(\d+\.)+\d+-r\d+"

if ! updates_available; then
	echo "No updates available."
	exit 0
fi

if [ "${1+}" = "--noconfirm" ] || confirm_action "Save changes?"; then
	save_changes

	if [ "${1+}" = "--noconfirm" ] || confirm_action "Commit changes?"; then
		commit_changes
	fi
fi
