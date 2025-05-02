#!/bin/bash
# Nuke Bloat Script - Safely removes unwanted system apps/files

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if ROM_FOLDER is set
if [ -z "$ROM_FOLDER" ]; then
  echo -e "${RED}Error: ROM_FOLDER environment variable not set!${NC}"
  echo "Either export ROM_FOLDER or run via main script"
  exit 1
fi

# Verify ROM directory structure
if [ ! -d "$ROM_FOLDER/system" ]; then
  echo -e "${RED}Error: Invalid ROM folder structure!${NC}"
  echo "Expected to find: $ROM_FOLDER/system"
  exit 1
fi

echo -e "${GREEN}[+] Starting bloat removal in $ROM_FOLDER...${NC}"

# ================================================
# BLOAT PACKAGES TO REMOVE
# ================================================
# Add your packages here following this format:
# "system/path/to/package"
# "product/path/to/app"
# etc...

declare -a BLOAT_LIST=(
"system/system/app/AutomationTest_FB"
  "system/system/app/DRParser"
  "system/system/app/DictDiotekForSec"
  "system/system/app/FactoryAirCommandManager"
  "system/system/app/FactoryCameraFB"
  "system/system/app/FBAppManager_NS"
  "system/system/app/HMT"
  "system/system/app/MoccaMobile"
  "system/system/app/PlayAutoInstallConfig"
  "system/system/app/SamsungCalendar"
  "system/system/app/SamsungPassAutofill_v1"
  "system/system/app/SamsungTTSVoice_de_DE_f00"
  "system/system/app/SamsungTTSVoice_en_GB_f00"
  "system/system/app/SamsungTTSVoice_en_US_l03"
  "system/system/app/SamsungTTSVoice_es_ES_f00"
  "system/system/app/SamsungTTSVoice_es_MX_f00"
  "system/system/app/SamsungTTSVoice_es_US_f00"
  "system/system/app/SamsungTTSVoice_fr_FR_f00"
  "system/system/app/SamsungTTSVoice_hi_IN_f00"
  "system/system/app/SamsungTTSVoice_it_IT_f00"
  "system/system/app/SamsungTTSVoice_pl_PL_f00"
  "system/system/app/SamsungTTSVoice_pt_BR_f00"
  "system/system/app/SamsungTTSVoice_ru_RU_f00"
  "system/system/app/SamsungTTSVoice_th_TH_f00"
  "system/system/app/SamsungTTSVoice_vi_VN_f00"
  "system/system/app/SilentLog"
  "system/system/app/WebManual"
  "system/system/app/WlanTest"
  "system/system/etc/init/digitalkey_init_nfc_tss2.rc"
  "system/system/etc/init/samsung_pass_authenticator_service.rc"
  "system/system/etc/permissions/privapp-permissions-com.microsoft.skydrive.xml"
  "system/system/etc/permissions/privapp-permissions-com.samsung.android.app.kfa.xml"
  "system/system/etc/permissions/privapp-permissions-com.samsung.android.authfw.xml"
  "system/system/etc/permissions/privapp-permissions-com.samsung.android.carkey.xml"
  "system/system/etc/permissions/privapp-permissions-com.samsung.android.cidmanager.xml"
  "system/system/etc/permissions/privapp-permissions-com.samsung.android.dkey.xml"
  "system/system/etc/permissions/privapp-permissions-com.samsung.android.providers.factory.xml"
  "system/system/etc/permissions/privapp-permissions-com.samsung.android.samsungpass.xml"
  "system/system/etc/permissions/privapp-permissions-com.samsung.android.spayfw.xml"
  "system/system/etc/permissions/privapp-permissions-com.sec.android.app.factorykeystring.xml"
  "system/system/etc/permissions/privapp-permissions-com.sec.android.soagent.xml"
  "system/system/etc/permissions/privapp-permissions-com.sec.bcservice.xml"
  "system/system/etc/permissions/privapp-permissions-com.sec.epdgtestapp.xml"
  "system/system/etc/permissions/privapp-permissions-com.sec.facatfunction.xml"
  "system/system/etc/permissions/privapp-permissions-com.sem.factoryapp.xml"
  "system/system/etc/permissions/privapp-permissions-com.wssyncmldm.xml"
  "system/system/etc/permissions/privapp-permissions-de.axelspringer.yana.zeropage.xml"
  "system/system/etc/permissions/privapp-permissions-meta.xml"
  "system/system/etc/sysconfig/digitalkey.xml"
  "system/system/etc/sysconfig/meta-hiddenapi-package-allowlist.xml"
  "system/system/etc/sysconfig/preinstalled-packages-com.samsung.android.dkey.xml"
  "system/system/etc/sysconfig/preinstalled-packages-com.samsung.android.spayfw.xml"
  "system/system/etc/sysconfig/samsungauthframework.xml"
  "system/system/etc/sysconfig/samsungpassapp.xml"
  "system/system/hidden/SmartTutor"
  "system/system/lib64/librildump_jni.so"
  "system/system/preload"
  "system/system/priv-app/AuthFramework"
  "system/system/priv-app/BCService"
  "system/system/priv-app/CIDManager"
  "system/system/priv-app/DeviceKeystring"
  "system/system/priv-app/DiagMonAgent91"
  "system/system/priv-app/DigitalKey"
  "system/system/priv-app/FBInstaller_NS"
  "system/system/priv-app/FBServices"
  "system/system/priv-app/FacAtFunction"
  "system/system/priv-app/FactoryTestProvider"
  "system/system/priv-app/FotaAgent"
  "system/system/priv-app/ModemServiceMode"
  "system/system/priv-app/OneDrive_Samsung_v3"
  "system/system/priv-app/PaymentFramework"
  "system/system/priv-app/SEMFactoryApp"
  "system/system/priv-app/SOAgent7"
  "system/system/priv-app/SamsungCarKeyFw"
  "system/system/priv-app/SamsungPass"
  "system/system/priv-app/SmartEpdgTestApp"
  "system/system/priv-app/Upday"
  "system/system/priv-app/GameDriver-SM8350"
  "system/system/priv-app/KnoxGuard"
  "system/system/priv-app/Scone"
  "system/system/priv-app/wssyncmldm"
  "system/system/priv-app/VzCloud"
  "system/system/priv-app/Ts43AuthService"
  "system/system/priv-app/UsByod"
  "system/system/app/Notes40"
    "system/system/app/SBrowser"
	"system/system/priv-app/AirCommand"
	"system/system/app/SamsungTTSVoice_es_US_l01"
	"system/system/app/BlockchainBasicKit"
 "system/system/priv-app/SmartEye"
 "system/system/priv-app/UnifiedTetheringProvision"
 "system/system/priv-app/UnifiedVVM"
 "system/system/priv-app/PhotoEditor_Full"
 "system/system/priv-app/AirReadingGlass'

  "product/app/AssistantShell"
  "product/app/Chrome"
  "product/app/DuoStub"
  "product/app/Gmail2"
  "product/app/Maps"
  "product/app/YouTube"
  "product/overlay/GmsConfigOverlaySearchSelector.apk"
  "product/priv-app/Messages"
  "product/priv-app/SearchSelector"
)

