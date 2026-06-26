# P2 SD config helper.
#
# Small JSON config files live under /berry/config. This module keeps that
# layout useful without changing boot, import, or low-level SD behavior.

import json
import os
import string

var configstore = module("configstore")

configstore.root = "/berry/config"

configstore.capabilities = def()
    return {
        "json_config_files": true,
        "filename_only_validation": true,
        "ensure_root": true,
        "load_result": true,
        "save_result": true,
        "remove_result": true,
        "list_result": true,
        "json_null_detection": true,
        "fat_jso_listing": true,
        "audit": true,
        "audit_policy": "capability_root_result_helper_consistency",
        "root": configstore.root
    }
end

configstore.capability = def(name)
    if type(name) != "string"
        return nil
    end
    var caps = configstore.capabilities()
    if caps.contains(name)
        return caps[name]
    end
    return nil
end

configstore.required_capability_keys = def()
    return [
        "json_config_files",
        "filename_only_validation",
        "ensure_root",
        "load_result",
        "save_result",
        "remove_result",
        "list_result",
        "json_null_detection",
        "fat_jso_listing",
        "audit",
        "audit_policy",
        "root"
    ]
end

configstore.audit = def()
    var caps = configstore.capabilities()
    var problems = []
    var missing_capability_keys = []
    var result_helpers = caps["load_result"] &&
        caps["save_result"] &&
        caps["remove_result"] &&
        caps["list_result"]

    for key : configstore.required_capability_keys()
        if !caps.contains(key)
            missing_capability_keys.push(key)
        end
    end
    if missing_capability_keys.size() != 0
        problems.push("missing_capability_keys")
    end

    if !caps["json_config_files"]
        problems.push("json_config_files_disabled")
    end
    if !caps["filename_only_validation"]
        problems.push("filename_only_validation_disabled")
    end
    if !caps["ensure_root"]
        problems.push("ensure_root_disabled")
    end
    if !result_helpers
        problems.push("result_helpers_incomplete")
    end
    if !caps["json_null_detection"]
        problems.push("json_null_detection_disabled")
    end
    if !caps["fat_jso_listing"]
        problems.push("fat_jso_listing_disabled")
    end
    if !caps["audit"]
        problems.push("audit_capability_disabled")
    end
    if caps["audit_policy"] != "capability_root_result_helper_consistency"
        problems.push("audit_policy_mismatch")
    end
    if caps["root"] != configstore.root
        problems.push("root_capability_mismatch")
    end
    if configstore.capability("root") != configstore.root
        problems.push("root_lookup_mismatch")
    end
    if configstore.capability("load_result") != caps["load_result"]
        problems.push("load_result_lookup_mismatch")
    end
    if configstore.capability("missing") != nil
        problems.push("missing_lookup_not_nil")
    end
    if configstore.capability(nil) != nil
        problems.push("nil_lookup_not_nil")
    end

    return {
        "ok": size(problems) == 0,
        "problem_count": size(problems),
        "problems": problems,
        "missing_capability_keys": missing_capability_keys,
        "root": configstore.root,
        "json_config_files": caps["json_config_files"],
        "filename_only_validation": caps["filename_only_validation"],
        "ensure_root": caps["ensure_root"],
        "result_helpers": result_helpers,
        "json_null_detection": caps["json_null_detection"],
        "fat_jso_listing": caps["fat_jso_listing"],
        "audit_policy": caps["audit_policy"]
    }
end

configstore.audit_problems = def()
    return configstore.audit()["problems"]
end

configstore.audit_ok = def()
    return configstore.audit()["ok"]
end

configstore._ensure_dir = def(path)
    if path == nil || size(path) == 0 || path == "."
        return
    end
    if !os.path.isdir(path)
        var parent = os.path.dirname(path)
        if parent != path && size(parent) > 0 && !os.path.isdir(parent)
            configstore._ensure_dir(parent)
        end
        try
            os.mkdir(path)
        except .. as e, m
        end
    end
end

configstore.ensure = def()
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
    if slash >= 0 || backslash >= 0
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

configstore._json_text_is_null = def(text)
    var i = 0
    var j = size(text) - 1
    while i <= j && (text[i] == " " || text[i] == "\t" || text[i] == "\n" || text[i] == "\r")
        i += 1
    end
    while j >= i && (text[j] == " " || text[j] == "\t" || text[j] == "\n" || text[j] == "\r")
        j -= 1
    end
    return i <= j && text[i..j] == "null"
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

configstore.load_result = def(name, fallback)
    var path = nil
    try
        path = configstore.path(name)
    except .. as e, m
        return {
            "ok": false,
            "found": false,
            "path": nil,
            "value": fallback,
            "error": e,
            "message": m
        }
    end

    if !os.path.exists(path)
        return {
            "ok": true,
            "found": false,
            "path": path,
            "value": fallback,
            "error": nil,
            "message": nil
        }
    end

    try
        var f = open(path, "r")
        var text = f.read()
        f.close()
        var value = json.load(text)
        if value == nil && fallback != nil && !configstore._json_text_is_null(text)
            return {
                "ok": false,
                "found": true,
                "path": path,
                "value": fallback,
                "error": "parse_error",
                "message": "config JSON parsed to nil"
            }
        end
        return {
            "ok": true,
            "found": true,
            "path": path,
            "value": value,
            "error": nil,
            "message": nil
        }
    except .. as e, m
        return {
            "ok": false,
            "found": true,
            "path": path,
            "value": fallback,
            "error": e,
            "message": m
        }
    end
end

configstore.save = def(name, value)
    configstore.ensure()
    var path = configstore.path(name)
    var f = open(path, "w")
    f.write(json.dump(value))
    f.close()
    return path
end

configstore.save_result = def(name, value)
    try
        var path = configstore.save(name, value)
        return {
            "ok": true,
            "path": path,
            "error": nil,
            "message": nil
        }
    except .. as e, m
        return {
            "ok": false,
            "path": nil,
            "error": e,
            "message": m
        }
    end
end

configstore.remove = def(name)
    var path = configstore.path(name)
    if os.path.exists(path)
        return os.remove(path)
    end
    return false
end

configstore.remove_result = def(name)
    var path = nil
    try
        path = configstore.path(name)
        if os.path.exists(path)
            var removed = os.remove(path)
            return {
                "ok": removed,
                "found": true,
                "removed": removed,
                "path": path,
                "error": nil,
                "message": nil
            }
        end
        return {
            "ok": true,
            "found": false,
            "removed": false,
            "path": path,
            "error": nil,
            "message": nil
        }
    except .. as e, m
        return {
            "ok": false,
            "found": false,
            "removed": false,
            "path": path,
            "error": e,
            "message": m
        }
    end
end

configstore.list = def()
    if !os.path.isdir(configstore.root)
        return []
    end
    var out = []
    for entry : os.listdir(configstore.root)
        var lower = string.tolower(entry)
        if string.endswith(lower, ".json") || string.endswith(lower, ".jso")
            out.push(entry)
        end
    end
    return out
end

configstore.list_result = def()
    try
        if !os.path.isdir(configstore.root)
            return {
                "ok": true,
                "found": false,
                "root": configstore.root,
                "items": [],
                "count": 0,
                "error": nil,
                "message": nil
            }
        end
        var items = configstore.list()
        return {
            "ok": true,
            "found": true,
            "root": configstore.root,
            "items": items,
            "count": size(items),
            "error": nil,
            "message": nil
        }
    except .. as e, m
        return {
            "ok": false,
            "found": false,
            "root": configstore.root,
            "items": [],
            "count": 0,
            "error": e,
            "message": m
        }
    end
end

return configstore
