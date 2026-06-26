import json
import os

var target = "/P2JSON.TXT"
var data = {
    "name": "berry-p2",
    "answer": 42,
    "features": ["sd", "json", "lazy-modules"]
}

if os.path.exists(target)
    raise "io_error", target + " already exists"
end

var encoded = json.dump(data)
var f = open(target, "w")
f.write(encoded)
f.close()

var decoded = json.load(open(target, "r").read())
print("wrote", target)
print("answer:", decoded["answer"])
print("feature count:", decoded["features"].size())
print("remove:", os.remove(target))
print("json sd example done")
