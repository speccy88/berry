import os

var path = "/P2FEXMP.TXT"

if os.path.exists(path)
    raise "io_error", path + " already exists"
end

var f = open(path, "w")
f.write("hello from Berry on P2 SD")
f.close()

print("exists:", os.path.exists(path))
print("text:", open(path, "r").read())
print("bytes:", open(path, "r").readbytes().tohex())
print("remove:", os.remove(path))
print("file sd example done")
