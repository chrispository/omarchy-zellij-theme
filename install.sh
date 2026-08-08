#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMED_DIR="$HOME/.config/omarchy/themed"
HOOKS_DIR="$HOME/.config/omarchy/hooks"
THEME_SET_DIR="$HOOKS_DIR/theme-set.d"
THEME_TEMPLATE="$THEMED_DIR/zellij.kdl.tpl"
THEME_SET_HOOK="$THEME_SET_DIR/omarchy-zellij-theme"
LEGACY_HOOK="$HOOKS_DIR/theme-set"
ZELLIJ_CONFIG="$HOME/.config/zellij/config.kdl"
OLD_THEME_FILE="$HOME/.config/zellij/themes/omarchy.kdl"

timestamped_backup() {
    local path="$1"
    local backup="${path}.bak.$(date +%s)"
    cp -- "$path" "$backup"
    printf 'Backup: %s\n' "$backup"
}

install_symlink() {
    local target="$1"
    local link="$2"

    mkdir -p "$(dirname "$link")"

    if [[ -L "$link" ]] && [[ "$(readlink -f "$link")" == "$(readlink -f "$target")" ]]; then
        return
    fi

    if [[ -e "$link" || -L "$link" ]]; then
        mv -- "$link" "${link}.bak.$(date +%s)"
    fi

    ln -s -- "$target" "$link"
}

remove_legacy_hook_integration() {
    [[ -f "$LEGACY_HOOK" && ! -L "$LEGACY_HOOK" ]] || return 0

    local start_marker="# --- omarchy-zellij-theme integration (start) ---"
    local end_marker="# --- omarchy-zellij-theme integration (end) ---"

    grep -qF "$start_marker" "$LEGACY_HOOK" || return 0

    local temp_hook
    temp_hook="$(mktemp "${LEGACY_HOOK}.XXXXXX")"
    sed "/$start_marker/,/$end_marker/d" "$LEGACY_HOOK" > "$temp_hook"
    chmod --reference="$LEGACY_HOOK" "$temp_hook"
    mv -- "$temp_hook" "$LEGACY_HOOK"
}

printf '%s\n' '=== omarchy-zellij-theme installer ==='

mkdir -p "$THEMED_DIR" "$THEME_SET_DIR"

install_symlink "$SCRIPT_DIR/zellij.kdl.tpl" "$THEME_TEMPLATE"
printf '%s\n' "[1/5] Template installed at $THEME_TEMPLATE"

install_symlink "$SCRIPT_DIR/theme-set" "$THEME_SET_HOOK"
chmod +x "$THEME_SET_HOOK"

# Migrate the old version's symlink or appended hook block when possible.
if [[ -L "$LEGACY_HOOK" ]] && [[ "$(readlink -f "$LEGACY_HOOK")" == "$(readlink -f "$SCRIPT_DIR/theme-set")" ]]; then
    rm -- "$LEGACY_HOOK"
fi
remove_legacy_hook_integration
printf '%s\n' "[2/5] Theme hook installed at $THEME_SET_HOOK"

if [[ -f "$ZELLIJ_CONFIG" ]]; then
    if grep -q '^theme "omarchy"$' "$ZELLIJ_CONFIG"; then
        printf '%s\n' '[3/5] Zellij already uses the omarchy theme.'
    else
        config_tmp="$(mktemp "$(dirname "$ZELLIJ_CONFIG")/.config.kdl.XXXXXX")"
        if grep -qE '^theme "[^"]+"$' "$ZELLIJ_CONFIG"; then
            sed -E '0,/^theme "[^"]+"$/s//theme "omarchy"/' "$ZELLIJ_CONFIG" > "$config_tmp"
        elif grep -qE '^//[[:space:]]*theme ' "$ZELLIJ_CONFIG"; then
            sed -E '0,/^\/\/[[:space:]]*theme /s//theme "omarchy"/' "$ZELLIJ_CONFIG" > "$config_tmp"
        else
            cp -- "$ZELLIJ_CONFIG" "$config_tmp"
            printf '\n%s\n' 'theme "omarchy"' >> "$config_tmp"
        fi
        if cmp -s "$config_tmp" "$ZELLIJ_CONFIG"; then
            rm -- "$config_tmp"
        else
            timestamped_backup "$ZELLIJ_CONFIG"
            chmod --reference="$ZELLIJ_CONFIG" "$config_tmp"
            mv -- "$config_tmp" "$ZELLIJ_CONFIG"
        fi
        printf '%s\n' '[3/5] Configured Zellij to use the omarchy theme.'
    fi
else
    printf '%s\n' "[3/5] Zellij config not found at $ZELLIJ_CONFIG; skipping config update."
fi

if [[ -f "$OLD_THEME_FILE" ]]; then
    rm -- "$OLD_THEME_FILE"
    printf '%s\n' "[4/5] Removed old theme file: $OLD_THEME_FILE"
else
    printf '%s\n' '[4/5] No old theme file to clean up.'
fi

CURRENT_THEME="$(cat "$HOME/.config/omarchy/current/theme.name" 2>/dev/null || true)"
if [[ -n "$CURRENT_THEME" && -f "$ZELLIJ_CONFIG" ]]; then
    printf '%s\n' "[5/5] Applying current theme '$CURRENT_THEME' to Zellij..."
    OMARCHY_ZELLIJ_THEME_NOTIFY=0 "$THEME_SET_HOOK" "$CURRENT_THEME"
    printf '%s\n' '[5/5] Current theme applied.'
else
    printf '%s\n' '[5/5] No current Omarchy theme or Zellij config found; sync will begin on the next theme change.'
fi

printf '\n%s\n' '=== Installation complete ==='
printf 'To revert, run: %s/uninstall.sh\n' "$SCRIPT_DIR"
