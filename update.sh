#!/usr/bin/env bash


# Abort on any error
set -eu

# Simpler git usage, relative file paths
CWD=$(dirname "$0")
cd "$CWD"

# Load helpful functions
source libs/common.sh
source libs/docker.sh

# Check dependencies
assert_dependency "jq"
assert_dependency "curl"

# Current version of docker image
register_current_version

# Alpine Linux
update_image "alpine" "Alpine" "x86_64" "(\d+\.)+\d+"

# NGINX
update_alpine_pkg "nginx" "NGINX" "true" "main" "(\d+\.)+\d+-r\d+"

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
