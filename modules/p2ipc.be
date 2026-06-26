# Cooperative P2 IPC facade for Berry.
#
# Import this module to attach p2.channel, p2.mailbox, p2.shared, and p2.mutex
# to the native p2 module. The objects live in the current VM/Hub memory.
# Mutexes use p2.lock hardware locks when available, and fall back to a
# cooperative in-VM lock when no hardware lock can be allocated.

import p2

var p2ipc = module("p2ipc")

def _payload_contract(out, value, present)
    out["payload_contract"] = true
    out["current_vm_reference"] = present
    out["serialized"] = false
    out["ownership_transfer"] = false
    out["payload_type"] = present ? type(value) : nil
    out["serialization_policy"] = "unsupported_current_vm_references_only"
    out["ownership_policy"] = "caller_keeps_current_vm_object_ownership"
    return out
end

def _bounded_attention_available()
    var cog = nil
    try
        cog = p2.cog
    except .. as e, m
        return false
    end
    if type(cog) != "module"
        return false
    end
    try
        return type(cog.wait_attention_result) == "function"
    except .. as e, m
        return false
    end
end

class Mutex
    var lock_id
    var locked
    var closed
    def init()
        self.lock_id = -1
        self.locked = false
        self.closed = false
        if type(p2.lock) == "module"
            var id = p2.lock.new()
            if type(id) == "int" && id >= 0
                self.lock_id = id
            end
        end
    end
    def lock()
        if self.closed
            return false
        end
        if self.lock_id >= 0
            var ok = p2.lock.("try")(self.lock_id) != 0
            if ok
                self.locked = true
            end
            return ok
        end
        if self.locked
            return false
        end
        self.locked = true
        return true
    end
    def lock_result()
        if self.closed
            return {
                "ok": false,
                "locked": false,
                "error": "closed",
                "message": "mutex is closed",
                "lock_id": self.lock_id,
                "hardware": self.lock_id >= 0
            }
        end
        var ok = false
        if self.lock_id >= 0
            ok = p2.lock.("try")(self.lock_id) != 0
            if ok
                self.locked = true
            end
        elif !self.locked
            self.locked = true
            ok = true
        end
        return {
            "ok": ok,
            "locked": ok,
            "error": ok ? nil : "busy",
            "message": ok ? nil : "mutex is busy",
            "lock_id": self.lock_id,
            "hardware": self.lock_id >= 0
        }
    end
    def unlock()
        if self.closed
            return false
        end
        if self.lock_id >= 0
            p2.lock.release(self.lock_id)
            self.locked = false
            return true
        end
        if !self.locked
            return false
        end
        self.locked = false
        return true
    end
    def unlock_result()
        if self.closed
            return {
                "ok": false,
                "unlocked": false,
                "error": "closed",
                "message": "mutex is closed",
                "lock_id": self.lock_id,
                "hardware": self.lock_id >= 0
            }
        end
        if self.lock_id >= 0
            if !self.locked
                return {
                    "ok": false,
                    "unlocked": false,
                    "error": "not_locked",
                    "message": "mutex is not locked",
                    "lock_id": self.lock_id,
                    "hardware": true
                }
            end
            p2.lock.release(self.lock_id)
            self.locked = false
            return {
                "ok": true,
                "unlocked": true,
                "error": nil,
                "message": nil,
                "lock_id": self.lock_id,
                "hardware": true
            }
        end
        if !self.locked
            return {
                "ok": false,
                "unlocked": false,
                "error": "not_locked",
                "message": "mutex is not locked",
                "lock_id": self.lock_id,
                "hardware": false
            }
        end
        self.locked = false
        return {
            "ok": true,
            "unlocked": true,
            "error": nil,
            "message": nil,
            "lock_id": self.lock_id,
            "hardware": false
        }
    end
    def close()
        if self.closed
            return true
        end
        if self.lock_id >= 0
            p2.lock.ret(self.lock_id)
            self.lock_id = -1
        end
        self.locked = false
        self.closed = true
        return true
    end
    def close_result()
        var was_closed = self.closed
        var previous_lock_id = self.lock_id
        var was_hardware = self.lock_id >= 0
        self.close()
        return {
            "ok": true,
            "closed": true,
            "was_closed": was_closed,
            "error": nil,
            "message": nil,
            "lock_id": previous_lock_id,
            "hardware": was_hardware
        }
    end
    def id()
        return self.lock_id
    end
    def info()
        return {
            "kind": "Mutex",
            "lock_id": self.lock_id,
            "hardware": self.lock_id >= 0,
            "locked": self.lock_id >= 0 ? nil : self.locked,
            "closed": self.closed
        }
    end
