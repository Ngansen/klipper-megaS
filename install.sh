#!/bin/bash
# ============================================================
# Klipper setup script — Anycubic Mega S / SKR Mini E3 V3.0
# Run this on the Raspberry Pi after cloning the repo:
#   git clone <repo-url>
#   cd klipper-megaS
#   chmod +x install.sh
#   ./install.sh
# ============================================================

set -e

KLIPPER_EXTRAS=~/klipper/klippy/extras
KLIPPER_CONFIG=~/printer_data/config

echo "============================================================"
echo " Anycubic Mega S Klipper Setup"
echo "============================================================"

# 1. Check Klipper is installed
if [ ! -d "$KLIPPER_EXTRAS" ]; then
    echo "ERROR: Klipper not found at ~/klipper"
    echo "Please install MainsailOS first, then run this script."
    exit 1
fi

# 2. Install tftbridge Klipper add-on
echo "[1/4] Installing tftbridge add-on..."
cp tftbridge.py "$KLIPPER_EXTRAS/tftbridge.py"
echo "      Done — tftbridge.py copied to $KLIPPER_EXTRAS"

# 3. Enable UART on Pi (disable Bluetooth to free /dev/ttyAMA0)
echo "[2/4] Enabling hardware UART for TFT35 connection..."
if ! grep -q "dtoverlay=disable-bt" /boot/config.txt 2>/dev/null && \
   ! grep -q "dtoverlay=disable-bt" /boot/firmware/config.txt 2>/dev/null; then
    BOOT_CFG=""
    if [ -f /boot/firmware/config.txt ]; then
        BOOT_CFG=/boot/firmware/config.txt
    elif [ -f /boot/config.txt ]; then
        BOOT_CFG=/boot/config.txt
    fi
    if [ -n "$BOOT_CFG" ]; then
        echo "dtoverlay=disable-bt" | sudo tee -a "$BOOT_CFG" > /dev/null
        echo "      Bluetooth disabled — /dev/ttyAMA0 is now free for TFT35"
    fi
else
    echo "      Bluetooth already disabled — OK"
fi

# 4. Install printer.cfg
echo "[3/4] Installing printer.cfg..."
mkdir -p "$KLIPPER_CONFIG"
if [ -f "$KLIPPER_CONFIG/printer.cfg" ]; then
    BACKUP="$KLIPPER_CONFIG/printer.cfg.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$KLIPPER_CONFIG/printer.cfg" "$BACKUP"
    echo "      Existing printer.cfg backed up to $BACKUP"
fi
cp printer.cfg "$KLIPPER_CONFIG/printer.cfg"
echo "      Done — printer.cfg installed"

# 5. Restart Klipper
echo "[4/4] Restarting Klipper..."
sudo systemctl restart klipper
sleep 3
if systemctl is-active --quiet klipper; then
    echo "      Klipper restarted successfully"
else
    echo "      WARNING: Klipper may not have started — check: sudo journalctl -u klipper -n 50"
fi

echo ""
echo "============================================================"
echo " Setup complete!"
echo "============================================================"
echo ""
echo "NEXT STEPS:"
echo ""
echo "  1. Find your SKR serial ID:"
echo "     ls /dev/serial/by-id/"
echo ""
echo "  2. Edit printer.cfg and replace the placeholder serial path:"
echo "     nano ~/printer_data/config/printer.cfg"
echo "     Look for: serial: /dev/serial/by-id/usb-Klipper_stm32g0b1xx_XXXX"
echo ""
echo "  3. Restart Klipper after editing:"
echo "     sudo systemctl restart klipper"
echo ""
echo "  4. Open Mainsail in your browser: http://mainsailos.local"
echo ""
echo "  5. Calibration order (in Mainsail console):"
echo "     G28                                    — home all axes"
echo "     PROBE_CALIBRATE                        — set Z offset"
echo "     SAVE_CONFIG"
echo "     BED_MESH_CALIBRATE                     — auto bed leveling"
echo "     SAVE_CONFIG"
echo "     PID_CALIBRATE HEATER=extruder TARGET=200"
echo "     SAVE_CONFIG"
echo "     PID_CALIBRATE HEATER=heater_bed TARGET=60"
echo "     SAVE_CONFIG"
echo ""
echo "  See README.md for full calibration guide."
echo ""
