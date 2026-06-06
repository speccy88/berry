import libstore

print("Discovered SD modules:")

for name : libstore.modules()
    print("-", name, libstore.source_path(name))
end

print("Trying safe imports for currently supported SD modules")

import binary_heap
import math
import p2mem
import taskspin

print("binary_heap:", type(binary_heap))
print("math.sqrt(81):", math.sqrt(81))
print("p2mem modules:", p2mem.modules().size())
print("taskspin max tasks:", taskspin.info()["max_tasks"])

try
    import wifi
    print("wifi imported")
except .. as e, m
    print("wifi import skipped:", e, m)
end