end

class Channel
    var _task_kind
    var depth
    var items
    var mutex
    var closed
    def init(depth)
        self._task_kind = "p2ipc_channel"
        if depth == nil
            self.depth = 8
        elif type(depth) != "int" || depth < 0
            self.depth = 0
        else
            self.depth = depth
        end
        self.items = []
        self.mutex = Mutex()
        self.closed = false
    end
    def send(value)
        if self.closed
            return false
        end
        if !self.mutex.lock()
            return false
        end
        var ok = false
        if self.items.size() < self.depth
            self.items.push(value)
            ok = true
        end
        self.mutex.unlock()
        return ok
    end
    def send_result(value)
        if self.closed
            return _payload_contract({
                "ok": false,
                "sent": false,
                "error": "closed",
                "message": "channel is closed",
                "size": self.items.size(),
                "free": self.free()
            }, value, true)
        end
        if !self.mutex.lock()
            return _payload_contract({
                "ok": false,
                "sent": false,
                "error": "lock_busy",
                "message": "channel mutex is busy",
                "size": self.items.size(),
                "free": self.free()
            }, value, true)
        end
        var ok = false
        if self.items.size() < self.depth
            self.items.push(value)
            ok = true
        end
        var out = {
            "ok": ok,
            "sent": ok,
            "error": ok ? nil : "full",
            "message": ok ? nil : "channel is full",
            "size": self.items.size(),
            "free": self.free()
        }
        self.mutex.unlock()
        return _payload_contract(out, value, true)
    end
    def recv(timeout_ms)
        if self.closed
            return nil
        end
        if !self.mutex.lock()
            return nil
        end
        var value = nil
        if self.items.size() > 0
            value = self.items.pop(0)
        end
        self.mutex.unlock()
        return value
    end
    def recv_result(timeout_ms)
        if self.closed
            return _payload_contract({
                "ok": false,
                "found": false,
                "value": nil,
                "error": "closed",
                "message": "channel is closed",
                "size": self.items.size(),
                "free": self.free()
            }, nil, false)
        end
        if !self.mutex.lock()
            return _payload_contract({
                "ok": false,
                "found": false,
                "value": nil,
                "error": "lock_busy",
                "message": "channel mutex is busy",
                "size": self.items.size(),
                "free": self.free()
            }, nil, false)
        end
        var found = false, value = nil
        if self.items.size() > 0
            value = self.items.pop(0)
            found = true
        end
        var out = {
            "ok": true,
            "found": found,
            "value": value,
            "error": nil,
            "message": nil,
            "size": self.items.size(),
            "free": self.free()
        }
        self.mutex.unlock()
        return _payload_contract(out, value, found)
    end
    def snapshot_result()
        if self.closed
            return {
                "ok": false,
                "error": "closed",
                "message": "channel is closed",
                "items": [],
                "size": self.items.size(),
                "free": self.free(),
                "depth": self.depth,
                "payload_contract": true,
                "current_vm_reference": false,
                "serialized": false,
                "ownership_transfer": false,
                "serialization_policy": "unsupported_current_vm_references_only",
                "ownership_policy": "caller_keeps_current_vm_object_ownership"
            }
        end
        if !self.mutex.lock()
            return {
                "ok": false,
                "error": "lock_busy",
                "message": "channel mutex is busy",
                "items": [],
                "size": self.items.size(),
                "free": self.free(),
                "depth": self.depth,
                "payload_contract": true,
                "current_vm_reference": false,
                "serialized": false,
                "ownership_transfer": false,
                "serialization_policy": "unsupported_current_vm_references_only",
                "ownership_policy": "caller_keeps_current_vm_object_ownership"
            }
        end
        var items = []
        for item : self.items
            items.push(item)
        end
        var out = {
            "ok": true,
            "error": nil,
            "message": nil,
            "items": items,
            "size": self.items.size(),
            "free": self.free(),
            "depth": self.depth,
            "payload_contract": true,
            "current_vm_reference": items.size() > 0,
            "serialized": false,
            "ownership_transfer": false,
            "serialization_policy": "unsupported_current_vm_references_only",
            "ownership_policy": "caller_keeps_current_vm_object_ownership"
        }
        self.mutex.unlock()
        return out
    end
    def size()
        return self.items.size()
    end
    def free()
        return self.depth - self.items.size()
    end
    def clear()
        if self.closed
            return false
        end
        if !self.mutex.lock()
            return false
        end
        self.items.clear()
        self.mutex.unlock()
        return true
    end
    def clear_result()
        if self.closed
            return {
                "ok": false,
                "cleared": false,
                "error": "closed",
                "message": "channel is closed",
                "size": self.items.size(),
                "free": self.free(),
                "released_payloads": 0
            }
        end
        if !self.mutex.lock()
            return {
                "ok": false,
                "cleared": false,
                "error": "lock_busy",
                "message": "channel mutex is busy",
                "size": self.items.size(),
                "free": self.free(),
                "released_payloads": 0
            }
        end
        var released = self.items.size()
        self.items.clear()
        var out = {
            "ok": true,
            "cleared": true,
            "error": nil,
            "message": nil,
            "size": self.items.size(),
            "free": self.free(),
            "released_payloads": released
        }
        self.mutex.unlock()
        return out
    end
    def close()
        self.items.clear()
        self.closed = true
        return self.mutex.close()
    end
    def close_result()
        var was_closed = self.closed
        var previous_lock_id = self.mutex.id()
        var was_hardware = previous_lock_id >= 0
        var previous_size = self.items.size()
        var previous_free = self.free()
        self.close()
        return {
            "ok": true,
            "closed": true,
            "was_closed": was_closed,
            "error": nil,
            "message": nil,
            "depth": self.depth,
            "size": self.items.size(),
            "free": self.free(),
            "previous_size": previous_size,
            "previous_free": previous_free,
            "released_payloads": previous_size,
            "lock_id": previous_lock_id,
            "hardware_lock": was_hardware
        }
    end
    def info()
        return {
            "kind": "Channel",
            "depth": self.depth,
            "size": self.items.size(),
            "free": self.free(),
            "lock_id": self.mutex.id(),
            "hardware_lock": self.mutex.id() >= 0,
            "closed": self.closed
        }
    end
