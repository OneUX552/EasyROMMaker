#!/bin/bash
# Vendor Image Handler for kona

# Parameters from main script
BASE_DIR="$1"
DEVICE_CODE="$2"

# Paths (inherited from extract_fw.sh or defined here)
WORK_DIR="${WORK_DIR:-${BASE_DIR}/firmware/work_dir}"
PARTITIONS_DIR="${PARTITIONS_DIR:-${WORK_DIR}/partitions}"
VENDOR_DIR="${BASE_DIR}/firmware/vendor/${DEVICE_CODE}"

# Single URL for this specific device
VENDOR_URL="https://get.filesto.space/download/gAAAAABoFcGNSathTbO9Pvyyn0TxpksmtVmVwqUi6C0noE61HDTberIzwVIVvP8oDe3i790jgWZ8oplg9LG0w_FUqO3R4gk23Nwx57qFSk--gjWCnR9sMiY="  # REPLACE WITH y2q vendor.img stock

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
