import wifi

# Pins are Propeller 2 pins. These match the P2-to-ESP32-C6 wiring table:
# P16 SCK, P17 MOSI, P18 MISO, P19 CS, P20 BUSY, P21 RESET, P22 IRQ.
wifi.init({
    "sck": 16,
    "mosi": 17,
    "miso": 18,
    "cs": 19,
    "busy": 20,
    "reset": 21,
    "irq": 22
})

print(wifi.firmware_version())
print(wifi.status())
