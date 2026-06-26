import task
import p2ipc

def channel_recv_waiter(state, ch)
    var res = ch.recv_result()
    if res["found"]
        state["value"] = res["value"]
        return task.done
    end
    return task.wait(ch, "recv", 1000)
end

def channel_send_waiter(state, ch)
    var res = ch.send_result("later")
    if res["sent"]
        state["sent"] = true
        return task.done
    end
    return task.wait(ch, "send", 1000)
end

def mailbox_get_waiter(state, mb)
    var res = mb.get_result()
    if res["found"]
        state["value"] = res["value"]
        return task.done
    end
    return task.wait(mb, "get", 1000)
end

def mailbox_put_waiter(state, mb)
    var res = mb.put_result("mail-later")
    if res["stored"]
        state["stored"] = true
        return task.done
    end
    return task.wait(mb, "put", 1000)
end

print("task ipc integration")

task.reset()
var ch = p2ipc.channel.new(1)
var recv_state = {"value": nil}
var recv_h = task.start(channel_recv_waiter, recv_state, ch)
task.next()
print("channel recv waiting:", recv_h, task.status(recv_h))
ch.send_result("ready")
task.next()
print("channel recv value:", recv_state["value"], "status", task.status(recv_h))

task.reset()
var full_ch = p2ipc.channel.new(1)
full_ch.send_result("held")
var send_state = {"sent": false}
var send_h = task.start(channel_send_waiter, send_state, full_ch)
task.next()
print("channel send waiting:", send_h, task.status(send_h))
print("channel released:", full_ch.recv_result()["value"])
task.next()
print("channel send stored:", send_state["sent"], full_ch.recv_result()["value"], "status", task.status(send_h))

task.reset()
var mb = p2ipc.mailbox.new()
var mb_get_state = {"value": nil}
var mb_get_h = task.start(mailbox_get_waiter, mb_get_state, mb)
task.next()
print("mailbox get waiting:", mb_get_h, task.status(mb_get_h))
mb.put_result("mail-ready")
task.next()
print("mailbox get value:", mb_get_state["value"], "status", task.status(mb_get_h))

task.reset()
var full_mb = p2ipc.mailbox.new()
full_mb.put_result("mail-held")
var mb_put_state = {"stored": false}
var mb_put_h = task.start(mailbox_put_waiter, mb_put_state, full_mb)
task.next()
print("mailbox put waiting:", mb_put_h, task.status(mb_put_h))
print("mailbox released:", full_mb.get_result()["value"])
task.next()
print("mailbox put stored:", mb_put_state["stored"], full_mb.get_result()["value"], "status", task.status(mb_put_h))

print("task ipc example done")
