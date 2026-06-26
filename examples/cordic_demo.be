import p2

print("CORDIC demos")
var xypol = p2.cordic.xypol(3, 4)
var polxy = p2.cordic.polxy(1, 0)
var rotxy = p2.cordic.rotxy(1, 0, 0)
print("xypol r/t:", xypol["r"], xypol["t"])
print("polxy x/y:", polxy["x"], polxy["y"])
print("rotxy x/y:", rotxy["x"], rotxy["y"])
print("isqrt(81):", p2.math.isqrt(81))
print("muldiv64(6,7,3):", p2.math.muldiv64(6, 7, 3))
print("cordic demo done")
