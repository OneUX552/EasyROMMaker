#!/bin/bash
set -e

# Configuration
export BASE_DIR="$(pwd)"


SCRIPTS_DIR="${BASE_DIR}/ishihara/scripts"

UTILS_DIR="${BASE_DIR}/ishihara/utils"

FIRMWARE_DIR="${BASE_DIR}/firmware/"

DEVICES_DIR="${BASE_DIR}/devices"

INSTALL_SCRIPT="${BASE_DIR}/make/install.sh"

PARTITIONS_DIR="${BASE_DIR}/firmware/work_dir/partitions"

# Device List
declare -A DEVICES=(
    ["1"]="(x1q) S20 5G"
    ["2"]="(y2q) S20+ 5G"
    ["3"]="(z3q) S20 Ultra"
    ["4"]="(c1q) Note20 5G"
    ["5"]="(c2q) Note20 Ultra"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Error handling
trap 'echo -e "${RED}Script interrupted! Exiting...${NC}"; exit 1' INT

# Device Selection Function
select_device() {
    echo -e "${YELLOW}[+] Available Devices:${NC}"
    for key in "${!DEVICES[@]}"; do
        echo "  $key) ${DEVICES[$key]}"
    done

    while true; do
        read -p "Select device [1-5]: " choice
        if [[ -n "${DEVICES[$choice]}" ]]; then
            # Extract device code between parentheses
            DEVICE_CODE=$(echo "${DEVICES[$choice]}" | grep -oP '(?<=\().*(?=\))')
            DEVICE_NAME=$(echo "${DEVICES[$choice]}" | sed 's/(.*)//' | xargs)
            echo -e "${GREEN}[+] Selected: ${DEVICE_NAME} (${DEVICE_CODE})${NC}"
            break
        else
            echo -e "${RED}[-] Invalid selection! Please try again.${NC}"
        fi
    done

    export DEVICE_CODE DEVICE_NAME
}


   



create_rom_kitchen_zip() {
    local timestamp=$(date +"%Y-%m-%d_%H-%M")
    local zip_name="${DEVICE_CODE}_${timestamp}.zip"
    local zip_dir="${BASE_DIR}/input_rom_kitchen"
    local img_count

    echo -e "${YELLOW}[+] Preparing ROM kitchen package...${NC}"

    # Verify IMG files exist
    img_count=$(find "${PARTITIONS_DIR}" -maxdepth 1 -name "*.img" | wc -l)
    if [ "$img_count" -eq 0 ]; then
        echo -e "${RED}[-] Error: No .img files found in ${PARTITIONS_DIR}${NC}"
        return 1
    fi

    # Create target directory
    mkdir -p "${zip_dir}" || {
        echo -e "${RED}[-] Failed to create output directory${NC}"
        return 1
    }

    # Create ZIP with no compression
    echo -e "${GREEN}[+] Creating ZIP archive (Store mode - no compression)...${NC}"
    if ! (cd "${PARTITIONS_DIR}" && zip -0 -r "${zip_dir}/${zip_name}" ./*.img); then
        echo -e "${RED}[-] ZIP creation failed${NC}"
        rm -f "${zip_dir}/${zip_name}" 2>/dev/null
        return 1
    fi

    # Verify final ZIP
    if [ -f "${zip_dir}/${zip_name}" ]; then
        echo -e "${GREEN}[✓] ROM kitchen package created: ${zip_dir}/${zip_name}${NC}"
    else
        echo -e "${RED}[-] Unknown error in ZIP creation${NC}"
        return 1
    fi
}

# --------------------------------------------------
# Initial Setup
# --------------------------------------------------
clear
echo -e "${YELLOW}

████████████████████████████████████████████████████████████████████████████████████
█▄─▄█─▄▄▄▄█─█─█▄─▄█─█─██▀▄─██▄─▄▄▀██▀▄─████▄─▄▄▀█─▄▄─█▄─▀█▀─▄███▀▄▄▀█▀▄▄▀█░▄▄▄█─▄▄─█
██─██▄▄▄▄─█─▄─██─██─▄─██─▀─███─▄─▄██─▀─█████─▄─▄█─██─██─█▄█─████▀▄▄▀██▀▄██▄▄▄▒█─██─█
▀▄▄▄▀▄▄▄▄▄▀▄▀▄▀▄▄▄▀▄▀▄▀▄▄▀▄▄▀▄▄▀▄▄▀▄▄▀▄▄▀▀▀▄▄▀▄▄▀▄▄▄▄▀▄▄▄▀▄▄▄▀▀▀█▄▄█▀▄▄▄▄▀▄▄▄▄▀▄▄▄▄▀


Firmware Downloader and Extractor for target device 


${NC}"

DEPENDENCIES=("simg2img" "lpunpack" "openjdk-17-jdk" "xmlstarlet" "zip" "nodejs" "lz4" "make")
MISSING_COUNT=0

echo "[+] Checking system-wide dependencies..."

# Check each dependency
for dep in "${DEPENDENCIES[@]}"; do
    if command -v "$dep" >/dev/null 2>&1 || dpkg -l | grep -qw "$dep"; then
        echo "[+] $dep is installed."
    else
        echo "[-] $dep is missing."
        MISSING_COUNT=$((MISSING_COUNT + 1))
    fi
done


if [ "$MISSING_COUNT" -gt 0 ]; then
    echo "[+] $MISSING_COUNT dependencies missing. Running install script..."
    if [ -f "$INSTALL_SCRIPT" ]; then
        bash "$INSTALL_SCRIPT" || {
            echo "[-] Install script failed! Please resolve dependency issues manually."
            exit 1
        }
    else
        echo "[-] install.sh not found! Please provide the installation script."
        exit 1
    fi
else
    echo "[+] All dependencies are already installed. Skipping installation."
fi


vendor_props() {
    local vendor_script_path="${DEVICES_DIR}/${DEVICE_CODE}/vendor/vendor.sh"
    
    echo -e "${YELLOW}[+] Checking vendor operations for ${DEVICE_NAME}...${NC}"
    
    if [ -f "${vendor_script_path}" ]; then
        echo -e "${GREEN}[+] Found vendor script at ${vendor_script_path}${NC}"
        chmod +x "${vendor_script_path}"
        
        # Execute with proper arguments
        if ! bash "${vendor_script_path}" "${BASE_DIR}" "${DEVICE_CODE}"; then
            echo -e "${RED}[-] Vendor script execution failed!${NC}"
            exit 1
        fi
        echo -e "${GREEN}[✓] Vendor operations completed${NC}"
    else
        echo -e "${YELLOW}[!] No vendor script found for ${DEVICE_CODE}, skipping...${NC}"
    fi
}

check_firmware() {
    echo -e "${YELLOW}[+] Checking firmware files...${NC}"
    
    # Search recursively in firmware directory and subdirectories
    AP_FILES=$(find "${FIRMWARE_DIR}" -type f \( -name "AP_*.tar.md5" -o -name "AP_*.tar" \))
    
    if [ -n "$AP_FILES" ]; then
        echo -e "${GREEN}[+] Found firmware files:${NC}"
        echo "$AP_FILES" | sed 's/^/  /'
        return 0
    else
        echo -e "${RED}[-] No AP files found in ${FIRMWARE_DIR}${NC}"
        return 1
    fi
}




# --------------------------------------------------
# Firmware Download
# --------------------------------------------------
download_firmware() {
    echo -e "${YELLOW}[+] Starting firmware download...${NC}"
    bash "${UTILS_DIR}/samfirm.sh" || {
        echo -e "${RED}[-] Firmware download failed!${NC}"
        exit 1
    }
    echo -e "${GREEN}[+] Firmware download completed${NC}"
}

# --------------------------------------------------
# Firmware Extraction
# --------------------------------------------------
extract_firmware() {
    echo -e "${YELLOW}[+] Extracting firmware...${NC}"
    sudo bash "${UTILS_DIR}/extract_fw.sh" "${BASE_DIR}" || {
        echo -e "${RED}[-] Extraction failed!${NC}"
        exit 1
    }
    echo -e "${GREEN}[+] Firmware extracted successfully${NC}"
}

# --------------------------------------------------
# Main Flow
# --------------------------------------------------
# Check or download firmware
if ! check_firmware; then
    download_firmware
fi

if ! check_partitions; then
extract_firmware
fi

select_device

vendor_props

create_rom_kitchen_zip


echo -e "${GREEN}[+] Initial setup completed successfully!${NC}"
