print("P2_SMOKE_BEGIN sd")

import os

var path = "/P2SMOKE.TXT"

try
    os.remove(path)
except .. as e, m
end

var f = open(path, "w")
assert(f != nil)
f.write("sd smoke ok")
f.close()

assert(os.path.exists(path))
assert(os.path.isfile(path))

var text = open(path, "r").read()
assert(text == "sd smoke ok")

var raw = open(path, "r").readbytes()
assert(raw.tohex() == "736420736d6f6b65206f6b")

assert(os.remove(path))
assert(!os.path.exists(path))
assert(type(os.listdir("/")) == "list")

print("P2_SMOKE_PASS sd")
