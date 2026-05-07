import i2c

# BMP180 on the current test board is wired SDA=24, SCL=25.
i2c.init(25, 24, 400)
print(i2c.scan())

if i2c.present(0x77)
    # BMP180 chip-id register. Expected raw byte is 0x55, printed as "U".
    print(i2c.writeread(0x77, "\xD0", 1))
end
