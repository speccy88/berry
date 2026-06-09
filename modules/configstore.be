# P2 SD config helper.
#
# Small JSON config files live under /berry/config. This module keeps that
# layout useful without changing boot, import, or low-level SD behavior.

import json
import os
import string

var configstore = module("configstore")

configstore.root = "/berry/config"

configstore._ensure_dir = def(path)
    if !os.path.isdir(path)
        try
            os.mkdir(path)
        except .. as e, m
        end
    end
end

configstore.ensure = def()
    configstore._ensure_dir("/berry")
    configstore._ensure_dir(configstore.root)
    return configstore.root
end

configstore.name = def(name)
    if name == nil
        raise "value_error", "config name is nil"
    end
    var out = str(name)
    if size(out) == 0
        raise "value_error", "config name is empty"
    end
    var slash = string.find(out, "/")
    var backslash = string.find(out, "\\")
    if slash != nil || backslash != nil
        raise "value_error", "config name must be a file name"
    end
    return string.endswith(string.tolower(out), ".json") ? out : out + ".json"
end

configstore.path = def(name)
    return configstore.root + "/" + configstore.name(name)
end

configstore.exists = def(name)
    return os.path.exists(configstore.path(name))
end

configstore.load = def(name, fallback)
    var path = configstore.path(name)
    if !os.path.exists(path)
        return fallback
    end
    var f = open(path, "r")
    var text = f.read()
    f.close()
    return json.load(text)
end

configstore.save = def(name, value)
    configstore.ensure()
    var path = configstore.path(name)
    var f = open(path, "w")
    f.write(json.dump(value))
    f.close()
    return path
end

configstore.remove = def(name)
    var path = configstore.path(name)
    if os.path.exists(path)
        return os.remove(path)
    end
    return false
end

configstore.list = def()
    if !os.path.isdir(configstore.root)
        return []
    end
    var out = []
    for entry : os.listdir(configstore.root)
        if string.endswith(string.tolower(entry), ".json")
            out.push(entry)
        end
    end
    return out
end

return configstore