end

class Mailbox
    var _task_kind
    var full
    var value
    var mutex
    var closed
    def init()
        self._task_kind = "p2ipc_mailbox"
        self.full = false
        self.value = nil
        self.mutex = Mutex()
        self.closed = false
    end
    def put(value)
        if self.closed
            return false
        end
        if !self.mutex.lock()
            return false
        end
        var ok = false
        if !self.full
            self.value = value
            self.full = true
            ok = true
        end
        self.mutex.unlock()
        return ok
    end
    def put_result(value)
        if self.closed
            return _payload_contract({
                "ok": false,
                "stored": false,
                "error": "closed",
                "message": "mailbox is closed",
                "ready": self.full
            }, value, true)
        end
        if !self.mutex.lock()
            return _payload_contract({
                "ok": false,
                "stored": false,
                "error": "lock_busy",
                "message": "mailbox mutex is busy",
                "ready": self.full
            }, value, true)
        end
        var ok = false
        if !self.full
            self.value = value
            self.full = true
            ok = true
        end
        var out = {
            "ok": ok,
            "stored": ok,
            "error": ok ? nil : "full",
            "message": ok ? nil : "mailbox is full",
            "ready": self.full
        }
        self.mutex.unlock()
        return _payload_contract(out, value, true)
    end
    def get()
        if self.closed
            return nil
        end
        if !self.mutex.lock()
            return nil
        end
        var out = nil
        if self.full
            out = self.value
            self.value = nil
            self.full = false
        end
        self.mutex.unlock()
        return out
    end
    def get_result()
        if self.closed
            return _payload_contract({
                "ok": false,
                "found": false,
                "value": nil,
                "error": "closed",
                "message": "mailbox is closed",
                "ready": self.full
            }, nil, false)
        end
        if !self.mutex.lock()
            return _payload_contract({
                "ok": false,
                "found": false,
                "value": nil,
                "error": "lock_busy",
                "message": "mailbox mutex is busy",
                "ready": self.full
            }, nil, false)
        end
        var found = false, value = nil
        if self.full
            value = self.value
            self.value = nil
            self.full = false
            found = true
        end
        var out = {
            "ok": true,
            "found": found,
            "value": value,
            "error": nil,
            "message": nil,
            "ready": self.full
        }
        self.mutex.unlock()
        return _payload_contract(out, value, found)
    end
    def peek_result()
        if self.closed
            return _payload_contract({
                "ok": false,
                "found": false,
                "value": nil,
                "error": "closed",
                "message": "mailbox is closed",
                "ready": self.full
            }, nil, false)
        end
        if !self.mutex.lock()
            return _payload_contract({
                "ok": false,
                "found": false,
                "value": nil,
                "error": "lock_busy",
                "message": "mailbox mutex is busy",
                "ready": self.full
            }, nil, false)
        end
        var found = self.full
        var value = found ? self.value : nil
        var out = {
            "ok": true,
            "found": found,
            "value": value,
            "error": nil,
            "message": nil,
            "ready": self.full
        }
        self.mutex.unlock()
        return _payload_contract(out, value, found)
    end
    def ready()
        return self.full
    end
    def clear()
        if self.closed
            return false
        end
        if !self.mutex.lock()
            return false
        end
        self.value = nil
        self.full = false
        self.mutex.unlock()
        return true
    end
    def clear_result()
        if self.closed
            return {
                "ok": false,
                "cleared": false,
                "error": "closed",
                "message": "mailbox is closed",
                "ready": self.full,
                "released_payload": false
            }
        end
        if !self.mutex.lock()
            return {
                "ok": false,
                "cleared": false,
                "error": "lock_busy",
                "message": "mailbox mutex is busy",
                "ready": self.full,
                "released_payload": false
            }
        end
        var released = self.full
        self.value = nil
        self.full = false
        var out = {
            "ok": true,
            "cleared": true,
            "error": nil,
            "message": nil,
            "ready": self.full,
            "released_payload": released
        }
        self.mutex.unlock()
        return out
    end
    def close()
        self.full = false
        self.value = nil
        self.closed = true
        return self.mutex.close()
    end
    def close_result()
        var was_closed = self.closed
        var previous_lock_id = self.mutex.id()
        var was_hardware = previous_lock_id >= 0
        var previous_ready = self.full
        self.close()
        return {
            "ok": true,
            "closed": true,
            "was_closed": was_closed,
            "error": nil,
            "message": nil,
            "ready": self.full,
            "previous_ready": previous_ready,
            "released_payload": previous_ready,
            "lock_id": previous_lock_id,
            "hardware_lock": was_hardware
        }
    end
    def info()
        return {
            "kind": "Mailbox",
            "ready": self.full,
            "lock_id": self.mutex.id(),
            "hardware_lock": self.mutex.id() >= 0,
            "closed": self.closed
        }
    end
