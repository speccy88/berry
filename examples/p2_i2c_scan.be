import i2c

# BMP180 on this port is currently wired SDA=24, SCL=25.
i2c.init(25, 24, 400)
print(i2c.scan())
