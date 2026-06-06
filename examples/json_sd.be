import json
import os

var path = "/berry/config/example.json"
var fallback = "/P2JSON.TXT"
var target = os.path.exists("/berry/config") ? path : fallback
var data = {
    "name": "berry-p2",
    "answer": 42,
    "features": ["sd", "json", "lazy-modules"]
}

var encoded = json.dump(data)
var f = open(target, "w")
f.write(encoded)
f.close()

var decoded = json.load(open(target, "r").read())
print("wrote", target)
print("answer:", decoded["answer"])
print("feature count:", decoded["features"].size())
