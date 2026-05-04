#!/usr/bin/env bash

set -u

list_dir() {
    local dir="$1"
    local parent

    if [ "$dir" = "/" ]; then
        parent="/"
    else
        parent="$(dirname "$dir")"
    fi

    printf '\0prompt\x1fFiles\n'
    printf '\0message\x1f%s\n' "$dir"
    printf '\0no-custom\x1ftrue\n'
    printf '\0data\x1f%s\n' "$dir"
    printf '..\0info\x1f%s\n' "$parent"

    local entry base display
    for entry in "$dir"/* "$dir"/.*; do
        [ -e "$entry" ] || continue
        base="$(basename "$entry")"
        [ "$base" = "." ] && continue
        [ "$base" = ".." ] && continue

        if [ -d "$entry" ]; then
            display="${base}/"
        else
            display="$base"
        fi

        printf '%s\0info\x1f%s\n' "$display" "$entry"
    done
}

open_path() {
    local path="$1"
    if command -v dolphin >/dev/null 2>&1; then
        coproc ( dolphin -- "$path" >/dev/null 2>&1 )
    else
        coproc ( xdg-open "$path" >/dev/null 2>&1 )
    fi
}

retv="${ROFI_RETV:-0}"
current="${ROFI_DATA:-$HOME}"
selected_path="${ROFI_INFO:-}"

if [ "$retv" = "0" ]; then
    list_dir "$current"
    exit 0
fi

if [ "$retv" = "1" ] || [ "$retv" = "2" ]; then
    if [ -z "$selected_path" ]; then
        list_dir "$current"
        exit 0
    fi

    if [ -d "$selected_path" ]; then
        list_dir "$selected_path"
        exit 0
    fi

    if [ -e "$selected_path" ]; then
        open_path "$selected_path"
    fi
fi
