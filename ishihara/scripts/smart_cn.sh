#!/bin/bash
# SmartManagerCN Full Installer
# Uses BASE_DIR and ROM_FOLDER from parent script

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verify environment variables are set
if [ -z "$BASE_DIR" ]; then
    echo -e "${RED}ERROR: BASE_DIR environment variable not set!${NC}"
    exit 1
fi

if [ -z "$ROM_FOLDER" ]; then
    echo -e "${RED}ERROR: ROM_FOLDER environment variable not set!${NC}"
    exit 1
fi

# Paths
SOURCE_DIR="${BASE_DIR}/resources/cn"
TARGET_DIR="${ROM_FOLDER}/system/system"
FF_HELPER="${BASE_DIR}/ishihara/utils/ff_helper.sh"

# ================================================
# 1. DELETE OLD FILES
# ================================================
echo -e "${GREEN}[1/3] Removing old SmartManager files...${NC}"

# Files to delete (relative to TARGET_DIR)
DIRS_TO_DELETE=(
    "priv-app/SmartManager_v5"
    "app/SmartManager_v6_DeviceSecurity"
    "priv-app/SmartManager_v6_DeviceSecurity"
    "priv-app/SmartManagerCN"
    "app/SmartManager_v6_DeviceSecurity_CN"
    "priv-app/SmartManager_v6_DeviceSecurity_CN"
    "priv-app/SAppLock"
    "priv-app/Firewall"
)

for file in "${DIRS_TO_DELETE[@]}"; do
    full_path="${TARGET_DIR}/${file}"
    if [ -e "$full_path" ]; then
        echo "Removing: $full_path"
        rm -rf "$full_path"
    fi
done

# ================================================
# 2. COPY NEW FILES
# ================================================
echo -e "\n${GREEN}[2/3] Installing new SmartManagerCN...${NC}"

if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}ERROR: Source directory not found at $SOURCE_DIR${NC}"
    exit 1
fi

echo "Copying from: $SOURCE_DIR"
echo "Installing to: $TARGET_DIR"

mkdir -p "$TARGET_DIR"
cp -av "$SOURCE_DIR"/* "$TARGET_DIR/" || {
    echo -e "${RED}ERROR: File copy failed${NC}"
    exit 1
}

# ================================================
# 3. UPDATE FLOATING FEATURES
# ================================================
echo -e "\n${GREEN}[3/3] Updating floating features...${NC}"

# Load XML helper
if [ ! -f "$FF_HELPER" ]; then
    echo -e "${RED}ERROR: Missing ff_helper.sh at $FF_HELPER${NC}"
    exit 1
fi

source "$FF_HELPER" || {
    echo -e "${RED}ERROR: Failed to load ff_helper.sh${NC}"
    exit 1
}

FF_FILE="${TARGET_DIR}/etc/floating_feature.xml"

# Initialize if missing
init_xml_file "$FF_FILE" || {
    echo -e "${RED}ERROR: Cannot initialize floating_feature.xml${NC}"
    exit 1
}

# Tag modifications
declare -A TAG_UPDATES=(
    ["SEC_FLOATING_FEATURE_SMARTMANAGER_CONFIG_PACKAGE_NAME"]="com.samsung.android.sm_cn"
    ["SEC_FLOATING_FEATURE_SECURITY_CONFIG_DEVICEMONITOR_PACKAGE_NAME"]="com.samsung.android.sm.devicesecurity.tcm"
    ["SEC_FLOATING_FEATURE_COMMON_SUPPORT_NAL_PRELOADAPP_REGULATION"]="TRUE"
)

for tag in "${!TAG_UPDATES[@]}"; do
    modify_feature_tag "$tag" "${TAG_UPDATES[$tag]}" "$FF_FILE"
done

# ================================================
# VERIFICATION
# ================================================
echo -e "\n${GREEN}[✓] Installation Complete${NC}"
echo -e "${YELLOW}Modified floating features:${NC}"
grep -E '<SEC_FLOATING_FEATURE_(SMARTMANAGER|SECURITY|COMMON)' "$FF_FILE" 2>/dev/null || {
    echo "  No matching floating features found"
}

echo -e "\n${GREEN}All files copied from:${NC}"
find "$SOURCE_DIR" -type f -printf "  %P\n"

echo -e "\n${GREEN}Installed to:${NC}"
find "$TARGET_DIR" \( -path "*SmartManager*" -o -path "*sm_cn*" \) -printf "  %P\n" 2>/dev/null || {
    echo "  No matching installed files found"
}

exit 0