end

class Buffer
    var bytes
    def init(size)
        self.bytes = []
        var n = 0
        if type(size) == "int" && size > 0
            n = size
        end
        for i : 0..n - 1
            self.bytes.push(0)
        end
    end
    def size()
        return self.bytes.size()
    end
    def read(offset)
        if type(offset) != "int" || offset < 0 || offset >= self.bytes.size()
            return nil
        end
        return self.bytes[offset]
    end
    def read_result(offset)
        if type(offset) != "int"
            return {"ok": false, "found": false, "value": nil, "error": "invalid_offset", "message": "offset must be an integer"}
        end
        if offset < 0 || offset >= self.bytes.size()
            return {"ok": false, "found": false, "value": nil, "error": "offset_out_of_range", "message": "offset is outside the buffer"}
        end
        return {"ok": true, "found": true, "value": self.bytes[offset], "error": nil, "message": nil}
    end
    def write(offset, value)
        if type(offset) != "int" || offset < 0 || offset >= self.bytes.size()
            return false
        end
        if type(value) != "int"
            return false
        end
        if value < 0 || value > 255
            return false
        end
        self.bytes[offset] = value
        return true
    end
    def write_result(offset, value)
        if type(offset) != "int"
            return {"ok": false, "written": false, "error": "invalid_offset", "message": "offset must be an integer"}
        end
        if offset < 0 || offset >= self.bytes.size()
            return {"ok": false, "written": false, "error": "offset_out_of_range", "message": "offset is outside the buffer"}
        end
        if type(value) != "int"
            return {"ok": false, "written": false, "error": "invalid_value", "message": "value must be an integer byte"}
        end
        if value < 0 || value > 255
            return {"ok": false, "written": false, "error": "value_out_of_range", "message": "value must be in byte range 0..255"}
        end
        self.bytes[offset] = value
        return {"ok": true, "written": true, "error": nil, "message": nil}
    end
    def fill(value)
        if type(value) != "int"
            return false
        end
        if value < 0 || value > 255
            return false
        end
        for i : 0..self.bytes.size() - 1
            self.bytes[i] = value
        end
        return true
    end
    def fill_result(value)
        if type(value) != "int"
            return {"ok": false, "filled": false, "error": "invalid_value", "message": "value must be an integer byte"}
        end
        if value < 0 || value > 255
            return {"ok": false, "filled": false, "error": "value_out_of_range", "message": "value must be in byte range 0..255"}
        end
        for i : 0..self.bytes.size() - 1
            self.bytes[i] = value
        end
        return {"ok": true, "filled": true, "error": nil, "message": nil}
    end
    def clear()
        for i : 0..self.bytes.size() - 1
            self.bytes[i] = 0
        end
        return true
    end
    def clear_result()
        var n = self.bytes.size()
        self.clear()
        return {"ok": true, "cleared": true, "size": n, "released_bytes": n, "error": nil, "message": nil}
    end
    def aslist()
        return self.bytes.copy()
    end
    def info()
        return {
            "kind": "Buffer",
            "size": self.bytes.size()
        }
    end
