#!/bin/sh

script_path="$(dirname "$(readlink -e -- "$0")")"
script_name="$(basename "$0")"
logfile_name=/dev/null
export SUDO_ASKPASS="$(which ssh-askpass)"
unset quiet
distname="$(awk -F'=' '/^ID=/ {print tolower($2)}' /etc/*-release)"
