print("P2_SMOKE_BEGIN time")

import time

assert(type(time) == "module")
assert(type(time.clock) == "function")
assert(type(time.dump) == "function")
assert(type(time.time) == "function")

def has_time_fields(d)
    return d.contains("year") &&
           d.contains("month") &&
           d.contains("day") &&
           d.contains("hour") &&
           d.contains("min") &&
           d.contains("sec") &&
           d.contains("weekday") &&
           d.contains("epoch")
end

def has_integer_time_fields(d)
    return type(d["year"]) == "int" &&
           type(d["month"]) == "int" &&
           type(d["day"]) == "int" &&
           type(d["hour"]) == "int" &&
           type(d["min"]) == "int" &&
           type(d["sec"]) == "int" &&
           type(d["weekday"]) == "int" &&
           type(d["epoch"]) == "int"
end

var clock0 = time.clock()
assert(type(clock0) == "real")
assert(clock0 >= 0)

var spin = 0
for i: 0..100
    spin += i
end
assert(spin == 5050)
var clock1 = time.clock()
assert(type(clock1) == "real")
assert(clock1 >= clock0)

var d2021 = time.dump(1609459200)
assert(isinstance(d2021, map))
assert(has_time_fields(d2021))
assert(has_integer_time_fields(d2021))
assert(d2021["year"] == 2021)
assert(d2021["month"] == 1)
assert(d2021["epoch"] == 1609459200)
assert(d2021["weekday"] >= 0 && d2021["weekday"] <= 6)
assert(d2021["hour"] >= 0 && d2021["hour"] <= 23)
assert(d2021["min"] >= 0 && d2021["min"] <= 59)
assert(d2021["sec"] >= 0 && d2021["sec"] <= 60)
d2021["year"] = 9999
assert(time.dump(1609459200)["year"] == 2021)

var d2000 = time.dump(946684800)
assert(isinstance(d2000, map))
assert(has_time_fields(d2000))
assert(has_integer_time_fields(d2000))
assert(d2000["year"] == 2000)
assert(d2000["epoch"] == 946684800)

var leap2000 = time.dump(951782400)
assert(isinstance(leap2000, map))
assert(has_time_fields(leap2000))
assert(has_integer_time_fields(leap2000))
assert(leap2000["year"] == 2000)
assert(leap2000["month"] == 2)
assert(leap2000["day"] == 29)
assert(leap2000["epoch"] == 951782400)

var d0 = time.dump(0)
assert(isinstance(d0, map))
assert(has_time_fields(d0))
assert(has_integer_time_fields(d0))
assert(d0["epoch"] == 0)

assert(time.dump() == nil)
assert(time.dump(nil) == nil)
assert(time.dump("hello") == nil)
assert(time.dump(3.14) == nil)
assert(time.dump(true) == nil)
assert(time.dump(false) == nil)
assert(time.dump([]) == nil)
assert(time.dump({}) == nil)
assert(time.dump([0]) == nil)
assert(time.dump({"epoch": 0}) == nil)

var now = time.time()
assert(type(now) == "int")
var now_dump = time.dump(now)
assert(isinstance(now_dump, map))
assert(now_dump["epoch"] == now)
assert(has_time_fields(now_dump))
assert(has_integer_time_fields(now_dump))

print("P2_SMOKE_PASS time")