end

var channel = module("p2.channel")
channel.new = def(depth)
    return Channel(depth)
end
channel.Channel = Channel

var mailbox = module("p2.mailbox")
mailbox.new = def()
    return Mailbox()
end
mailbox.Mailbox = Mailbox

var mutex = module("p2.mutex")
mutex.new = def()
    return Mutex()
end
mutex.Mutex = Mutex

var shared = module("p2.shared")
shared.Buffer = Buffer

p2.channel = channel
p2.mailbox = mailbox
p2.mutex = mutex
p2.shared = shared

p2ipc.channel = channel
p2ipc.mailbox = mailbox
p2ipc.mutex = mutex
p2ipc.shared = shared

p2ipc.self_test_result = def(iterations)
    if iterations == nil
        iterations = 1
    end
    if type(iterations) != "int" || iterations < 0
        return {
            "ok": false,
            "error": "invalid_iterations",
            "message": "iterations must be a non-negative integer",
            "iterations": 0,
            "checks": 0,
            "failures": []
        }
    end
    if iterations > 64
        iterations = 64
    end

    var failures = []
    var checks = 0

    def expect(cond, label)
        checks += 1
        if !cond
            failures.push(label)
        end
    end

    var i = 0
    while i < iterations
        var label = "iter_" + str(i) + "_"

        var ch = p2.channel.new(2)
        expect(ch.send_result(i)["ok"], label + "channel_send")
        var ch_recv = ch.recv_result()
        expect(ch_recv["ok"] && ch_recv["found"] && ch_recv["value"] == i, label + "channel_recv")
        expect(ch.send_result("held")["ok"], label + "channel_send_held")
        var ch_snapshot = ch.snapshot_result()
        expect(ch_snapshot["ok"] && ch_snapshot["items"].size() == 1 && ch_snapshot["items"][0] == "held" && ch.size() == 1, label + "channel_snapshot")
        var ch_clear = ch.clear_result()
        expect(ch_clear["ok"] && ch_clear["released_payloads"] == 1 && ch.size() == 0, label + "channel_clear")
        expect(ch.close_result()["closed"], label + "channel_close")
        expect(ch.send_result("closed")["error"] == "closed", label + "channel_closed_send")

        var mb = p2.mailbox.new()
        expect(mb.put_result(i)["ok"], label + "mailbox_put")
        var mb_get = mb.get_result()
        expect(mb_get["ok"] && mb_get["found"] && mb_get["value"] == i, label + "mailbox_get")
        expect(mb.put_result("held")["ok"], label + "mailbox_put_held")
        var mb_peek = mb.peek_result()
        expect(mb_peek["ok"] && mb_peek["found"] && mb_peek["value"] == "held" && mb.ready(), label + "mailbox_peek")
        var mb_clear = mb.clear_result()
        expect(mb_clear["ok"] && mb_clear["released_payload"], label + "mailbox_clear")
        expect(mb.close_result()["closed"], label + "mailbox_close")
        expect(mb.put_result("closed")["error"] == "closed", label + "mailbox_closed_put")

        var buf = p2.shared.Buffer(4)
        expect(buf.write_result(0, i % 256)["ok"], label + "buffer_write")
        expect(buf.read_result(0)["value"] == i % 256, label + "buffer_read")
        expect(buf.fill_result(7)["ok"], label + "buffer_fill")
        var buf_clear = buf.clear_result()
        expect(buf_clear["ok"] && buf_clear["released_bytes"] == 4 && buf.read(0) == 0, label + "buffer_clear")

        var mx = p2.mutex.new()
        expect(mx.lock_result()["ok"], label + "mutex_lock")
        expect(mx.unlock_result()["ok"], label + "mutex_unlock")
        var mx_close = mx.close_result()
        expect(mx_close["ok"] && mx_close["closed"], label + "mutex_close")
        expect(mx.lock_result()["error"] == "closed", label + "mutex_closed_lock")

        i += 1
    end

    return {
        "ok": failures.size() == 0,
        "error": failures.size() == 0 ? nil : "self_test_failed",
        "message": failures.size() == 0 ? nil : "one or more current-VM IPC cleanup checks failed",
        "iterations": iterations,
        "checks": checks,
        "failures": failures,
        "failure_count": failures.size(),
        "policy": "bounded_current_vm_cleanup_diagnostic"
    }
