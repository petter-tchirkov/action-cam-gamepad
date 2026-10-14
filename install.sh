#!/usr/bin/env bash
# Symlinks the ActionCamGamepad addon folder into the WoW AddOns directory.
# Override the target with WOW_ADDONS_DIR=/path/to/Interface/AddOns ./install.sh
set -euo pipefail

ADDON_NAME="ActionCamGamepad"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$REPO_DIR/$ADDON_NAME"
ADDONS_DIR="${WOW_ADDONS_DIR:-$HOME/Games/Battle.net/World of Warcraft/_classic_beta_/Interface/AddOns}"
TARGET="$ADDONS_DIR/$ADDON_NAME"

if [[ ! -d "$ADDONS_DIR" ]]; then
    echo "AddOns directory not found: $ADDONS_DIR" >&2
    echo "Set WOW_ADDONS_DIR to your Interface/AddOns path." >&2
    exit 1
fi

if [[ -L "$TARGET" ]]; then
    if [[ "$(readlink -f "$TARGET")" == "$SOURCE" ]]; then
        echo "Already linked: $TARGET -> $SOURCE"
        exit 0
    fi
    rm "$TARGET"
elif [[ -e "$TARGET" ]]; then
    echo "$TARGET exists and is not a symlink; move or delete it first." >&2
    exit 1
fi

ln -s "$SOURCE" "$TARGET"
echo "Linked: $TARGET -> $SOURCE"
