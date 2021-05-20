#!/bin/bash
( # run entire script in a subshell to eliminate side effects when running via .
cd "$(dirname "$(realpath "$BASH_SOURCE")")" # cd to script directory

if [[ $EUID -ne 0 ]]; then
   echo "$BASH_SOURCE script must be run as root"
   exit 1
fi
exec /bin/bash _aa_driver_latest-src/ensure_module.sh
)