end

p2ipc.capabilities = def()
    var bounded_attention = _bounded_attention_available()
    return {
        "current_vm": true,
        "cross_vm": false,
        "contract": true,
        "cross_vm_reason": "current VM objects are not serialized or transferred across VM/cog boundaries",
        "wakeup_policy": "no_cross_cog_wakeup",
        "attention_policy": "native_bounded_wait_available_not_wired_to_ipc",
        "bounded_attention_wait": bounded_attention,
        "cross_cog_attention_wakeup": false,
        "serialization_policy": "unsupported_current_vm_references_only",
        "ownership_policy": "caller_keeps_current_vm_object_ownership",
        "payload_contract_results": true,
        "task_wait_integration": true,
        "task_wait_channel": true,
        "task_wait_mailbox": true,
        "channel": true,
        "mailbox": true,
        "mutex": true,
        "shared_buffer": true,
        "result_diagnostics": true,
        "nil_payload_results": true,
        "close_result": true,
        "close_releases_payloads": true,
        "clear_result": true,
        "clear_releases_payloads": true,
        "snapshot_result": true,
        "peek_result": true,
        "shared_buffer_clear_result": true,
        "self_test_result": true,
        "self_test_policy": "bounded_current_vm_cleanup_diagnostic",
        "hardware_lock_backend_available": type(p2.lock) == "module",
        "fallback_mutex": true
    }
end

p2ipc.attention_policy = def()
    var bounded_attention = _bounded_attention_available()
    return {
        "policy": "native_bounded_wait_available_not_wired_to_ipc",
        "bounded_attention_wait": bounded_attention,
        "wait_helper": "p2.cog.wait_attention_result",
        "cross_cog_wakeup": false,
        "channel_wakeup": false,
        "mailbox_wakeup": false,
        "current_vm_only": true,
        "reason": "IPC channels and mailboxes are current-VM cooperative objects; native cog attention is available as a bounded primitive but is not wired to IPC wakeups yet"
    }
