#!/bin/bash
# apksign_helper.sh - APK Signing Utility

# Configuration
SIGNER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../external/apksigner" && pwd)"
APKSIGNER_JAR="$SIGNER_DIR/apksigner.jar"
KEY_PK8="$SIGNER_DIR/testkey.pk8"
KEY_X509="$SIGNER_DIR/testkey.x509.pem"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_signing_deps() {
    local missing=0
    
    [ -f "$APKSIGNER_JAR" ] || {
        echo -e "${RED}ERROR: apksigner.jar missing${NC}"
        missing=1
    }
    
    [ -f "$KEY_PK8" ] || {
        echo -e "${RED}ERROR: testkey.pk8 missing${NC}"
        missing=1
    }
    
    [ -f "$KEY_X509" ] || {
        echo -e "${RED}ERROR: testkey.x509.pem missing${NC}"
        missing=1
    }
    
    command -v java >/dev/null 2>&1 || {
        echo -e "${RED}ERROR: Java runtime missing${NC}"
        missing=1
    }
    
    [ $missing -eq 1 ] && return 1
    return 0
}

sign_apk() {
    local input_apk="$1"
    local output_apk="$2"
    
    echo -e "${YELLOW}[*] Signing ${input_apk##*/}${NC}"
    
    java -jar "$APKSIGNER_JAR" sign \
        --key "$KEY_PK8" \
        --cert "$KEY_X509" \
        --out "$output_apk" \
        "$input_apk"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Successfully signed: ${output_apk##*/}${NC}"
    else
        echo -e "${RED}[✗] Failed to sign ${input_apk##*/}${NC}"
        return 1
    fi
}

batch_sign_apks() {
    local apk_list=("$@")
    local output_dir="$ROM_FOLDER/signed_apks"
    
    mkdir -p "$output_dir"
    
    for apk_path in "${apk_list[@]}"; do
        local apk_name=$(basename "$apk_path")
        local relative_path="${apk_path#$ROM_FOLDER}"
        local output_path="$output_dir/$relative_path"
        
        mkdir -p "$(dirname "$output_path")"
        
        sign_apk "$apk_path" "$output_path" || return 1
    done
}