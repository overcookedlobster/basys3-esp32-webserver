# Basys3 ESP32 Web Server Project

## Overview
This project implements a web server using a Pmod ESP32 connected to a Basys3 FPGA board. The web server displays the real-time status of buttons on the FPGA via a web page accessible on your local Wi-Fi network.

## Features
- **Wi-Fi Connection**: The ESP32 connects to the "home" Wi-Fi network with password "password".
- **Web Server**: Hosts a web server on port 8000 displaying button.
- **FPGA Inputs**: Monitors 5 buttons on the Basys3 board.
- **Real-time Updates**: The web page auto-refreshes to show current states.

## Project Structure
- **src/**: FPGA source files and constraints.
  - `fpga_top.sv`: Top-level FPGA module.
  - `uart_tx.sv`: UART transmitter module.
  - `button_debounce.sv`: Button debouncing module.
  - `input_handler.sv`: Input handling module.
  - `constraints.xdc`: Pin mapping for Basys3.
- **sim/**: Simulation files.
  - `fpga_tb.sv`: Testbench for FPGA design.
- **arduino/**: ESP32 Arduino code.
  - `esp32_webserver.ino`: Web server implementation.
- **tcl/**: Vivado TCL scripts.
  - Various scripts for project creation, synthesis, and programming.

## Hardware Requirements
- Basys3 FPGA board
- Pmod ESP32 module
- USB cable for FPGA programming
- Generic USB-to-UART adapter for ESP32 programming
- Access to "home" Wi-Fi network

## Setup Instructions

### Installing Arduino CLI

1. Install Arduino CLI:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
   ```

2. Add Arduino CLI to your PATH:
   ```bash
   export PATH=$PATH:~/bin
   ```

3. Configure ESP32 support:
   ```bash
   arduino-cli config init
   arduino-cli config add board_manager.additional_urls https://dl.espressif.com/dl/package_esp32_index.json
   arduino-cli core update-index
   arduino-cli core install esp32:esp32
   ```

### ESP32 Programming with USB-UART Adapter

1. Connect the USB-UART adapter to the ESP32:
   - Connect the **USB-UART TX** pin to **RX** (pin 3) on the ESP32 J2 header
   - Connect the **USB-UART RX** pin to **TX** (pin 2) on the ESP32 J2 header
   - Connect **GND** on the USB-UART adapter to **GND** on the ESP32
   - Connect **3.3V** on the USB-UART adapter to **3.3V** on the ESP32 (if needed)

2. Setup PmodESP32 for programming:
   - Set **SW1.2 (BOOT)** switch to **ON** position (programming mode)
   - Press the **Reset button** on the PmodESP32

3. Create a proper Arduino project structure:
   ```bash
   mkdir -p ~/basys3-esp32-webserver/arduino/esp32_webserver
   cp ~/basys3-esp32-webserver/arduino/esp32_webserver.ino ~/basys3-esp32-webserver/arduino/esp32_webserver/
   ```

4. Identify your USB-UART device port:
   ```bash
   arduino-cli board list
   ```
   Note the port (like `/dev/ttyUSB0` on Linux, or `COM3` on Windows)

5. Compile and upload the ESP32 code:
   ```bash
   cd ~/basys3-esp32-webserver/arduino/esp32_webserver
   arduino-cli compile --fqbn esp32:esp32:esp32 .
   arduino-cli upload -p [YOUR_PORT] --fqbn esp32:esp32:esp32 .
   arduino-cli upload -p /dev/ttyUSB0 --fqbn esp32:esp32:esp32 .
   ```
   Replace `[YOUR_PORT]` with your actual port (e.g., `/dev/ttyUSB0`)

6. After programming:
   - Set **SW1.2 (BOOT)** switch to **OFF** position (normal operation mode)
   - Press the **Reset button** again to boot into the application
   - Set **SW1.1 (SPI)** switch to **OFF** position to enable UART communication with FPGA

### FPGA Programming

1. Connect the Basys3 board to your computer via USB.
2. Connect the Pmod ESP32 to the JA Pmod connector on the Basys3 with the proper jumper wires:
   - ESP32 RX (GPIO16) → JA1 (FPGA UART TX)
   - ESP32 GND → Pmod GND
   - ESP32 3.3V → Pmod VCC

### Testing the Web Server

1. Monitor the ESP32 serial output to find its IP address:
   ```bash
   arduino-cli monitor -p [YOUR_PORT] -c baudrate=115200
   ```

2. On a device connected to the "home" network, open a web browser.
3. Navigate to `http://<ESP32_IP>:8000`.
4. The web page should display the current state of the FPGA buttons.
5. Press buttons on the Basys3 to see the web page update in real-time.

## Communication Protocol
The FPGA sends a 1-byte packet to the ESP32 via UART (115200 baud):
- Byte Button states (5 bits used)

## Troubleshooting

### ESP32 Programming Issues
- If `arduino-cli board list` doesn't show your USB-UART adapter, check if it's properly connected and if drivers are installed.
- Make sure SW1.2 is in the ON position during programming.
- Try pressing the Reset button right before starting the upload.

### FPGA-ESP32 Communication Issues
- Ensure SW1.1 on the ESP32 is in the OFF position for UART mode.
- Verify the connections between the FPGA JA1 pin and ESP32 RX pin are secure.
- Make sure both devices share a common ground.
- Check that the baud rate is set correctly on both devices (115200).

### Reminder for Pmod ESP32 Configuration
- For UART communication with FPGA: SW1.1 (SPI) = OFF, SW1.2 (BOOT) = OFF
- For programming mode: SW1.1 (SPI) = any, SW1.2 (BOOT) = ON

-e arduino/esp32_webserver/build/ logs/ vivado_project/ esp32_webserver.ino esp32_webserver_example.ino .Xil/