end

p2ipc.attention_policy_value = def(name)
    if type(name) != "string"
        return nil
    end
    var policy = p2ipc.attention_policy()
    if policy.contains(name)
        return policy[name]
    end
    return nil
end

p2ipc.capability = def(name)
    if type(name) != "string"
        return nil
    end
    var caps = p2ipc.capabilities()
    if caps.contains(name)
        return caps[name]
    end
    return nil
end

p2ipc.contract = def()
    var attention = p2ipc.attention_policy()
    return {
        "model": "current_vm_cooperative_ipc",
        "current_vm": true,
        "cross_vm": false,
        "cross_cog_wakeup": false,
        "serialization": false,
        "ownership_transfer": false,
        "payload_contract_results": true,
        "task_wait_integration": true,
        "task_wait_channel": true,
        "task_wait_mailbox": true,
        "close_releases_payloads": true,
        "clear_releases_payloads": true,
        "snapshot_result": true,
        "peek_result": true,
        "shared_buffer_clear_result": true,
        "self_test_result": true,
        "self_test_policy": "bounded_current_vm_cleanup_diagnostic",
        "hardware_lock_backend_available": type(p2.lock) == "module",
        "fallback_mutex": true,
        "wakeup_policy": "no_cross_cog_wakeup",
        "attention_policy": attention["policy"],
        "bounded_attention_wait": attention["bounded_attention_wait"],
        "cross_cog_attention_wakeup": attention["cross_cog_wakeup"],
        "serialization_policy": "unsupported_current_vm_references_only",
        "ownership_policy": "caller_keeps_current_vm_object_ownership",
        "unsupported_reason": "cross-VM serialization, cross-cog wakeups, ownership transfer, and independent child-VM resource cleanup are not implemented"
    }
end

p2ipc.contract_value = def(name)
    if type(name) != "string"
        return nil
    end
    var contract = p2ipc.contract()
    if contract.contains(name)
        return contract[name]
    end
    return nil
end

p2ipc.required_capability_keys = def()
    return [
        "current_vm",
        "cross_vm",
        "contract",
        "cross_vm_reason",
        "wakeup_policy",
        "attention_policy",
        "bounded_attention_wait",
        "cross_cog_attention_wakeup",
        "serialization_policy",
        "ownership_policy",
        "payload_contract_results",
        "task_wait_integration",
        "task_wait_channel",
        "task_wait_mailbox",
        "channel",
        "mailbox",
        "mutex",
        "shared_buffer",
        "result_diagnostics",
        "nil_payload_results",
        "close_result",
        "close_releases_payloads",
        "clear_result",
        "clear_releases_payloads",
        "snapshot_result",
        "peek_result",
        "shared_buffer_clear_result",
        "self_test_result",
        "self_test_policy",
        "hardware_lock_backend_available",
        "fallback_mutex"
    ]
end

p2ipc.required_contract_keys = def()
    return [
        "model",
        "current_vm",
        "cross_vm",
        "cross_cog_wakeup",
        "serialization",
        "ownership_transfer",
        "payload_contract_results",
        "task_wait_integration",
        "task_wait_channel",
        "task_wait_mailbox",
        "close_releases_payloads",
        "clear_releases_payloads",
        "snapshot_result",
        "peek_result",
        "shared_buffer_clear_result",
        "self_test_result",
        "self_test_policy",
        "hardware_lock_backend_available",
        "fallback_mutex",
        "wakeup_policy",
        "attention_policy",
        "bounded_attention_wait",
        "cross_cog_attention_wakeup",
        "serialization_policy",
        "ownership_policy",
        "unsupported_reason"
    ]
end

