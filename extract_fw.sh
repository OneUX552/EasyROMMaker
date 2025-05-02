#!/bin/bash
set -e

# Get base directory from first argument
BASE_DIR="$1"

# Define paths relative to base directory
WORK_DIR="${BASE_DIR}/firmware/work_dir"
PARTITIONS_DIR="${WORK_DIR}/partitions"
FIRMWARE_DIR="${BASE_DIR}/firmware"

# Ensure necessary folders exist
mkdir -p "$PARTITIONS_DIR"

echo "Working directory: $WORK_DIR"

check_required_images() {
    if [ -f "$PARTITIONS_DIR/system.img" ] && 
       [ -f "$PARTITIONS_DIR/odm.img" ] && 
       [ -f "$PARTITIONS_DIR/product.img" ]; then
        return 0
    else
        return 1
    fi
}

extract_ap_file() {
    echo "- Searching for AP image in ${FIRMWARE_DIR}..."
    AP_FILE=$(find "${FIRMWARE_DIR}" -type f \( -iname "AP*.tar.md5" -o -iname "AP*.tar" -o -iname "AP*.zip" -o -iname "AP*.7z" \) | head -n 1)

    if [ -z "$AP_FILE" ]; then
        echo "ERROR: No AP file found in ${FIRMWARE_DIR}"
        exit 1
    fi

    echo "Extracting AP file: $AP_FILE..."
    mkdir -p "$WORK_DIR"
    
    if [[ "$AP_FILE" == *.tar.md5 || "$AP_FILE" == *.tar ]]; then
        tar -xf "$AP_FILE" -C "$WORK_DIR"
    elif [[ "$AP_FILE" == *.zip ]]; then
        unzip -q "$AP_FILE" -d "$WORK_DIR"
    else
        echo "ERROR: Unsupported file format: $AP_FILE"
        exit 1
    fi
}

process_super_image() {
    echo "- Processing super.img.lz4..."
    SUPER_IMG_LZ4=$(find "$WORK_DIR" -type f -name "super.img.lz4" | head -n 1)
    
    if [ -z "$SUPER_IMG_LZ4" ]; then
        echo "ERROR: super.img.lz4 not found in extracted files."
        exit 1
    fi

    echo "Decompressing super.img.lz4..."
    lz4 -d "$SUPER_IMG_LZ4" "$WORK_DIR/super.img"

    echo "Converting super.img (sparse) to raw image..."
    simg2img "$WORK_DIR/super.img" "$WORK_DIR/super_raw.img"
    
    if [ $? -eq 0 ]; then
        echo "Conversion successful. Deleting super.img..."
        rm -f "$WORK_DIR/super.img"
    else
        echo "Error converting super.img to raw image. Exiting..."
        exit 1
    fi

    echo "Unpacking super_raw.img into partitions..."
    rm -rf "$PARTITIONS_DIR"
    mkdir -p "$PARTITIONS_DIR"
    
    lpunpack --slot=0 "$WORK_DIR/super_raw.img" "$PARTITIONS_DIR"
    
    if [ $? -eq 0 ]; then
        echo "Unpacking successful. Cleaning up..."
        rm -f "$PARTITIONS_DIR/vendor.img"
        rm -f "$WORK_DIR/super_raw.img"
        rm -f "$SUPER_IMG_LZ4"
    else
        echo "Error unpacking super_raw.img. Exiting..."
        exit 1
    fi
}

# Main execution flow
if check_required_images; then
    echo "[+] Required images found in $PARTITIONS_DIR. Skipping extraction steps."
else
    echo "[-] Required images missing. Running extraction..."
    extract_ap_file
    process_super_image
fi

echo "All partitions processed. Check $EXTRACTED_DIR for results."