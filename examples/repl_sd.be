import os
import p2

print("P2 SD REPL helper")
print("filesystem:", p2.fs_info("/")["mount_result_name"])
print("root:", os.listdir("/"))

if os.path.exists("/berry/main.be")
    print("Run /berry/main.be with:")
    print("run_file('/berry/main.be')")
else
    print("No /berry/main.be found yet.")
end
