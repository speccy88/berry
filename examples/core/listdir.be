import os

def scandir(path, max_entries)
    print("path:", path)
    var names = os.listdir(path)
    print("entry count:", names.size())
    var count = 0
    var limit = names.size()
    if limit > max_entries
        limit = max_entries
    end
    while count < limit
        print("entry:", names[count])
        count += 1
    end
    if names.size() > max_entries
        print("entry limit reached:", max_entries)
    end
end

var root = "/berry/examples/core"
if !os.path.exists(root)
    root = "examples/core"
end
if !os.path.exists(root)
    root = "."
end

scandir(root, 8)
print("listdir demo done")
