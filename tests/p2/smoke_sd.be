print("P2_SMOKE_BEGIN sd")

import os

var path = "/P2SMOKE.TXT"

assert(!os.path.exists(path))

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

var af = open(path, "a")
assert(af != nil)
af.write("!")
af.close()
assert(open(path, "r").read() == "sd smoke ok!")

var append_new_path = "/P2APPEND.TXT"
assert(!os.path.exists(append_new_path))
var append_new = open(append_new_path, "a")
assert(append_new != nil)
append_new.write("created")
append_new.close()
assert(open(append_new_path, "r").read() == "created")
assert(os.remove(append_new_path))
assert(!os.path.exists(append_new_path))

var rw = open(path, "r+")
assert(rw != nil)
assert(rw.seek(3) == 0)
rw.write("SMOKE")
rw.close()
assert(open(path, "r").read() == "sd SMOKE ok!")

var text = open(path, "r").read()
assert(text == "sd SMOKE ok!")

var rf = open(path, "r")
assert(rf.tell() == 0)
assert(rf.readbytes(2).tohex() == "7364")
assert(rf.tell() == 2)
assert(rf.seek(3) == 0)
assert(rf.tell() == 3)
assert(rf.read() == "SMOKE ok!")
rf.close()

var lines_path = "/P2LINES.TXT"
assert(!os.path.exists(lines_path))

var lf = open(lines_path, "w")
assert(lf != nil)
lf.write("one\n")
lf.write("two\n")
lf.close()
var lines = open(lines_path, "r").readlines()
assert(lines == ["one\n", "two\n"])
assert(os.remove(lines_path))

var raw = open(path, "r").readbytes()
assert(raw.tohex() == "736420534d4f4b45206f6b21")

var plus_path = "/P2PLUS.TXT"
assert(!os.path.exists(plus_path))

var wf = open(plus_path, "w+")
assert(wf != nil)
wf.write("abc")
assert(wf.seek(0) == 0)
assert(wf.read() == "abc")
wf.close()

var ap = open(plus_path, "a+")
assert(ap != nil)
ap.write("def")
assert(ap.seek(0) == 0)
assert(ap.read() == "abcdef")
ap.close()
assert(os.remove(plus_path))
assert(!os.path.exists(plus_path))

var renamed = "/P2SMOKE2.TXT"
assert(!os.path.exists(renamed))
assert(os.rename(path, renamed))
assert(!os.path.exists(path))
assert(os.path.exists(renamed))
assert(os.remove(renamed))
assert(!os.path.exists(renamed))
assert(type(os.listdir("/")) == "list")

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
assert(type(dir_entries) == "list")
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

print("P2_SMOKE_PASS sd")
