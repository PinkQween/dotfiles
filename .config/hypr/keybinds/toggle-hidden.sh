#!/usr/bin/env bash

ADDRESS=$(hyprctl -j activewindow |jq -r '.address')
WORKSPACE=$(hyprctl -j activewindow | jq -r '.workspace.name')

if [[ "$WORKSPACE" == "special:hidden" ]]; then
	CURRENT_WORKSPACE=$(hyprctl -j activeworkspace | jq -r '.id')
	hyprctl dispatch movetoworkspace "$CURRENT_WORKSPACE,address:$ADDRESS"
else
	hyprctl dispatch movetoworkspace "special:hidden,address:$ADDRESS"
fi
