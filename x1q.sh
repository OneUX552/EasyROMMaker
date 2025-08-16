#!/bin/bash

# Location Declarations

export BASE_DIR="$(pwd)"
UTILS_DIR="${BASE_DIR}/ishihara/utils"
INSTALL_SCRIPT="${BASE_DIR}/make/install.sh"
SCRIPTS_DIR="${BASE_DIR}/ishihara/scripts"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Hello World"

device="x1q"
model="Galaxy S20 5G"
cpu="Snapdragon 865 kona/SD 8250"

echo "ishiharaROM for $device $model"
echo "Platform is $cpu"

# Dependency Check
DEPENDENCIES=("simg2img" "lpunpack" "openjdk-17-jdk" "xmlstarlet" "zip" "nodejs" "lz4" "make")
MISSING_COUNT=0

echo "[+] Checking system-wide dependencies..."
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


download_res() {
    local URL="https://my.filesto.space/download/gAAAAABoFKLvlxKH4X-KFhzcOHgHol29SVqvi7_DbMrWnDFNMMTLEawA17ZAYyI9wQntAiGUQOm1OlOPIFnACMMR1BlDkNIgSsm-xBgNRVya2N7fc-5iOAMYQEQuTkHbW3HkE3o7X05w"
    local FILE_NAME="resources.7z"
    local DEST_DIR="resources/"
    local MIN_SIZE_MB=300

    # Check if file exists and verify its size (600MB or more)
    if [[ -f "$FILE_NAME" ]]; then
        local FILE_SIZE_MB=$(( $(stat -c%s "$FILE_NAME") / 1024 / 1024 ))
        if (( FILE_SIZE_MB >= MIN_SIZE_MB )); then
            echo "File already exists and is 600MB+, skipping download."
            return 0
        fi
    fi

    echo "Downloading resources required for patching ROM..."
    curl -L "$URL" -o "$FILE_NAME"

    echo "Extracting contents to: $DEST_DIR"
    mkdir -p "$DEST_DIR"
    7z x "$FILE_NAME" -o"$DEST_DIR"

    echo "Download and extraction completed."
}



# CRB Environment Setup
setup_crb_environment() {
    # Load CRB path from config
    if [ ! -f "${BASE_DIR}/conf.txt" ]; then
        echo -e "${RED}ERROR: conf.txt not found in ${BASE_DIR}${NC}"
        exit 1
    fi

    source "${BASE_DIR}/conf.txt"
    if [ -z "$CRB_KITCHEN_PATH" ]; then
        echo -e "${RED}ERROR: CRB_KITCHEN_PATH not set in conf.txt${NC}"
        exit 1
    fi

    # Validate CRB kitchen structure
    local projects_dir="${CRB_KITCHEN_PATH}/Projects"
    if [ ! -d "$projects_dir" ]; then
        echo -e "${RED}ERROR: Invalid CRB kitchen - Projects directory not found at:"
        echo -e "${projects_dir}${NC}"
        exit 1
    fi

    # Project selection
    while true; do
        echo -e "${YELLOW}Available projects in CRB kitchen:${NC}"
        ls -1 "$projects_dir" | sed 's/^/  /'
        
        read -p "Enter project name: " project_name
        local crb_dir="${projects_dir}/${project_name}"
        
        if [ -d "$crb_dir" ]; then
            export CRB_DIR="$crb_dir"
            echo -e "${GREEN}Selected project: ${project_name}${NC}"
            break
        else
            echo -e "${RED}Project '${project_name}' not found!${NC}"
        echo -e "${YELLOW}Please enter a valid project name from the list above.${NC}"
        echo ""
        sleep 1
        continue
        fi
    done

    # Validate ROM directory
    local rom_dir="${CRB_DIR}/ROM"
    if [ ! -d "$rom_dir" ]; then
        echo -e "${RED}ERROR: ROM directory not found in project:"
        echo -e "${rom_dir}${NC}"
        exit 1
    fi
    
    export ROM_FOLDER="${rom_dir}"
    echo -e "${GREEN}[✓] ROM_FOLDER set to: ${ROM_FOLDER}${NC}"
}

