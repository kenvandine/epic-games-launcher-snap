#!/bin/bash
# Verify the manually-connected snap plugs are present before starting the launcher.
PLUGS="hardware-observe joystick process-control system-observe"

missing=()
for plug in $PLUGS; do
    snapctl is-connected "$plug" >/dev/null 2>&1 || missing+=("$plug")
done

if [ "${#missing[@]}" -gt 0 ]; then
    cmds=""
    for plug in "${missing[@]}"; do
        cmds+="sudo snap connect ${SNAP_INSTANCE_NAME}:${plug}"$'\n'
    done
    msg="Epic Games Launcher needs additional permissions to work correctly.

Run the following in a terminal, then start the launcher again:

${cmds}"
    echo "$msg" >&2
    if command -v zenity >/dev/null 2>&1; then
        zenity --error --no-markup --title="Epic Games Launcher" \
            --width=480 --text="$msg" >/dev/null 2>&1
    fi
    exit 1
fi

exec "$SNAP/epic-games-launcher/usr/bin/EpicGamesLauncher" "$@"
