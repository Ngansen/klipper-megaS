# Klipper — Anycubic Mega S + BTT SKR Mini E3 V3.0 + CR Touch + TFT35-E3 Touch Mode

Complete Klipper configuration for:
- **Printer**: Anycubic Mega S (210×210×205mm)
- **Mainboard**: BTT SKR Mini E3 V3.0 (STM32G0B1)
- **Probe**: CR Touch (on BLTouch header)
- **Display**: BTT TFT35-E3 V3.0 in **Touch Mode** via Pi GPIO
- **Host**: Raspberry Pi Zero 2 W running MainsailOS

---

## Hardware you need

| Item | Purpose |
|---|---|
| Raspberry Pi Zero 2 W | Klipper host |
| MicroSD card (16GB+) | MainsailOS |
| Micro-USB OTG adapter | Pi USB → SKR USB-C |
| USB-A to USB-C cable | SKR → Pi |
| 4× female-to-female jumper wires | TFT35 → Pi GPIO |

---

## Part 1 — Flash MainsailOS

1. Download [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. Device: **Raspberry Pi Zero 2 W**
3. OS: Other specific-purpose OS → 3D Printing → **MainsailOS 64-bit**
4. Click ⚙️ settings:
   - Enter your Wi-Fi SSID + password
   - Enable SSH
   - Username: `pi`, set a password
5. Flash → insert SD into Pi → power on
6. Access at `http://mainsailos.local`

---

## Part 2 — Flash Klipper to the SKR board

SSH into the Pi:
```bash
ssh pi@mainsailos.local
cd ~/klipper
make menuconfig
```

Select:
- Micro-controller: **STM32**
- Processor: **STM32G0B1**
- Bootloader: **8KiB bootloader**
- Communication: **USB (on PA11/PA12)**

```bash
make
```

Copy `~/klipper/out/klipper.bin` to a FAT32 SD card, rename it `firmware.bin`.  
Insert into SKR, power on — it flashes automatically (LED blinks, file renames to `.cur`).

---

## Part 3 — Wire TFT35 to Pi GPIO

Disconnect the TFT's 5-pin cable from the SKR. Wire TFT directly to Pi 40-pin header:

```
TFT35 pin    →    Pi physical pin    Pi function
─────────────────────────────────────────────────
GND          →    Pin 6              Ground
VCC          →    Pin 4              5V power
TX           →    Pin 10             GPIO15 (RX)
RX           →    Pin 8              GPIO14 (TX)
RST          →    not connected
```

> **TX → RX and RX → TX** — they always cross between devices.  
> 3.3V GPIO is safe — no level shifter needed.

---

## Part 4 — Install this repo on the Pi

```bash
cd ~
git clone https://github.com/Ngansen/klipper-megaS.git
cd klipper-megaS
chmod +x install.sh
./install.sh
```

The script:
- Copies `tftbridge.py` to Klipper's extras folder
- Disables Bluetooth to free `/dev/ttyAMA0` for the TFT
- Installs `printer.cfg` to `~/printer_data/config/`
- Restarts Klipper

---

## Part 5 — Set your SKR serial ID

```bash
ls /dev/serial/by-id/
```

Copy the path that appears (looks like `usb-Klipper_stm32g0b1xx_XXXX-if00`).  
Open `printer.cfg` in Mainsail (Machine tab) and replace the placeholder:

```ini
[mcu]
serial: /dev/serial/by-id/usb-Klipper_stm32g0b1xx_XXXX-if00   ← paste here
```

Then: **sudo systemctl restart klipper**

---

## Part 6 — Calibration (in order)

Open Mainsail → Console tab, run these commands in sequence:

### Step 1 — Home and check motor directions
```
G28
```
- X should move **left** to endstop
- Y should move **forward** to endstop
- Z should move **up** (probe triggers at bottom)

If any axis moves the wrong direction, flip the `!` on its `dir_pin` in `printer.cfg`.

### Step 2 — Calibrate Z offset
```
PROBE_CALIBRATE
```
Use paper test to find correct Z offset, then:
```
SAVE_CONFIG
```

### Step 3 — Bed mesh
```
BED_MESH_CALIBRATE
SAVE_CONFIG
```

### Step 4 — PID tune hotend
```
PID_CALIBRATE HEATER=extruder TARGET=200
SAVE_CONFIG
```

### Step 5 — PID tune bed
```
PID_CALIBRATE HEATER=heater_bed TARGET=60
SAVE_CONFIG
```

### Step 6 — Calibrate extruder (e-steps)
1. Heat hotend to 200°C
2. Mark filament 120mm from extruder entrance
3. Extrude 100mm: `G1 E100 F100`
4. Measure remaining distance to mark
5. Calculate: `new_rotation_distance = old × (measured / 100)`
6. Update `rotation_distance` in `[extruder]` section

### Step 7 — Slicer settings
Set start G-code:
```
START_PRINT BED_TEMP=[bed_temperature] EXTRUDER_TEMP=[nozzle_temperature]
```
Set end G-code:
```
END_PRINT
```

---

## Important reminders

- After **any** `printer.cfg` change, restart with:
  ```bash
  sudo systemctl restart klipper
  ```
  The Mainsail web UI restart button does **not** reload tftbridge.

- TFT baud rate must stay at **115200** (matches `P1:6` in TFT config.ini).

- CR Touch `sensor_pin: ^PC14` — the `^` (pull-up) is required. Removing it breaks Z homing.

---

## File reference

| File | Purpose |
|---|---|
| `printer.cfg` | Main Klipper config — copy to `~/printer_data/config/` |
| `tftbridge.py` | Klipper add-on — copy to `~/klipper/klippy/extras/` |
| `install.sh` | Automates both of the above |
| `README.md` | This guide |