# Function to update filesystem size in CRB config with additional modifications
update_filesystem_sizes() {
    echo -e "\n${GREEN}[+] Updating filesystem size configurations and making adjustments...${NC}"
    
    # Directory paths to check
    declare -A dir_paths=(
        ["system"]="${ROM_FOLDER}/system"
        ["vendor"]="${ROM_FOLDER}/vendor"
        ["odm"]="${ROM_FOLDER}/odm"
        ["product"]="${ROM_FOLDER}/product"
    )
    
    # Config file paths
    declare -A config_files=(
        ["system"]="${CRB_DIR}/Config/system_filesystem_features.txt"
        ["vendor"]="${CRB_DIR}/Config/vendor_filesystem_features.txt"
        ["odm"]="${CRB_DIR}/Config/odm_filesystem_features.txt"
        ["product"]="${CRB_DIR}/Config/product_filesystem_features.txt"
    )
    
    for partition in "${!dir_paths[@]}"; do
        dir_path="${dir_paths[$partition]}"
        config_file="${config_files[$partition]}"
        
        # Check if directory exists
        if [ ! -d "$dir_path" ]; then
            echo -e "${YELLOW}  Warning: $partition directory not found at $dir_path${NC}"
            continue
        fi
        
        # Calculate directory size in bytes
        size_bytes=$(du -sb "$dir_path" | cut -f1)
        
        # Special handling for odm - add 1MB (1048576 bytes)
        if [ "$partition" == "odm" ]; then
            size_bytes=$((size_bytes + 1048576))
            echo -e "${YELLOW}  Adding 1MB to odm partition size${NC}"
        fi
        
        # Convert to GB for display (optional)
        size_gb=$(echo "scale=2; $size_bytes/1024/1024/1024" | bc)
        
        echo -e "  ${partition}: ${size_gb} GB (${size_bytes} bytes)"
        
        # Check if config file exists
        if [ ! -f "$config_file" ]; then
            echo -e "${YELLOW}  Warning: Config file not found at $config_file${NC}"
            continue
        fi
        
        # Update the ImageSize in config file
        if grep -q '"ImageSize":' "$config_file"; then
            # Using temp file for in-place editing
            temp_file="${config_file}.tmp"
            sed "s/\"ImageSize\":.*/\"ImageSize\": \"${size_bytes}\",/" "$config_file" > "$temp_file" && \
            mv "$temp_file" "$config_file"
            
            echo -e "  ${GREEN}✓ Updated ${partition} config${NC}"
        else
            echo -e "${YELLOW}  Warning: ImageSize field not found in ${config_file}${NC}"
        fi
    done
    
    # Remove selinux folders if they exist
    echo -e "\n${GREEN}[+] Cleaning up selinux directories...${NC}"
    selinux_dirs=(
        "${ROM_FOLDER}/odm/etc/selinux"
        "${ROM_FOLDER}/product/etc/selinux"
    )
    
    for dir in "${selinux_dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo -e "  Removing: ${dir}"
            rm -rf "$dir"
        else
            echo -e "  ${YELLOW}Not found: ${dir}${NC}"
        fi
    done
    
    echo -e "${GREEN}[✓] Filesystem adjustments completed${NC}"
}

download_res

# Call the CRB setup function
setup_crb_environment

# Source helper script
HELPER_SCRIPT="${UTILS_DIR}/ff_helper.sh"
if [ ! -f "${HELPER_SCRIPT}" ]; then
    echo -e "${RED}ERROR: Helper script not found at ${HELPER_SCRIPT}${NC}"
    exit 1
fi

source "${HELPER_SCRIPT}"

