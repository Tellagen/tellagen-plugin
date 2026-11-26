#!/bin/sh
# Keeps the copy of this plugin in Tellagen/tellagen-marketplace equal to this
# repository. The marketplace is what people install, so a change here reaches
# nobody until the copy is refreshed.
#
#   scripts/sync-marketplace.sh <marketplace checkout>          copies the plugin
#   scripts/sync-marketplace.sh --check <marketplace checkout>  fails when the copy differs
#
# The copy holds the files a client loads: .claude-plugin, .mcp.json, commands,
# hooks and skills. It also sets the plugin version in the marketplace list.
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
check=0
if [ "${1:-}" = "--check" ]; then check=1; shift; fi
if [ "$#" -ne 1 ] || [ ! -f "$1/.claude-plugin/marketplace.json" ]; then
  echo "Give the path of a tellagen-marketplace checkout." >&2
  exit 2
fi
market=$(cd "$1" && pwd)
copy="$market/plugins/tellagen"
parts=".claude-plugin .mcp.json commands hooks skills"
version=$(sed -n 's/^  "version": "\([^"]*\)".*/\1/p' "$here/.claude-plugin/plugin.json" | head -n 1)
listed=$(sed -n 's/^      "version": "\([^"]*\)".*/\1/p' "$market/.claude-plugin/marketplace.json" | head -n 1)
[ -n "$version" ] || { echo "No version in .claude-plugin/plugin.json." >&2; exit 2; }

if [ "$check" -eq 1 ]; then
  status=0
  for part in $parts; do
    diff -r -x .DS_Store "$here/$part" "$copy/$part" || status=1
  done
  if [ "$listed" != "$version" ]; then
    echo "marketplace.json lists version $listed and the plugin is $version."
    status=1
  fi
  if [ "$status" -ne 0 ]; then
    echo "The marketplace copy differs from the plugin. Run scripts/sync-marketplace.sh <marketplace checkout> in tellagen-plugin and open a PR in tellagen-marketplace." >&2
  fi
  exit "$status"
fi

mkdir -p "$copy"
for part in $parts; do
  rm -rf "${copy:?}/$part"
  cp -R "$here/$part" "$copy/$part"
done
find "$copy" -name .DS_Store -exec rm -f {} +
if [ "$listed" != "$version" ]; then
  sed "s|^      \"version\": \"$listed\"|      \"version\": \"$version\"|" "$market/.claude-plugin/marketplace.json" > "$market/.claude-plugin/marketplace.json.tmp"
  mv "$market/.claude-plugin/marketplace.json.tmp" "$market/.claude-plugin/marketplace.json"
fi
echo "Copied plugin $version to $copy. Review the diff there and open a PR."
