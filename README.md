# Ishihara0xn-ROM
IshiharaROM 6.1.1 Full Samsung Firmware Port for Galaxy S20 and S20+ 
> **Note:** Unlocking Bootloader is required and Samsung knox will be tripped.


🛠 How to Build
📥 Download & Extract Firmware
bash
# Edit conf.txt to set Firmware Model, Region, and IMEI
nano conf.txt
bash
# Run the extraction script
bash extract_fw.sh
Downloads, extracts, and replaces the vendor with the target device.

Output: A .zip file is created inside input_rom_Kitchen/.

🛠 Prepare ROM in CRB Kitchen
bash
# Move the generated ROM to CRB Kitchen
mv input_rom_Kitchen/*.zip /path/to/crb_kitchen/
bash
# Configure the kitchen path in conf.sh
nano conf.sh
🔨 Build the ROM
bash
# Run the device-specific build script
bash device_<codename>.sh
bash
# Select the appropriate project in CRB Kitchen
# Follow the on-screen prompts
bash
# Generate the final flashable ROM package
zip -r IshiharaROM_v6.1.1.zip output/
