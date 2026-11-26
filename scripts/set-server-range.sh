#!/bin/sh
# Sets the version range of @tellagen/mcp-server in every place the plugin
# starts the server: .mcp.json and each command of hooks/hooks.json.
#
#   scripts/set-server-range.sh '^0.9.0'
#
# With no argument it prints the ranges in use and fails when they differ.
set -eu
cd "$(dirname "$0")/.."
files=".mcp.json hooks/hooks.json"

if [ "$#" -eq 1 ]; then
  case "$1" in
    *[!0-9A-Za-z.^~\<\>=\ -]* | "") echo "Not a version range: $1" >&2; exit 2 ;;
  esac
  for file in $files; do
    sed "s|@tellagen/mcp-server@[^\" ]*|@tellagen/mcp-server@$1|g" "$file" > "$file.tmp"
    mv "$file.tmp" "$file"
  done
fi

ranges=$(grep -oh '@tellagen/mcp-server@[^" ]*' $files | sort -u)
echo "$ranges"
if [ "$(echo "$ranges" | wc -l)" -ne 1 ]; then
  echo "The plugin starts more than one version range of the server. Run: scripts/set-server-range.sh '<range>'" >&2
  exit 1
fi
