import introspect

var p2 = module("p2")
var lock = module("p2.lock")
var lock_state = {}
var next_lock = 0

lock.new = def()
    var id = next_lock
    next_lock += 1
    lock_state[id] = false
    return id
end
lock.try = def(id)
    if lock_state[id]
        return 0
    end
    lock_state[id] = true
    return 1
end
lock.release = def(id)
    lock_state[id] = false
end
lock.ret = def(id)
    lock_state.remove(id)
end

p2.lock = lock
introspect.setmodule("p2", p2)

var p2ipc = run_file("modules/p2ipc.be")
assert(type(p2ipc) == "module")
assert(type(p2.channel) == "module")
assert(type(p2.mailbox) == "module")
assert(type(p2.shared) == "module")
assert(type(p2.mutex) == "module")

var ch = p2.channel.new(2)
assert(ch.send("a"))
assert(ch.send("b"))
assert(!ch.send("c"))
assert(ch.size() == 2)
assert(ch.recv() == "a")
assert(ch.recv() == "b")
assert(ch.recv() == nil)
assert(ch.close())

var mb = p2.mailbox.new()
assert(!mb.ready())
assert(mb.put(42))
assert(mb.ready())
assert(!mb.put(43))
assert(mb.get() == 42)
assert(mb.get() == nil)
assert(mb.close())

var buf = p2.shared.Buffer(4)
assert(buf.size() == 4)
assert(buf.aslist() == [0, 0, 0, 0])
assert(buf.write(0, 17))
assert(buf.write(3, 255))
assert(!buf.write(4, 1))
assert(!buf.write(1, 256))
assert(buf.read(0) == 17)
assert(buf.read(3) == 255)
assert(buf.read(4) == nil)
assert(buf.fill(7))
assert(buf.aslist() == [7, 7, 7, 7])

var m = p2.mutex.new()
assert(m.id() >= 0)
assert(m.lock())
assert(!m.lock())
assert(m.unlock())
assert(m.close())
