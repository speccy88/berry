# P2_SD_WRITE_AUDIT max_write_opens=5
print("P2_SMOKE_BEGIN sd_file_core_min")

import os
import p2

var fs = p2.fs_info("/")
assert(fs["mount_result_name"] == "ok")
assert(fs["partition_start"] == 2048)
if fs.contains("sd_response")
    assert(fs["sd_response"] == 0)
end
print("P2_SD_CORE_MIN fs")

var path = "/P2SDMIN.TXT"
assert(!os.path.exists(path))

var f = open(path, "w")
assert(f != nil)
f.write("abc")
f.flush()
assert(f.tell() == 3)
assert(f.size() == 3)
f.close()

assert(os.path.exists(path))
assert(os.path.isfile(path))
assert(os.path.basename(path) == "P2SDMIN.TXT")
assert(os.path.dirname(path) == "/")
assert(os.path.join("/", "P2SDMIN.TXT") == path)
assert(os.path.split(path) == ["/", "P2SDMIN.TXT"])
assert(os.path.splitext(path) == ["/P2SDMIN", ".TXT"])

var a = open(path, "a")
assert(a != nil)
a.write("!")
a.close()

var r = open(path, "r")
assert(r != nil)
assert(r.read() == "abc!")
r.close()

var rw = open(path, "r+")
assert(rw != nil)
rw.seek(1)
assert(rw.tell() == 1)
rw.write("Z")
rw.seek(0)
assert(rw.read() == "aZc!")
rw.close()
print("P2_SD_CORE_MIN file")

var dir = "/P2SDMIN"
assert(!os.path.exists(dir))
assert(os.mkdir(dir))
assert(os.path.isdir(dir))
assert(!os.path.isfile(dir))
assert(os.chdir(dir))
assert(os.getcwd() == dir)

var inner = open("INNER.TXT", "w")
assert(inner != nil)
inner.write("ok")
inner.close()
assert(os.path.exists("INNER.TXT"))
assert(os.path.isfile("INNER.TXT"))
assert(isinstance(os.listdir("."), list))
assert(os.remove("INNER.TXT"))
assert(!os.path.exists("INNER.TXT"))
assert(os.chdir("/"))
assert(os.remove(dir))
assert(!os.path.exists(dir))
print("P2_SD_CORE_MIN dir")

var renamed = "/P2SDMN2.TXT"
assert(!os.path.exists(renamed))
assert(os.rename(path, renamed))
assert(!os.path.exists(path))
assert(os.path.exists(renamed))
assert(os.remove(renamed))
assert(!os.path.exists(renamed))
assert(!os.path.exists("/P2SDNOPE.TXT"))
assert(!os.path.isfile("/P2SDNOPE.TXT"))
assert(!os.path.isdir("/P2SDNOPE.TXT"))
print("P2_SMOKE_PASS sd_file_core_min")
