#!/bin/bash

# Configuration
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verify ROM_FOLDER is set
if [ -z "$ROM_FOLDER" ]; then
    echo -e "${RED}ERROR: ROM_FOLDER environment variable not set!${NC}"
    echo "Usage: This script should be called from the main build script"
    exit 1
fi

# Set build.prop paths
declare -A BUILD_PROP_PATHS=(
    ["system"]="${ROM_FOLDER}/system/system/build.prop"
    ["vendor"]="${ROM_FOLDER}/vendor/default.prop"
    ["product"]="${ROM_FOLDER}/product/etc/build.prop"
    ["odm"]="${ROM_FOLDER}/odm/build.prop"
    ["system_ext"]="${ROM_FOLDER}/system/system/system_ext/etc/build.prop"
)

# Fallback for system_ext
[ ! -f "${BUILD_PROP_PATHS[system_ext]}" ] && \
BUILD_PROP_PATHS["system_ext"]="${ROM_FOLDER}/system_ext/build.prop"

# Build.prop properties
declare -A SYSTEM_PROPS=(
    ["ro.product.system.model"]="G981N"
    ["ro.factory.model"]="G981N"
	["ro.product.system.name"]="e3qxxx"
    
)

declare -A VENDOR_PROPS=(
    ["ro.surface_flinger.enable_frame_rate_override"]="false"
    ["ro.surface_flinger.use_content_detection_for_refresh_rate"]="true"
	["ro.surface_flinger.set_idle_timer_ms"]="200"
    ["ro.surface_flinger.set_touch_timer_ms"]="300"
    ["ro.surface_flinger.set_display_power_timer_ms"]="300"
)

declare -A PRODUCT_PROPS=(
 ["ro.product.product.model"]="G981N"
 ["ro.product.product.name"]="e3qxxx"

)

declare -A ODM_PROPS=(
 ["ro.product.odm.model"]="G981N"
 ["ro.product.odm.name"]="e3qxxx"
)

declare -A SYSTEM_EXT_PROPS=(
 ["ro.product.system_ext.model"]="G981N"
 ["ro.product.system_ext.name"]="e3qxxx"
)

# Verify and create build.prop files
echo -e "\n${GREEN}[+] Verifying build.prop files...${NC}"
for partition in "${!BUILD_PROP_PATHS[@]}"; do
    prop_file="${BUILD_PROP_PATHS[$partition]}"
    if [ ! -f "$prop_file" ]; then
        echo -e "${YELLOW}WARNING: Creating missing ${partition} build.prop...${NC}"
        mkdir -p "$(dirname "$prop_file")"
        touch "$prop_file"
    fi
done

# Property modification function
modify_build_property() {
    local partition="$1"
    local prop="$2"
    local value="$3"
    
    local prop_file="${BUILD_PROP_PATHS[$partition]}"
    
    # Clean existing property
    sed -i "/^[[:space:]]*${prop}=/d" "$prop_file"
    
    # Add new property
    echo "${prop}=${value}" >> "$prop_file"
    echo -e "  ${GREEN}Set: ${partition}/${prop}=${value}${NC}"
}

# Process properties
echo -e "\n${GREEN}[+] Updating build properties...${NC}"
process_properties() {
    local partition="$1"
    declare -n props="$2"
    
    echo -e "${YELLOW}Processing ${partition} build.prop...${NC}"
    for prop in "${!props[@]}"; do
        modify_build_property "$partition" "$prop" "${props[$prop]}" || {
            echo -e "${RED}ERROR: Failed to modify ${partition}/${prop}${NC}"
        }
    done
}

# Apply all properties
process_properties "system" SYSTEM_PROPS
process_properties "vendor" VENDOR_PROPS
process_properties "product" PRODUCT_PROPS
process_properties "odm" ODM_PROPS
process_properties "system_ext" SYSTEM_EXT_PROPS

# Verification
echo -e "\n${GREEN}[✓] Build properties configuration complete${NC}"
echo -e "${YELLOW}Modified properties:${NC}"

for partition in "${!BUILD_PROP_PATHS[@]}"; do
    prop_file="${BUILD_PROP_PATHS[$partition]}"
    echo -e "\n${YELLOW}=== ${partition} build.prop ===${NC}"
    grep -vE '^#|^$' "$prop_file" | sort | sed 's/^/  /'
done

exit 0
