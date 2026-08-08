#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_TEMPLATE="$HOME/.config/omarchy/themed/zellij.kdl.tpl"
THEME_SET_HOOK="$HOME/.config/omarchy/hooks/theme-set.d/omarchy-zellij-theme"
LEGACY_HOOK="$HOME/.config/omarchy/hooks/theme-set"
ZELLIJ_CONFIG="$HOME/.config/zellij/config.kdl"
OLD_THEME_FILE="$HOME/.config/zellij/themes/omarchy.kdl"
START_MARKER="// --- omarchy-zellij-theme (start) ---"
END_MARKER="// --- omarchy-zellij-theme (end) ---"

timestamped_backup() {
    local path="$1"
    local backup="${path}.bak.$(date +%s)"
    cp -- "$path" "$backup"
    printf 'Backup: %s\n' "$backup"
}

remove_marked_block() {
    local path="$1"
    local start_marker="$2"
    local end_marker="$3"
    local temp

    grep -qF "$start_marker" "$path" || return 0
    temp="$(mktemp "${path}.XXXXXX")"
    sed "\%$start_marker%,\%$end_marker%d" "$path" > "$temp"
    chmod --reference="$path" "$temp"
    mv -- "$temp" "$path"
}

remove_our_symlink() {
    local link="$1"
    local target="$2"

    if [[ -L "$link" ]] && [[ "$(readlink -f "$link")" == "$(readlink -f "$target")" ]]; then
        rm -- "$link"
        return 0
    fi

    return 1
}

printf '%s\n' '=== omarchy-zellij-theme uninstaller ==='

if remove_our_symlink "$THEME_TEMPLATE" "$SCRIPT_DIR/zellij.kdl.tpl"; then
    printf '%s\n' '[1/5] Removed template symlink.'
else
    printf '%s\n' '[1/5] Template symlink not found or belongs to another installation; left unchanged.'
fi

if remove_our_symlink "$THEME_SET_HOOK" "$SCRIPT_DIR/theme-set"; then
    printf '%s\n' '[2/5] Removed theme-set hook.'
else
    printf '%s\n' '[2/5] Theme-set hook not found or belongs to another installation; left unchanged.'
fi

if [[ -L "$LEGACY_HOOK" ]] && [[ "$(readlink -f "$LEGACY_HOOK")" == "$(readlink -f "$SCRIPT_DIR/theme-set")" ]]; then
    rm -- "$LEGACY_HOOK"
    printf '%s\n' '[2/5] Removed legacy theme-set hook.'
elif [[ -f "$LEGACY_HOOK" ]]; then
    remove_marked_block "$LEGACY_HOOK" \
        '# --- omarchy-zellij-theme integration (start) ---' \
        '# --- omarchy-zellij-theme integration (end) ---'
fi

if [[ -f "$ZELLIJ_CONFIG" ]]; then
    config_tmp="$(mktemp "$(dirname "$ZELLIJ_CONFIG")/.config.kdl.XXXXXX")"
    sed "\%$START_MARKER%,\%$END_MARKER%d" "$ZELLIJ_CONFIG" > "$config_tmp"
    sed -i 's/^theme "omarchy"$/\/\/ theme "omarchy"/' "$config_tmp"

    if cmp -s "$config_tmp" "$ZELLIJ_CONFIG"; then
        rm -- "$config_tmp"
        printf '%s\n' '[3/5] No active omarchy theme configuration found.'
    else
        timestamped_backup "$ZELLIJ_CONFIG"
        chmod --reference="$ZELLIJ_CONFIG" "$config_tmp"
        mv -- "$config_tmp" "$ZELLIJ_CONFIG"
        printf '%s\n' '[3/5] Removed the active omarchy theme configuration.'
    fi
else
    printf '%s\n' '[3/5] Zellij config not found; skipped.'
fi

if [[ -f "$OLD_THEME_FILE" ]]; then
    rm -- "$OLD_THEME_FILE"
    printf '%s\n' '[4/5] Removed old theme file.'
else
    printf '%s\n' '[4/5] No old theme file found.'
fi

rmdir "$HOME/.config/omarchy/hooks/theme-set.d" 2>/dev/null || true
printf '%s\n' '[5/5] Cleanup complete.'

printf '\n%s\n' '=== Uninstall complete ==='
