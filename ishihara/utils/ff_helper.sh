#!/bin/bash

# Helper for floating_feature.xml modifications

# Check if tag exists
tag_exists() {
    xmlstarlet sel -t -v "//$1" "$2" 2>/dev/null
    return $?
}

# Update or add tag
modify_feature_tag() {
    local tag="$1"
    local value="$2"
    local xml_file="$3"

    # Create backup
    cp "$xml_file" "${xml_file}.bak" 2>/dev/null

    # Check existence
    current_value=$(tag_exists "$tag" "$xml_file")
    
    if [ $? -eq 0 ]; then
        # Update existing tag if value differs
        if [ "$current_value" != "$value" ]; then
            xmlstarlet ed -L -u "//$tag" -v "$value" "$xml_file"
            echo "Updated: <$tag>$value</$tag>"
        fi
    else
        # Add new tag before closing element
        xmlstarlet ed -L \
            -s '/SecFloatingFeatureSet' -t elem -n "$tag" -v "$value" \
            "$xml_file"
        echo "Added: <$tag>$value</$tag>"
    fi
}

# Initialize XML structure if missing
init_xml_file() {
    local xml_file="$1"
    [ -f "$xml_file" ] || {
        mkdir -p "$(dirname "$xml_file")"
        echo '<?xml version="1.0" encoding="UTF-8"?>'
        echo '<SecFloatingFeatureSet>'
        echo '</SecFloatingFeatureSet>'
    } > "$xml_file"
}