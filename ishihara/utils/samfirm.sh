#!/bin/bash

# Automatically set the project root directory to two levels up from where the script is
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Path to the samfirm.js script
SAMFIRM_SCRIPT="$PROJECT_ROOT/external/samfirm/samfirm.js"

# Path to the configuration file
CONFIG_FILE="$PROJECT_ROOT/conf.txt"

# Directory to save downloaded firmware (single `firmware` folder)
DOWNLOAD_DIR="$PROJECT_ROOT/firmware"

# Create the firmware directory if it doesn’t exist
mkdir -p "$DOWNLOAD_DIR"

# Check if Node.js is installed
if ! command -v node &>/dev/null; then
    echo "Node.js is not installed. Please install Node.js to proceed."
    exit 1
fi

# Check if the samfirm.js script exists
if [ ! -f "$SAMFIRM_SCRIPT" ]; then
    echo "samfirm.js script not found at $SAMFIRM_SCRIPT."
    exit 1
fi

# Check if the configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found at $CONFIG_FILE."
    exit 1
fi

# Fetch values for MODEL, REGION, and IMEI from the configuration file
MODEL=$(grep "^MODEL=" "$CONFIG_FILE" | cut -d '=' -f2 | tr -d '\"')
REGION=$(grep "^REGION=" "$CONFIG_FILE" | cut -d '=' -f2 | tr -d '\"')
IMEI=$(grep "^IMEI=" "$CONFIG_FILE" | cut -d '=' -f2 | tr -d '\"')

# Validate that MODEL, REGION, and IMEI are not empty
if [ -z "$MODEL" ] || [ -z "$REGION" ] || [ -z "$IMEI" ]; then
    echo "MODEL, REGION, or IMEI is missing or invalid in the configuration file."
    exit 1
fi

# Temporarily change to the firmware directory
echo "Switching to firmware directory: $DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR" || { echo "ERROR: Unable to switch to firmware directory $DOWNLOAD_DIR"; exit 1; }

# Run the samfirm.js script with the provided model, region, and IMEI
echo "Starting firmware download for $MODEL ($REGION)..."
node "$SAMFIRM_SCRIPT" -m "$MODEL" -r "$REGION" -i "$IMEI"

# Check if the script executed successfully
if [ $? -eq 0 ]; then
    echo "Firmware downloaded successfully to $DOWNLOAD_DIR."
else
    echo "Firmware download failed. Please check for errors."
    exit 1
fi
