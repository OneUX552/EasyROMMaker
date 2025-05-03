#!/bin/bash

# buildprop_helper.sh

# Modified to support declarative syntax
modify_build_props() {
    local partition="$1"
    declare -n properties="$2"
    
    local prop_file
    case $partition in
        "system")
            prop_file="${ROM_FOLDER}/system/system/build.prop"
            ;;
        "vendor")
            prop_file="${ROM_FOLDER}/vendor/build.prop"
            ;;
        "product")
            prop_file="${ROM_FOLDER}/product/build.prop"
            ;;
        "odm")
            prop_file="${ROM_FOLDER}/odm/build.prop"
            ;;
        "system_ext")
            prop_file="${ROM_FOLDER}/system/system/system_ext/build.prop"
            [ ! -f "$prop_file" ] && prop_file="${ROM_FOLDER}/system_ext/build.prop"
            ;;
        *)
            echo "Invalid partition: $partition"
            return 1
            ;;
    esac

    mkdir -p "$(dirname "$prop_file")"
    [ ! -f "$prop_file" ] && touch "$prop_file"

    for key in "${!properties[@]}"; do
        value="${properties[$key]}"
        
        # Remove surrounding quotes if present
        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"

        # Check if property exists
        if grep -q "^[[:space:]]*${key}=" "$prop_file"; then
            current_val=$(grep "^[[:space:]]*${key}=" "$prop_file" | cut -d= -f2-)
            if [ "$current_val" != "$value" ]; then
                sed -i "s/^[[:space:]]*${key}=.*/$key=$value/" "$prop_file"
                echo "Updated: $partition:$key=$value"
            fi
        else
            echo "$key=$value" >> "$prop_file"
            echo "Added: $partition:$key=$value"
        fi
    done
}
