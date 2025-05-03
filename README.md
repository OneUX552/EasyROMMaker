# Ishihara0xn-ROM v6.1.1

![IshiharaROM Banner](https://i.imgur.com/placeholder.png)  
*A full Samsung firmware port for Galaxy S20/S20+/Ultra and Note20 series with enhanced features and customization*

## 📌 Key Features
- Based on latest Samsung OneUI firmware
- Full device-specific porting
- Customizable feature flags
- Support for multiple device variants

## ⚠️ Requirements
- **Unlocked Bootloader** (Will trip Knox)
- Snapdragon Variant
- Minimum 50GB free storage
- WSL Required

## 🛠️ Build Instructions

### 1. Initial Setup

git clone https://github.com/ishihara0xn/Ishihara0xn-ROM
cd Ishihara0xn-ROM

### 2. Configuration
Edit conf.txt with your parameters:


# Device Configuration
SOURCE_MODEL=SM-G98xB # Source firmware model
REGION=XXA # Firmware region
IMEI= # Leave blank for auto-selection

# Build Environment
CRB_KITCHEN_PATH=/path/to/your/crb_kitchen
3. Firmware Preparation
bash
bash extract_fw.sh
This will:

Download required firmware

Extract components

Generate kona vendor files

Create input_rom_Kitchen.zip

4. Kitchen Setup
Place input_rom_Kitchen.zip in your CRB kitchen

Start a new project

5. Build Execution
bash
bash devices/x1q.sh # For S20 (x1q) same for other devices....
Follow the on-screen prompts to select your CRB project.

6. Final Packaging
After successful build:

Build system/vendor/product images 

Package into flashable ZIP


📁 Project Structure
Ishihara0xn-ROM/
├── devices/              # Device-specific scripts
│   └── x1q.sh           # S20 build script
├── ishihara/
│   ├── scripts/         # Core modification scripts
│   └── utils/          # Helper utilities
├── input_rom_Kitchen/   # Auto-generated
├── conf.txt             # Main configuration
└── extract_fw.sh        # Firmware processor
Feature Customization
Modify these files for advanced tuning:

Floating Features
Edit device scripts to modify:

bash
declare -A FEATURE_TAGS=(
    ["SEC_FLOATING_FEATURE_LAUNCHER_CONFIG_ANIMATION_TYPE"]="HighEnd"
    ["SEC_FLOATING_FEATURE_LCD_SUPPORT_EXTRA_BRIGHTNESS"]="TRUE"
)
Build Properties
Customize per-partition props:

bash
declare -A SYSTEM_PROPS=(
    ["ro.build.type"]="userdebug"
    ["ro.sf.lcd_density"]="420"
)
📊 Supported Devices
Device 	Status
x1q		Primary
y2q		Experimental
z3q     Experimental
💬 Support
For issues and questions:

Telegram Group

XDA Thread


