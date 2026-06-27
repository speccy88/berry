import os

var path = "/berry/examples/core/run_file.be"
if !os.path.exists(path)
    path = "examples/core/run_file.be"
end
if !os.path.exists(path)
    path = "/examples/core/run_file.be"
end

print("run_file demo path:", path)
run_file(path)
print("run_file demo done")
