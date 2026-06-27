import json

var decoded = json.load('{"key": "value"}')
var dumped_nil = json.dump({'test key': nil})
var dumped_format = json.dump({'key1': nil, 45: true}, 'format')

print("json key:", decoded["key"])
print("json nil dump:", dumped_nil)
print("json formatted size:", size(dumped_format))
print("json core demo done")
