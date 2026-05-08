import spin2

# Build with `make spin2`, then transfer the build folder to the SD card with:
#   make spin2-sd-sync TOOLCHAIN=catalina PORT=/dev/cu.usbserial-XXXX
#
# The generated mb_*.bin files are 8.3-friendly, so they appear on the SD card
# as MB_01ALU.BIN, MB_02LOG.BIN, etc.

tests = [
    ["MB_01ALU.BIN", 10, 4, 0],
    ["MB_02LOG.BIN", 0x5A, 0x0F, 0],
    ["MB_03SHF.BIN", 0, 0, 0],
    ["MB_04CMP.BIN", 5, 5, 0],
    ["MB_05BIT.BIN", 0, 0, 0],
    ["MB_06LANE.BIN", 0, 0, 0],
    ["MB_07MUL.BIN", 6, 7, 0],
    ["MB_08DIV.BIN", 100, 9, 0],
    ["MB_09CORD.BIN", 1000, 2000, 0],
    ["MB_10HUB.BIN", 0x12, 0x3456, 0x01020304],
    ["MB_11LUT.BIN", 0x55AA, 0x1234, 0],
    ["MB_12STK.BIN", 99, 0, 0],
    ["MB_13JMP.BIN", 1, 1, 0],
    ["MB_14REP.BIN", 0, 0, 0],
    ["MB_15MISC.BIN", 0, 0, 0],
    ["MB_16TIME.BIN", 0, 0, 0],
    ["MB_17WIDE.BIN", 0, 0, 0],
    ["MB_18PINS.BIN", 0, 0, 0],
    ["MB_19LOCK.BIN", 0, 0, 0],
    ["MB_20PAT.BIN", 0, 0, 0],
]

print(spin2.list())
for test : tests
    file = test[0]
    handle = spin2.start(file)
    value = spin2.call(handle, 1, test[1], test[2], test[3])
    print(file, value)
    spin2.stop(handle)
end
