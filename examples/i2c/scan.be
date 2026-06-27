import i2c

var scl = 25
var sda = 24
var khz = 400
var bmp180 = 0x77

print("i2c scan pins:", "scl", scl, "sda", sda, "khz", khz)
i2c.init(scl, sda, khz)

var found = i2c.scan()
var present = i2c.present(bmp180)

print("i2c scan count:", found.size())
print("bmp180 present:", present)

if present
    # BMP180 chip-id register. Expected raw byte is 0x55, printed as "U".
    var chip = i2c.writeread(bmp180, "\xD0", 1)
    print("bmp180 chip id:", chip)
    print("bmp180 chip id ok:", chip == "U")
end

i2c.stop()
print("i2c scan done")