p2ipc.audit = def()
    var caps = p2ipc.capabilities()
    var contract = p2ipc.contract()
    var problems = []
    var missing_capabilities = []
    var missing_contract = []

    for key : p2ipc.required_capability_keys()
        if !caps.contains(key)
            missing_capabilities.push(key)
        end
    end
    for key : p2ipc.required_contract_keys()
        if !contract.contains(key)
            missing_contract.push(key)
        end
    end
    if missing_capabilities.size() > 0
        problems.push("missing_capability_keys")
    end
    if missing_contract.size() > 0
        problems.push("missing_contract_keys")
    end

    if !caps["current_vm"] || !contract["current_vm"]
        problems.push("current_vm_not_enabled")
    end
    if caps["cross_vm"] || contract["cross_vm"]
        problems.push("cross_vm_enabled")
    end
    if contract["cross_cog_wakeup"]
        problems.push("cross_cog_wakeup_enabled")
    end
    if contract["cross_cog_attention_wakeup"]
        problems.push("cross_cog_attention_wakeup_enabled")
    end
    if caps["attention_policy"] != contract["attention_policy"]
        problems.push("attention_policy_mismatch")
    end
    if caps["bounded_attention_wait"] != contract["bounded_attention_wait"]
        problems.push("bounded_attention_wait_mismatch")
    end
    if caps["cross_cog_attention_wakeup"] != contract["cross_cog_attention_wakeup"]
        problems.push("cross_cog_attention_wakeup_mismatch")
    end
    if contract["serialization"]
        problems.push("serialization_enabled")
    end
    if contract["ownership_transfer"]
        problems.push("ownership_transfer_enabled")
    end
    if caps["serialization_policy"] != contract["serialization_policy"]
        problems.push("serialization_policy_mismatch")
    end
    if caps["ownership_policy"] != contract["ownership_policy"]
        problems.push("ownership_policy_mismatch")
    end
    if caps["payload_contract_results"] != contract["payload_contract_results"]
        problems.push("payload_contract_results_mismatch")
    end
    if caps["task_wait_integration"] != contract["task_wait_integration"] || caps["task_wait_channel"] != contract["task_wait_channel"] || caps["task_wait_mailbox"] != contract["task_wait_mailbox"]
        problems.push("task_wait_integration_mismatch")
    end
    if caps["close_releases_payloads"] != contract["close_releases_payloads"]
        problems.push("close_cleanup_mismatch")
    end
    if caps["clear_releases_payloads"] != contract["clear_releases_payloads"]
        problems.push("clear_cleanup_mismatch")
    end
    if caps["snapshot_result"] != contract["snapshot_result"]
        problems.push("snapshot_result_mismatch")
    end
    if caps["peek_result"] != contract["peek_result"]
        problems.push("peek_result_mismatch")
    end
    if caps["shared_buffer_clear_result"] != contract["shared_buffer_clear_result"]
        problems.push("shared_buffer_clear_mismatch")
    end
    if caps["self_test_result"] != contract["self_test_result"]
        problems.push("self_test_result_mismatch")
    end
    if caps["self_test_policy"] != contract["self_test_policy"]
        problems.push("self_test_policy_mismatch")
    end
    if caps["hardware_lock_backend_available"] != contract["hardware_lock_backend_available"]
        problems.push("hardware_lock_backend_mismatch")
    end
    if caps["fallback_mutex"] != contract["fallback_mutex"]
        problems.push("fallback_mutex_mismatch")
    end

    return {
        "ok": problems.size() == 0,
        "problem_count": problems.size(),
        "problems": problems,
        "missing_capability_keys": missing_capabilities,
        "missing_contract_keys": missing_contract,
        "model": contract["model"],
        "current_vm": contract["current_vm"],
        "cross_vm": contract["cross_vm"],
        "cross_cog_attention_wakeup": contract["cross_cog_attention_wakeup"],
        "bounded_attention_wait": contract["bounded_attention_wait"],
        "serialization": contract["serialization"],
        "ownership_transfer": contract["ownership_transfer"],
        "payload_contract_results": contract["payload_contract_results"],
        "task_wait_integration": contract["task_wait_integration"],
        "task_wait_channel": contract["task_wait_channel"],
        "task_wait_mailbox": contract["task_wait_mailbox"],
        "snapshot_result": contract["snapshot_result"],
        "peek_result": contract["peek_result"],
        "self_test_result": contract["self_test_result"],
        "self_test_policy": contract["self_test_policy"]
    }
end

p2ipc.audit_problems = def()
    var out = []
    for problem : p2ipc.audit()["problems"]
        out.push(problem)
    end
    return out
end

p2ipc.audit_ok = def()
    return p2ipc.audit_problems().size() == 0
end

return p2ipc
