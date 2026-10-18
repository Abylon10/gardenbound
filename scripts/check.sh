#!/usr/bin/env bash
# Static checks for the Luau code, for environments without Roblox Studio.
# Downloads luau-compile, luau-lsp, Roblox type definitions, and Rojo into
# a cache folder on first run, then:
#   1. syntax-checks every .luau file
#   2. type-checks everything against the Roblox API (using a Rojo sourcemap)
# Usage: scripts/check.sh   (from the repo root)
set -euo pipefail

CACHE="${GARDENBOUND_TOOLS:-$HOME/.cache/gardenbound-tools}"
ROJO_VERSION="7.4.4"
mkdir -p "$CACHE"

fetch() { # url dest
	[ -e "$2" ] || curl -sSL -o "$2" "$1"
}

if [ ! -x "$CACHE/luau-compile" ]; then
	fetch https://github.com/luau-lang/luau/releases/latest/download/luau-ubuntu.zip "$CACHE/luau.zip"
	unzip -o -q "$CACHE/luau.zip" -d "$CACHE"
fi
if [ ! -x "$CACHE/luau-lsp" ]; then
	fetch https://github.com/JohnnyMorganz/luau-lsp/releases/latest/download/luau-lsp-linux-x86_64.zip "$CACHE/lsp.zip"
	unzip -o -q "$CACHE/lsp.zip" -d "$CACHE"
fi
fetch https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.None.d.luau "$CACHE/globalTypes.d.luau"
if [ ! -x "$CACHE/rojo" ]; then
	fetch "https://github.com/rojo-rbx/rojo/releases/download/v$ROJO_VERSION/rojo-$ROJO_VERSION-linux-x86_64.zip" "$CACHE/rojo.zip"
	unzip -o -q "$CACHE/rojo.zip" -d "$CACHE"
fi

echo "== Syntax"
status=0
while IFS= read -r file; do
	if ! "$CACHE/luau-compile" --null "$file" >/dev/null 2>&1; then
		"$CACHE/luau-compile" --null "$file" || true
		status=1
	fi
done < <(find src -name '*.luau')

echo "== Types"
"$CACHE/rojo" sourcemap default.project.json -o "$CACHE/sourcemap.json" >/dev/null
"$CACHE/luau-lsp" analyze \
	--definitions="$CACHE/globalTypes.d.luau" \
	--sourcemap="$CACHE/sourcemap.json" \
	src 2>&1 | grep -v '^\[INFO\]\|^\[WARN\] client does not allow' || true

exit $status
