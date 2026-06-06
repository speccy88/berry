# Cooperative P2 IPC facade for Berry.
#
# Import this module to attach p2.channel, p2.mailbox, p2.shared, and p2.mutex
# to the native p2 module. The objects live in the current VM/Hub memory.
# Mutexes use p2.lock hardware locks when available, and fall back to a
# cooperative in-VM lock when no hardware lock can be allocated.

import p2

var p2ipc = module("p2ipc")

class Mutex
    var lock_id
    var locked
    def init()
        self.lock_id = -1
        self.locked = false
        if type(p2.lock) == "module"
            var id = p2.lock.new()
            if type(id) == "int" && id >= 0
                self.lock_id = id
            end
        end
    end
    def lock()
        if self.lock_id >= 0
            return p2.lock.try(self.lock_id) != 0
        end
        if self.locked
            return false
        end
        self.locked = true
        return true
    end
    def unlock()
        if self.lock_id >= 0
            p2.lock.release(self.lock_id)
            return true
        end
        if !self.locked
            return false
        end
        self.locked = false
        return true
    end
    def close()
        if self.lock_id >= 0
            p2.lock.ret(self.lock_id)
            self.lock_id = -1
        end
        self.locked = false
        return true
    end
    def id()
        return self.lock_id
    end
end

class Channel
    var depth
    var items
    var mutex
    def init(depth)
        self.depth = depth == nil ? 8 : depth
        self.items = []
        self.mutex = Mutex()
    end
    def send(value)
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
    def recv(timeout_ms)
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
    def size()
        return self.items.size()
    end
    def free()
        return self.depth - self.items.size()
    end
    def close()
        return self.mutex.close()
    end
end

class Mailbox
    var full
    var value
    var mutex
    def init()
        self.full = false
        self.value = nil
        self.mutex = Mutex()
    end
    def put(value)
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
    def get()
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
    def ready()
        return self.full
    end
    def close()
        return self.mutex.close()
    end
end

class Buffer
    var bytes
    def init(size)
        self.bytes = []
        var n = size == nil ? 0 : size
        for i : 0..n - 1
            self.bytes.push(0)
        end
    end
    def size()
        return self.bytes.size()
    end
    def read(offset)
        if offset < 0 || offset >= self.bytes.size()
            return nil
        end
        return self.bytes[offset]
    end
    def write(offset, value)
        if offset < 0 || offset >= self.bytes.size()
            return false
        end
        if value < 0 || value > 255
            return false
        end
        self.bytes[offset] = value
        return true
    end
    def fill(value)
        if value < 0 || value > 255
            return false
        end
        for i : 0..self.bytes.size() - 1
            self.bytes[i] = value
        end
        return true
    end
    def aslist()
        return self.bytes.copy()
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

return p2ipc