# ================================================
# ENHANCED REMOVAL PROCESS
# ================================================
TOTAL_REMOVED=0
TOTAL_SKIPPED=0
FAILED_REMOVALS=0

remove_bloat() {
  local package="$1"
  local target="$ROM_FOLDER/$package"
  
  # Check if target exists (file or directory)
  if [ -e "$target" ] || [ -L "$target" ]; then
    echo -n "Processing: $package... "
    
    # Try removal (with sudo if needed)
    if rm -rf "$target" 2>/dev/null || sudo rm -rf "$target" 2>/dev/null; then
      echo -e "${GREEN}Removed${NC}"
      ((TOTAL_REMOVED++))
      
      # Remove empty parent directories (up to 3 levels up)
      local parent
      for i in {1..3}; do
        parent=$(dirname "$target")
        if [ "$parent" != "$ROM_FOLDER" ]; then
          find "$parent" -type d -empty -delete 2>/dev/null
        fi
      done
    else
      echo -e "${RED}Failed${NC}"
      ((FAILED_REMOVALS++))
    fi
  else
    ((TOTAL_SKIPPED++))
  fi
}

echo -e "${YELLOW}[*] Scanning for bloatware...${NC}"

# Process all packages
for package in "${BLOAT_LIST[@]}"; do
  remove_bloat "$package"
done

# ================================================
# POST-REMOVAL CLEANUP
# ================================================
cleanup_empty_dirs() {
  echo -e "\n${YELLOW}[*] Cleaning empty directories...${NC}"
  find "$ROM_FOLDER/system/system/" -type d -empty -delete 2>/dev/null
  find "$ROM_FOLDER/product/" -type d -empty -delete 2>/dev/null
  find "$ROM_FOLDER/vendor" -type d -empty -delete 2>/dev/null
}

####cleanup_empty_dirs###

# ================================================
# VERIFICATION REPORT
# ================================================
echo -e "\n${GREEN}[+] Removal Summary:${NC}"
echo -e "Successfully removed: ${GREEN}$TOTAL_REMOVED${NC} packages"
echo -e "Not found (skipped): ${YELLOW}$TOTAL_SKIPPED${NC} packages"
echo -e "Failed to remove:    ${RED}$FAILED_REMOVALS${NC} packages"

if [ "$FAILED_REMOVALS" -gt 0 ]; then
  echo -e "\n${YELLOW}Warning: Some packages failed to remove. Try running as root.${NC}"
fi

echo -e "\n${GREEN}[✓] Bloat removal completed in $ROM_FOLDER${NC}"
exit 0
