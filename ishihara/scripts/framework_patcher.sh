#!/bin/bash
# framework_patcher.sh 

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Path Configuration (relative to project root)
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"  # Two levels up from scripts/
APKTOOL_JAR="$PROJECT_ROOT/external/apktool/apktool.jar"
PATCHES_DIR="$PROJECT_ROOT/resources/patches/framework.jar"
ROM_FRAMEWORK="$ROM_FOLDER/system/system/framework/framework.jar"
WORK_DIR="$ROM_FOLDER/system/system/framework/frameworkedit"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verify all paths exist
verify_paths() {
    echo -e "${GREEN}[+] Verifying paths...${NC}"
    
    # 1. Check apktool
    if [ ! -f "$APKTOOL_JAR" ]; then
        echo -e "${RED}ERROR: apktool.jar not found at:${NC}"
        echo -e "  ${YELLOW}$APKTOOL_JAR${NC}"
        echo -e "Directory contents:"
        ls -l "$PROJECT_ROOT/external/apktool" || echo "Directory doesn't exist"
        exit 1
    fi
    echo -e "${GREEN}✓ Found apktool.jar${NC}"

    # 2. Check patches
    if [ ! -d "$PATCHES_DIR" ]; then
        echo -e "${RED}ERROR: Patches directory not found at:${NC}"
        echo -e "  ${YELLOW}$PATCHES_DIR${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Found $(ls "$PATCHES_DIR"/*.patch | wc -l) patch files${NC}"

    # 3. Check framework.jar
    if [ ! -f "$ROM_FRAMEWORK" ]; then
        echo -e "${RED}ERROR: framework.jar not found in ROM directory!${NC}"
        echo -e "  ${YELLOW}Expected: $ROM_FRAMEWORK${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Found framework.jar${NC}"
}

# Cleanup function
cleanup() {
    echo -e "${YELLOW}[*] Cleaning working directory...${NC}"
    rm -rf "$WORK_DIR"
}

# Main process
main() {
    verify_paths
    
    echo -e "${GREEN}[+] Decompiling framework.jar...${NC}"
    java -jar "$APKTOOL_JAR" d \
        -api 34 \
        -b \
        -o "$WORK_DIR" \
        "$ROM_FRAMEWORK" || {
            echo -e "${RED}ERROR: Decompilation failed${NC}"
            cleanup
            exit 1
        }

    # =================================================================
    # ANDROID 15 WORKAROUND - ADD AFTER DECOMPILATION
    # =================================================================
    echo -e "${GREEN}[+] Checking for Android 14 resources...${NC}"
    if unzip -l "$ROM_FRAMEWORK" | grep -q "debian.mime.types"; then
        echo -e "${YELLOW}[*] Found Android 15 resources, extracting...${NC}"
        mkdir -p "$WORK_DIR/unknown"
        unzip -q "$ROM_FRAMEWORK" "res/*" -d "$WORK_DIR/unknown" || {
            echo -e "${RED}ERROR: Failed to extract Android 15 resources${NC}"
            cleanup
            exit 1
        }
    fi

    echo -e "${GREEN}[+] Applying patches...${NC}"
    for patch in "$PATCHES_DIR"/*.patch; do
        echo -e "${YELLOW}  Applying $(basename "$patch")...${NC}"
        patch -d "$WORK_DIR" -p1 < "$patch" || {
            echo -e "${RED}ERROR: Patch failed${NC}"
            cleanup
            exit 1
        }
    done

    echo -e "${GREEN}[+] Rebuilding framework.jar...${NC}"
    java -jar "$APKTOOL_JAR" b \
        -c \
        -p res \
        --use-aapt2 \
        "$WORK_DIR" \
        -o "$WORK_DIR/dist/framework.jar" || {
            echo -e "${RED}ERROR: Rebuild failed${NC}"
            cleanup
            exit 1
        }

    # =================================================================
    # ANDROID 15 WORKAROUND - ADD BEFORE REPLACING ORIGINAL
    # =================================================================
    if [ -d "$WORK_DIR/unknown" ]; then
        echo -e "${GREEN}[+] Reintegrating Android 15 resources...${NC}"
        (
            cd "$WORK_DIR/unknown"
            zip -qr "$WORK_DIR/dist/framework.jar" . || {
                echo -e "${RED}ERROR: Failed to add Android 15 resources${NC}"
                cleanup
                exit 1
            }
        )
    fi

    echo -e "${GREEN}[+] Replacing original framework.jar...${NC}"
    mv "$WORK_DIR/dist/framework.jar" "$ROM_FRAMEWORK" || {
        echo -e "${RED}ERROR: Failed to replace framework.jar${NC}"
        cleanup
        exit 1
    }

    cleanup
    echo -e "${GREEN}[✓] Framework successfully patched!${NC}"
}

# Execute
main
