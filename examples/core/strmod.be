import string

print("int padded:", string.format('%.3d', 12))
print("float fixed:", string.format('%.3f', 12))
print("float width:", string.format('%20.7f', 14.5))
print("left text:", string.format('-- %-40s ---', 'this is a string format test'))
print("right text:", string.format('-- %40s ---', 'this is a string format test'))
print("string format demo done")
