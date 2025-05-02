#!/bin/bash
# Bluetooth Library Patcher - Fixed Mounting Version

# Configuration
TMP_DIR="/tmp/bluetooth_patch"
TARGET_LIB="$ROM_FOLDER/system/system/lib64/libbluetooth_jni.so"
APEX_FILE="$ROM_FOLDER/system/system/apex/com.android.btservices.apex"
WORK_DIR="$ROM_FOLDER"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Hex patching function
HEX_PATCH() {
    local file="$1"
    local original_hex="$2"
    local patched_hex="$3"
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}ERROR: File $file not found${NC}"
        return 1
    fi

    original_pattern=$(echo "$original_hex" | sed 's/../\\x&/g')
    patched_pattern=$(echo "$patched_hex" | sed 's/../\\x&/g')
    
    if ! grep -q -a -F -P "$original_pattern" "$file"; then
        echo -e "${YELLOW}WARNING: Original hex pattern not found (may already be patched)${NC}"
        return 1
    fi
    
    tmp_file="${file}.tmp"
    perl -pe "s/$original_pattern/$patched_pattern/g" "$file" > "$tmp_file" && \
    mv "$tmp_file" "$file"
    
    if grep -q -a -F -P "$patched_pattern" "$file"; then
        echo -e "${GREEN}✓ Hex patch applied successfully${NC}"
        return 0
    else
        echo -e "${RED}ERROR: Hex patch failed${NC}"
        return 1
    fi
}

# Main patching logic
if [ ! -f "$TARGET_LIB" ]; then
    echo -e "${YELLOW}[*] libbluetooth_jni.so not found, extracting from APEX...${NC}"
    
    [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"

    if [ ! -f "$APEX_FILE" ]; then
        echo -e "${RED}ERROR: APEX file not found at $APEX_FILE${NC}"
        exit 1
    fi

    if ! unzip -q -j "$APEX_FILE" "apex_payload.img" -d "$TMP_DIR"; then
        echo -e "${RED}ERROR: Failed to extract apex_payload.img${NC}"
        exit 1
    fi

    # Use debugfs instead of mount for non-root operation
    echo -e "${YELLOW}[*] Extracting using debugfs (no root required)...${NC}"
    mkdir -p "$TMP_DIR/tmp_out"
    
    if ! debugfs -R "rdump lib64 $TMP_DIR/tmp_out" "$TMP_DIR/apex_payload.img" >/dev/null 2>&1; then
        echo -e "${RED}ERROR: Failed to extract files using debugfs${NC}"
        echo -e "${YELLOW}Trying alternative extraction method...${NC}"
        
        # Fallback to using simg2img and mount if debugfs fails
        if command -v simg2img >/dev/null; then
            simg2img "$TMP_DIR/apex_payload.img" "$TMP_DIR/apex_payload.raw.img"
            if sudo mount -o ro "$TMP_DIR/apex_payload.raw.img" "$TMP_DIR/tmp_out"; then
                if [ -f "$TMP_DIR/tmp_out/lib64/libbluetooth_jni.so" ]; then
                    mkdir -p "$(dirname "$TARGET_LIB")"
                    sudo cp "$TMP_DIR/tmp_out/lib64/libbluetooth_jni.so" "$TARGET_LIB"
                    sudo chmod 644 "$TARGET_LIB"
                    sudo umount "$TMP_DIR/tmp_out"
                else
                    echo -e "${RED}ERROR: Library not found in mounted image${NC}"
                    sudo umount "$TMP_DIR/tmp_out"
                    exit 1
                fi
            else
                echo -e "${RED}ERROR: Both debugfs and mount methods failed${NC}"
                exit 1
            fi
        else
            echo -e "${RED}ERROR: simg2img not available for fallback extraction${NC}"
            exit 1
        fi
    else
        # Successfully extracted with debugfs
        mkdir -p "$(dirname "$TARGET_LIB")"
        cp "$TMP_DIR/tmp_out/lib64/libbluetooth_jni.so" "$TARGET_LIB"
        chmod 644 "$TARGET_LIB"
    fi

    rm -rf "$TMP_DIR"
    echo -e "${GREEN}✓ Successfully extracted libbluetooth_jni.so${NC}"
fi

# Apply hex patch
echo -e "${YELLOW}[*] Applying hex patch...${NC}"
HEX_PATCH "$TARGET_LIB" \
    "6804003528008052" \
    "2b00001428008052" || {
    echo -e "${RED}ERROR: Failed to apply hex patch${NC}"
    exit 1
}

echo -e "${GREEN}[✓] Bluetooth library successfully patched!${NC}"
exit 0