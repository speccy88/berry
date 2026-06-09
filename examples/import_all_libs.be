import libstore

print("Discovered SD modules:")

for name : libstore.modules()
    print("-", name, libstore.source_path(name))
end

print("Trying safe imports for currently supported SD modules")

import binary_heap
import configstore
import math
import p2compat
import p2ipc
import p2mem
import task

print("binary_heap:", type(binary_heap))
print("configstore:", configstore.path("app"))
print("math.sqrt(81):", math.sqrt(81))
print("p2compat unsupported:", p2compat.unsupported().size())
print("p2ipc:", type(p2ipc))
print("p2mem modules:", p2mem.modules().size())
print("task max tasks:", task.info()["max_tasks"])

try
    import wifi
    print("wifi imported")
except .. as e, m
    print("wifi import skipped:", e, m)
end
