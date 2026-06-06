import taskspin

taskspin.reset()

var log = []

def step(id, state)
    state["count"] += 1
    log.push(state["name"] + str(state["count"]))
    return state["count"] >= state["limit"] ? taskspin.STOP : taskspin.RUN
end

var a = taskspin.TASKSPIN(-1, step, {"name": "A", "count": 0, "limit": 2}, 287)
var b = taskspin.TASKSPIN(-1, step, {"name": "B", "count": 0, "limit": 3}, 286)

print("tasks:", a, b)
while taskspin.info()["tasks"] > 0
    taskspin.TASKNEXT()
end

print("log:", log)
