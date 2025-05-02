#!/bin/bash
# handle_device_vendor.sh - Proper device-specific vendor handler

set -eo pipefail


source "${BASE_DIR}/device_data/current_device.cfg" 2>/dev/null || {
    echo -e "\033[31mERROR: Device configuration missing! Run main script first.\033[0m"
    exit 1
}

WORK_DIR="${FIRMWARE_DIR}"
VENDOR_DIR="${WORK_DIR}/vendor/${DEVICE_CODE}"  
PARTITIONS_DIR="${WORK_DIR}/work_dir/partitions"


declare -A DEVICE_URLS=(
    ["x1q"]="https://example.com/x1q_vendor.img"
    ["y2q"]="https://example.com/y2q_vendor.img"
    ["z3q"]="https://get.filesto.space/download/gAAAAABoDjyJ7goLo4j8hR5QOfjmjibCeIHme4FkFpeWcW1N2InUYIXlP4898g5qLS1YZhASn3hSeAe50kfSWOTql8dNdUps3cg8T2P728OBjr1ykZ6bDNQ="
    ["c1q"]="https://example.com/c1q_vendor.img"
    ["c2q"]="https://example.com/c2q_vendor.img"
)


validate_device() {
    if [[ -z "${DEVICE_URLS[$DEVICE_CODE]}" ]]; then
        echo -e "\033[31mERROR: Unsupported device '${DEVICE_CODE}'\033[0m"
        exit 1
    fi
}

download_vendor() {
    mkdir -p "${VENDOR_DIR}"
    
    if [[ -f "${VENDOR_DIR}/vendor.img" ]]; then
        echo -e "\033[33mExisting vendor.img found for ${DEVICE_CODE}, skipping download\033[0m"
        return
    fi

    echo -e "\033[36mDownloading vendor image for ${DEVICE_NAME}...\033[0m"
    if ! wget -O "${VENDOR_DIR}/vendor.img" "${DEVICE_URLS[$DEVICE_CODE]}"; then
        echo -e "\033[31mFailed to download vendor image!\033[0m"
        exit 1
    fi
}

move_to_partitions() {
    if [[ ! -f "${VENDOR_DIR}/vendor.img" ]]; then
        echo -e "\033[31mMissing vendor.img in ${VENDOR_DIR}\033[0m"
        exit 1
    fi

    echo -e "\033[36mMoving vendor.img to partitions directory\033[0m"
    mkdir -p "${PARTITIONS_DIR}"
    mv -f "${VENDOR_DIR}/vendor.img" "${PARTITIONS_DIR}/"
}


validate_device
download_vendor
move_to_partitions

echo -e "\033[32mVendor processing completed for ${DEVICE_NAME} (${DEVICE_CODE})\033[0m"