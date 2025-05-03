#!/bin/bash
# Vendor Image for kona 

# Parameters from main script
BASE_DIR="$1"
DEVICE_CODE="$2"

# Paths (inherited from extract_fw.sh or defined here)
WORK_DIR="${WORK_DIR:-${BASE_DIR}/firmware/work_dir}"
PARTITIONS_DIR="${PARTITIONS_DIR:-${WORK_DIR}/partitions}"
VENDOR_DIR="${BASE_DIR}/firmware/vendor/${DEVICE_CODE}"

# Single URL for this specific device
VENDOR_URL="https://get.filesto.space/download/gAAAAABoFhLOfKTd4hVDB_b5fCjdR5hzNQ3LnscQodk1HRcDhynqwi5Z-cLsVn7-jqstJM9We6MB2rPdN2Zz2uwI0l-lyzuQRpUADh7cGoBM_tFsVT2pifk="  # REPLACE WITH x1q vendor.img stock link

# Create directories
mkdir -p "$VENDOR_DIR" "$PARTITIONS_DIR"

# Download only if vendor.img doesn't exist
if [ ! -f "${VENDOR_DIR}/vendor.img" ]; then
  echo "Downloading vendor image for ${DEVICE_CODE}..."
  if ! wget -O "${VENDOR_DIR}/vendor.img" "$VENDOR_URL"; then
    echo "ERROR: Failed to download vendor image!"
    exit 1
  fi
else
  echo "Vendor image already exists. Skipping download."
fi

# Move to partitions directory
echo "Moving vendor image to partitions..."
mv -f "${VENDOR_DIR}/vendor.img" "${PARTITIONS_DIR}/vendor.img"

echo "Vendor process completed for ${DEVICE_CODE}!"
