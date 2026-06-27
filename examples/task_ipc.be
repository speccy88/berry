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

def channel_closed_waiter(state, ch)
    var res = ch.recv_result()
    if res["error"] == "closed"
        state["error"] = res["error"]
        return task.done
    end
    return task.wait(ch, "recv", 1000)
end

def mailbox_closed_waiter(state, mb)
    var res = mb.get_result()
    if res["error"] == "closed"
        state["error"] = res["error"]
        return task.done
    end
    return task.wait(mb, "get", 1000)
end

print("task ipc integration")

task.reset()
var ch = p2ipc.channel.new(1)
var recv_state = {"value": nil}
var recv_h = task.start(channel_recv_waiter, recv_state, ch)
task.next()
var ch_recv_before = ch.ready_result("recv")
print("channel recv waiting:", recv_h, task.status(recv_h))
print("channel recv ready before:", ch_recv_before["ready"], ch_recv_before["can_recv"])
ch.send_result("ready")
var ch_recv_after_send = ch.ready_result("recv")
task.next()
print("channel recv value:", recv_state["value"], "status", task.status(recv_h))
print("channel recv ready after:", ch_recv_after_send["ready"], ch_recv_after_send["can_recv"])

task.reset()
var full_ch = p2ipc.channel.new(1)
full_ch.send_result("held")
var send_state = {"sent": false}
var send_h = task.start(channel_send_waiter, send_state, full_ch)
task.next()
var ch_send_before = full_ch.ready_result("send")
print("channel send waiting:", send_h, task.status(send_h))
print("channel send ready before:", ch_send_before["ready"], ch_send_before["can_send"])
print("channel released:", full_ch.recv_result()["value"])
var ch_send_after_release = full_ch.ready_result("send")
task.next()
print("channel send stored:", send_state["sent"], full_ch.recv_result()["value"], "status", task.status(send_h))
print("channel send ready after release:", ch_send_after_release["ready"], ch_send_after_release["can_send"])

task.reset()
var mb = p2ipc.mailbox.new()
var mb_get_state = {"value": nil}
var mb_get_h = task.start(mailbox_get_waiter, mb_get_state, mb)
task.next()
var mb_get_before = mb.ready_result("get")
print("mailbox get waiting:", mb_get_h, task.status(mb_get_h))
print("mailbox get ready before:", mb_get_before["ready"], mb_get_before["can_get"])
mb.put_result("mail-ready")
var mb_get_after_put = mb.ready_result("get")
task.next()
print("mailbox get value:", mb_get_state["value"], "status", task.status(mb_get_h))
print("mailbox get ready after:", mb_get_after_put["ready"], mb_get_after_put["can_get"])

task.reset()
var full_mb = p2ipc.mailbox.new()
full_mb.put_result("mail-held")
var mb_put_state = {"stored": false}
var mb_put_h = task.start(mailbox_put_waiter, mb_put_state, full_mb)
task.next()
var mb_put_before = full_mb.ready_result("put")
print("mailbox put waiting:", mb_put_h, task.status(mb_put_h))
print("mailbox put ready before:", mb_put_before["ready"], mb_put_before["can_put"])
print("mailbox released:", full_mb.get_result()["value"])
var mb_put_after_release = full_mb.ready_result("put")
task.next()
print("mailbox put stored:", mb_put_state["stored"], full_mb.get_result()["value"], "status", task.status(mb_put_h))
print("mailbox put ready after release:", mb_put_after_release["ready"], mb_put_after_release["can_put"])

task.reset()
var close_ch = p2ipc.channel.new(1)
var close_ch_state = {"error": nil}
var close_ch_h = task.start(channel_closed_waiter, close_ch_state, close_ch)
task.next()
print("channel close waiting:", close_ch_h, task.status(close_ch_h))
close_ch.close_result()
task.next()
print("channel close wake:", close_ch_state["error"], "status", task.status(close_ch_h))

task.reset()
var close_mb = p2ipc.mailbox.new()
var close_mb_state = {"error": nil}
var close_mb_h = task.start(mailbox_closed_waiter, close_mb_state, close_mb)
task.next()
print("mailbox close waiting:", close_mb_h, task.status(close_mb_h))
close_mb.close_result()
task.next()
print("mailbox close wake:", close_mb_state["error"], "status", task.status(close_mb_h))

print("task ipc example done")
