print("P2_SMOKE_BEGIN sd_main")

import os

def ensure_dir(path)
    if !os.path.isdir(path)
        try
            os.mkdir(path)
        except .. as e, m
        end
    end
end

ensure_dir("/berry")

assert(!os.path.exists("/berry/main.be"))

var f = open("/berry/main.be", "w")
f.write("import json\n")
f.write("var p1_main_data = json.load('{\"answer\":42}')\n")
f.write("return p1_main_data['answer']\n")
f.close()

assert(os.path.exists("/berry/main.be"))
assert(run_file("/berry/main.be") == 42)

try
    os.remove("/berry/main.be")
except .. as e, m
end
assert(!os.path.exists("/berry/main.be"))

print("P2_SMOKE_PASS sd_main")
