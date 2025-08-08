#!/usr/bin/env bash
# toggle-vivaldi-theme.sh
# Toggle Vivaldi's active theme between scheduled light/dark IDs in Preferences.

set -euo pipefail
PREF="$HOME/.config/vivaldi/Default/Preferences"
TMP="$(mktemp)"

if ! command -v jq >/dev/null; then
  echo "Error: jq is required" >&2
  exit 1
fi

[[ -f "$PREF" ]] || { echo "Preferences not found: $PREF" >&2; exit 1; }

vivaldi_running() {
  pgrep -xa vivaldi-bin >/dev/null 2>&1 || pgrep -xa vivaldi >/dev/null 2>&1
}

list_themes() {
  active=$(jq -r '.vivaldi.theme.active' "$PREF")
  jq -r --arg active "$active" '
    .vivaldi.themes.user[] |
    "\(.id)  \(.name)\(if .id == $active then "  [ACTIVE]" else "" end)"
  ' "$PREF"
}

get_current_theme() {
 jq -r '
    .vivaldi.themes.current as $current |
    .vivaldi.themes.user[] |
    select(.id == $current) |
    "\(.name)  [CURRENT]"
  ' "$PREF"
}

toggle_theme() {
	if vivaldi_running; then
		echo "Vivaldi is running and toggle will be overwritten"
		exit 1
	fi
  current=$(jq -r '.vivaldi.themes.current' "$PREF")
  new_id=$(jq -r --arg current "$current" '
    .vivaldi.themes.user[] | select(.id != $current) | .id
  ' "$PREF")

  if [[ -z "$new_id" ]]; then
    echo "No alternate theme found to toggle to." >&2
    exit 1
  fi

  jq --arg new "$new_id" '.vivaldi.themes.current = $new' "$PREF" > "$TMP"
  mv "$TMP" "$PREF"

  new_name=$(jq -r --arg id "$new_id" '
    .vivaldi.themes.user[] | select(.id == $id) | .name
  ' "$PREF")
  echo "Switched to: $new_name ($new_id)"
}

toggle_theme
