# P2 SD library store helper.
#
# The current P2 firmware imports .be libraries lazily from /modules on the SD
# card. On edge32, PSRAM is a block device today, so it is reported as a future
# cache backend instead of pretending modules can execute directly from it.

import os
import p2

var libstore = module("libstore")

libstore.paths = ["/modules"]

libstore.psram = def()
    return p2.psram_info()
end

libstore.status = def()
    var psram = p2.psram_info()
    return {
        "paths": libstore.paths,
        "lazy": true,
        "source": "sd",
        "psram_available": psram["available"],
        "psram_bytes": psram["bytes"],
        "psram_cache": false,
        "heap": "hub"
    }
end

libstore.source_path = def(name)
    for base : libstore.paths
        var path = base + "/" + name + ".be"
        if os.path.exists(path)
            return path
        end
    end
    return nil
end

libstore.exists = def(name)
    return libstore.source_path(name) != nil
end

libstore.run = def(path)
    return run_file(path)
end

return libstore
