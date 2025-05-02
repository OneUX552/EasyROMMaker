#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'


# Set paths
SOURCE_DIR="$BASE_DIR/resources/stock"
TARGET_DIR="$ROM_FOLDER/system"

# Create target system directory if it doesn't exist
mkdir -p "$TARGET_DIR"

echo -e "${GREEN}[+] Copying files from stock resources to ROM...${NC}"
echo -e "Source: ${YELLOW}${SOURCE_DIR}${NC}"
echo -e "Target: ${YELLOW}${TARGET_DIR}${NC}"

# Copy files with preservation of permissions and attributes
if ! cp -av "$SOURCE_DIR"/. "$TARGET_DIR"/; then
    echo -e "${RED}ERROR: Failed to copy files${NC}"
    exit 1
fi

# Verify copy operation
echo -e "\n${GREEN}[✓] Copy operation completed${NC}"
echo -e "${YELLOW}Copied files:${NC}"
find "$SOURCE_DIR" -type f -printf "  %P\n"

echo -e "\n${GREEN}[✓] ROM resources successfully updated!${NC}"
exit 0