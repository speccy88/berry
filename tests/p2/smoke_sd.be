# P2_SD_WRITE_AUDIT max_write_opens=8
print("P2_SMOKE_BEGIN sd")

import os
import p2

var fs = p2.fs_info("/")
assert(fs["mount_result_name"] == "ok")
assert(fs["partition_start"] == 2048)
assert(fs["volinfo_result_name"] == "ok")
if fs.contains("sd_response")
    assert(fs["sd_response"] == 0)
end
if fs.contains("filesystem_type")
    assert(fs["filesystem_type"] == 2)
end
print("P2_SMOKE_STAGE sd fs_info")

var path = "/P2SMOKE.TXT"

assert(!os.path.exists(path))
print("P2_SMOKE_STAGE sd preflight")

var f = open(path, "w")
assert(f != nil)
f.write("sd smoke ok")
f.flush()
assert(f.tell() == 11)
assert(f.size() == 11)
f.close()

assert(os.path.exists(path))
assert(os.path.isfile(path))
assert(os.path.basename(path) == "P2SMOKE.TXT")
assert(os.path.dirname(path) == "/")
assert(os.path.basename("/P2DIR/INNER.TXT") == "INNER.TXT")
assert(os.path.dirname("/P2DIR/INNER.TXT") == "/P2DIR")
assert(os.path.basename("LOCAL.TXT") == "LOCAL.TXT")
assert(os.path.dirname("LOCAL.TXT") == "")
assert(os.path.join("/", "P2SMOKE.TXT") == path)
assert(os.path.join("/P2DIR", "INNER.TXT") == "/P2DIR/INNER.TXT")
assert(os.path.join("", "LOCAL.TXT") == "LOCAL.TXT")
assert(os.path.split(path) == ["/", "P2SMOKE.TXT"])
assert(os.path.split("/P2DIR/INNER.TXT") == ["/P2DIR", "INNER.TXT"])
assert(os.path.split("LOCAL.TXT") == ["", "LOCAL.TXT"])
assert(os.path.splitext(path) == ["/P2SMOKE", ".TXT"])
assert(os.path.splitext("/P2DIR/INNER.TXT") == ["/P2DIR/INNER", ".TXT"])
assert(os.path.splitext("/P2DIR/NOEXT") == ["/P2DIR/NOEXT", ""])
assert(os.path.splitext("LOCAL.TXT") == ["LOCAL", ".TXT"])
assert(os.path.splitext("LOCAL") == ["LOCAL", ""])
assert(!os.path.exists("/P2_NO_SUCH.TXT"))
assert(!os.path.isfile("/P2_NO_SUCH.TXT"))
assert(!os.path.isdir("/P2_NO_SUCH.TXT"))
print("P2_SMOKE_STAGE sd path_helpers")

var af = open(path, "a")
assert(af != nil)
af.write("!")
af.close()
var ar = open(path, "r")
assert(ar != nil)
assert(ar.read() == "sd smoke ok!")
ar.close()
print("P2_SMOKE_STAGE sd append")

var append_new_path = "/P2APPEND.TXT"
assert(!os.path.exists(append_new_path))
var append_new = open(append_new_path, "a")
assert(append_new != nil)
append_new.write("created")
append_new.close()
var append_read = open(append_new_path, "r")
assert(append_read != nil)
assert(append_read.read() == "created")
append_read.close()
assert(os.remove(append_new_path))
assert(!os.path.exists(append_new_path))

var rw = open(path, "r+")
assert(rw != nil)
rw.seek(3)
assert(rw.tell() == 3)
rw.write("SMOKE")
rw.close()
var sr = open(path, "r")
assert(sr != nil)
assert(sr.read() == "sd SMOKE ok!")
sr.close()

var text_file = open(path, "r")
assert(text_file != nil)
var text = text_file.read()
text_file.close()
assert(text == "sd SMOKE ok!")

var rf = open(path, "r")
assert(rf.tell() == 0)
assert(rf.readbytes(2).tohex() == "7364")
assert(rf.tell() == 2)
rf.seek(3)
assert(rf.tell() == 3)
assert(rf.read() == "SMOKE ok!")
rf.close()
print("P2_SMOKE_STAGE sd read_seek")

var lines_path = "/P2LINES.TXT"
assert(!os.path.exists(lines_path))

var lf = open(lines_path, "w")
assert(lf != nil)
lf.write("one\n")
lf.write("two\n")
lf.close()
var lines_file = open(lines_path, "r")
assert(lines_file != nil)
var lines = lines_file.readlines()
lines_file.close()
assert(lines == ["one\n", "two\n"])
assert(os.remove(lines_path))

var raw_file = open(path, "r")
assert(raw_file != nil)
var raw = raw_file.readbytes()
raw_file.close()
assert(raw.tohex() == "736420534D4F4B45206F6B21")
print("P2_SMOKE_STAGE sd lines_raw")

var plus_path = "/P2PLUS.TXT"
assert(!os.path.exists(plus_path))

var wf = open(plus_path, "w+")
assert(wf != nil)
wf.write("abc")
wf.seek(0)
assert(wf.tell() == 0)
assert(wf.read() == "abc")
wf.close()

var ap = open(plus_path, "a+")
assert(ap != nil)
ap.write("def")
ap.seek(0)
assert(ap.tell() == 0)
assert(ap.read() == "abcdef")
ap.close()
assert(os.remove(plus_path))
assert(!os.path.exists(plus_path))
print("P2_SMOKE_STAGE sd plus_modes")

var renamed = "/P2SMOKE2.TXT"
assert(!os.path.exists(renamed))
assert(os.rename(path, renamed))
assert(!os.path.exists(path))
assert(os.path.exists(renamed))
assert(os.remove(renamed))
assert(!os.path.exists(renamed))
assert(isinstance(os.listdir("/"), list))
print("P2_SMOKE_STAGE sd rename_list")

var start_cwd = os.getcwd()
assert(type(start_cwd) == "string")

var dir_path = "/P2DIR"
assert(!os.path.exists(dir_path))

assert(os.mkdir(dir_path))
assert(os.path.exists(dir_path))
assert(os.path.isdir(dir_path))
assert(!os.path.isfile(dir_path))
assert(os.path.join(dir_path, "INNER.TXT") == "/P2DIR/INNER.TXT")
assert(os.chdir(dir_path))
assert(os.getcwd() == dir_path)
assert(!os.path.exists("INNER.TXT"))
var inner = open("INNER.TXT", "w")
assert(inner != nil)
inner.write("inner")
inner.close()
var dir_entries = os.listdir(".")
assert(isinstance(dir_entries, list))
var saw_inner = false
for entry : dir_entries
    if entry == "INNER.TXT"
        saw_inner = true
    end
end
assert(saw_inner)
assert(os.path.exists("INNER.TXT"))
assert(os.path.isfile("INNER.TXT"))
assert(os.remove("INNER.TXT"))
assert(!os.path.exists("INNER.TXT"))
assert(os.chdir(start_cwd))
assert(os.getcwd() == start_cwd)
assert(os.remove(dir_path))
assert(!os.path.exists(dir_path))
print("P2_SMOKE_STAGE sd dir_ops")

print("P2_SMOKE_PASS sd")
