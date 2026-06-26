print("Trying quick imports for currently supported SD modules")

print("import binary_heap...")
import binary_heap
print("import binary_heap ok")
print("import configstore...")
import configstore
print("import configstore ok")
print("import math...")
import math
print("import math ok")
print("import p2compat...")
import p2compat
print("import p2compat ok")
print("import p2ipc...")
import p2ipc
print("import p2ipc ok")
print("import task...")
import task
print("import task ok")
print("import wifi...")
import wifi
print("import wifi ok")

print("binary_heap:", type(binary_heap))
print("configstore app path:", configstore.path("app"))
print("math.sqrt(81):", math.sqrt(81))
print("p2compat:", type(p2compat))
print("p2ipc model:", p2ipc.contract()["model"])
print("task max tasks:", task.info()["max_tasks"])
print("wifi audit:", wifi.audit_ok(), wifi.capability("hardware_deferred"))

print("import all libs example done")
