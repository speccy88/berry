import os
import p2

print("P2 SD REPL helper")
var fs = p2.fs_info("/")
var root = os.listdir("/")
print("filesystem:", fs["mount_result_name"])
print("partition start:", fs["partition_start"])
print("root entries:", root.size())

if os.path.exists("/berry/main.be")
    print("main present:", true)
else
    print("main present:", false)
end
print("repl sd helper done")
