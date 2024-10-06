#!/bin/sh
echo -ne '\033c\033]0;NewLinuxServer\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/NewLinuxServer.x86_64" "$@"
