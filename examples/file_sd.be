import os

var path = "/P2FILE.TXT"

try
    os.remove(path)
except .. as e, m
end

var f = open(path, "w")
f.write("hello from Berry on P2 SD")
f.close()

print("exists:", os.path.exists(path))
print("text:", open(path, "r").read())
print("bytes:", open(path, "r").readbytes().tohex())
print("remove:", os.remove(path))