run_device_scripts() {
    local device_scripts_dir="${BASE_DIR}/devices/${device}/scripts"
    
    # Check if device scripts directory exists
    if [ ! -d "${device_scripts_dir}" ]; then
        echo -e "${YELLOW}[!] No device scripts directory found at ${device_scripts_dir}${NC}"
        return 0
    fi

    # Initialize counters
    local DEVICE_TOTAL=0
    local DEVICE_SUCCESS=0
    local DEVICE_FAILED=0
    local device_failed_scripts=()

    echo -e "\n${YELLOW}[+] Locating device-specific scripts for ${device}...${NC}"
    shopt -s nullglob
    local device_scripts=("${device_scripts_dir}"/*.sh)
    DEVICE_TOTAL=${#device_scripts[@]}

    if [ ${DEVICE_TOTAL} -eq 0 ]; then
        echo -e "${YELLOW}[!] No device scripts found in ${device_scripts_dir}${NC}"
        return 0
    fi

    # Sort device scripts
    local IFS=$'\n'
    local sorted_device_scripts=($(sort -V <<< "${device_scripts[*]}"))
    unset IFS

    echo -e "${GREEN}[+] Found ${DEVICE_TOTAL} device-specific scripts${NC}"
    
    for script in "${sorted_device_scripts[@]}"; do
        echo -e "${GREEN}==================================================${NC}"
        echo -e "${GREEN}[+] Executing DEVICE SCRIPT: $(basename "${script}")${NC}"
        echo -e "${GREEN}==================================================${NC}"
        
        [ ! -x "${script}" ] && chmod +x "${script}"
        
        if (
            cd "${ROM_FOLDER}" && \
            "${script}"
        ); then
            ((DEVICE_SUCCESS++))
            echo -e "${GREEN}[✓] Device script success: $(basename "${script}")${NC}\n"
        else
            ((DEVICE_FAILED++))
            device_failed_scripts+=("$(basename "${script}")")
            echo -e "${RED}[✗] Device script failed: $(basename "${script}")${NC}\n"
        fi
    done

    # Update main counters
    TOTAL_SCRIPTS=$((TOTAL_SCRIPTS + DEVICE_TOTAL))
    SUCCESS_SCRIPTS=$((SUCCESS_SCRIPTS + DEVICE_SUCCESS))
    FAILED_SCRIPTS=$((FAILED_SCRIPTS + DEVICE_FAILED))
    failed_scripts+=("${device_failed_scripts[@]}")

    echo -e "${GREEN}[✓] Device script execution completed (${DEVICE_SUCCESS}/${DEVICE_TOTAL} succeeded)${NC}"
}



# Initialize counters
TOTAL_SCRIPTS=0
SUCCESS_SCRIPTS=0
FAILED_SCRIPTS=0
declare -a failed_scripts

# Find and execute scripts in ROM directory
echo -e "\n${YELLOW}[+] Locating scripts in ROM directory...${NC}"
shopt -s nullglob
scripts=("${SCRIPTS_DIR}"/*.sh)
TOTAL_SCRIPTS=${#scripts[@]}

if [ ${TOTAL_SCRIPTS} -eq 0 ]; then
    echo -e "${RED}ERROR: No scripts found in ${ROM_FOLDER}${NC}"
    exit 1
fi

# Sort scripts numerically
IFS=$'\n' sorted_scripts=($(sort -V <<< "${scripts[*]}"))
unset IFS

# Execute scripts in order
echo -e "\n${GREEN}[+] Found ${TOTAL_SCRIPTS} scripts in ROM directory${NC}"
echo -e "${YELLOW}[+] Starting processing...${NC}\n"

for script in "${sorted_scripts[@]}"; do
    echo -e "${GREEN}==================================================${NC}"
    echo -e "${GREEN}[+] Executing: $(basename "${script}")${NC}"
    echo -e "${GREEN}==================================================${NC}"
    
    # Make script executable
    if [ ! -x "${script}" ]; then
        chmod +x "${script}"
    fi
    
    # Execute script
    if "${script}"; then
        ((SUCCESS_SCRIPTS++))
        echo -e "${GREEN}[✓] Success: $(basename "${script}")${NC}\n"
    else
        ((FAILED_SCRIPTS++))
        failed_scripts+=("$(basename "${script}")")
        echo -e "${RED}[✗] Failed: $(basename "${script}")${NC}\n"
    fi
done

run_device_scripts

# Print summary
echo -e "${GREEN}================== PROCESSING SUMMARY ==================${NC}"
echo -e "ROM Directory:    ${ROM_FOLDER}"
echo -e "Total Scripts:    ${TOTAL_SCRIPTS}"
echo -e "Device Scripts:   ${BASE_DIR}/devices/${device}/scripts"
echo -e "${GREEN}Successful:      ${SUCCESS_SCRIPTS}${NC}"
echo -e "${RED}Failed:          ${FAILED_SCRIPTS}${NC}"

if [ ${FAILED_SCRIPTS} -gt 0 ]; then
    echo -e "\n${RED}Failed scripts:${NC}"
    printf ' - %s\n' "${failed_scripts[@]}"
    echo -e "\n${YELLOW}Troubleshooting tips:${NC}"
    echo "1. Check the error messages above for each failed script"
    echo "2. Try running failed scripts manually to debug:"
    echo "   cd \"${ROM_FOLDER}\" && bash <scriptname.sh>"
fi

echo -e "${GREEN}[+] Initial setup completed!${NC}"



update_filesystem_sizes


echo "ishiharaROM for $device $model is succesfully patched. Now go to your ROM Kitchen and Build system,product,odm and vendor. And last create a ROM ZIP"
