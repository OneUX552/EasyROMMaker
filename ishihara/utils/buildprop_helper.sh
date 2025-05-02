#!/bin/bash
# buildprop_helper.sh - Advanced Build.prop Manager

# Check if ROM_FOLDER is set
[ -z "$ROM_FOLDER" ] && { echo "ERROR: ROM_FOLDER not set!"; exit 1; }

BUILD_PROP="$ROM_FOLDER/system/system/build.prop"
BACKUP_PROP="$BUILD_PROP.bak"
ISHIHARA_HEADER="# from variable ISHIHARA_ROM_BUILD_CONFIG_PROPERTIES"
ISHIHARA_FOOTER="####################################"

# Main processing function
process_build_props() {
    local SUBSCRIPT_SOURCE_DIR="$1"
    local EDITS_FILE="$SUBSCRIPT_SOURCE_DIR/system/etc/build_edits.prop"

    [ -f "$EDITS_FILE" ] || return 0
    [ -f "$BUILD_PROP" ] || { echo "ERROR: build.prop missing"; return 1; }

    # Create backup
    cp -f "$BUILD_PROP" "$BACKUP_PROP"

    # Process each property
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [ -z "$line" ] && continue

        if [[ "$line" =~ ^([a-zA-Z0-9._-]+)=(.*)$ ]]; then
            local prop="${BASH_REMATCH[1]}"
            local new_value="${BASH_REMATCH[2]}"

            # Update existing property
            if grep -q "^$prop=" "$BUILD_PROP"; then
                local current_value=$(grep "^$prop=" "$BUILD_PROP" | cut -d= -f2-)
                if [ "$current_value" != "$new_value" ]; then
                    sed -i "s/^$prop=.*/$prop=$new_value/" "$BUILD_PROP"
                    echo "Updated: $prop=$new_value"
                fi
            # Add new property to ISHIHARA section
            else
                # Create ISHIHARA section if missing
                if ! grep -q "$ISHIHARA_HEADER" "$BUILD_PROP"; then
                    sed -i "/^# end of file/i $ISHIHARA_HEADER\n$ISHIHARA_FOOTER" "$BUILD_PROP"
                fi
                
                # Add property under ISHIHARA section
                if ! grep -q "^$prop=" "$BUILD_PROP"; then
                    sed -i "/$ISHIHARA_HEADER/a $prop=$new_value" "$BUILD_PROP"
                    echo "Added: $prop=$new_value"
                fi
            fi
        fi
    done < <(grep -v '^[[:space:]]*$' "$EDITS_FILE")

    # Cleanup empty lines in ISHIHARA section
    sed -i "/$ISHIHARA_HEADER/{N;/\n$/d}" "$BUILD_PROP"
    sed -i "/$ISHIHARA_HEADER/,/$ISHIHARA_FOOTER/{/^$/d}" "$BUILD_PROP"
}