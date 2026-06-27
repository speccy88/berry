import task

var caps = task.capabilities()
var model = task.execution_model()

print("scheduler policy:", caps["scheduler_policy"])
print("unsupported reason:", caps["unsupported_reason"])
print("execution model:", model["model"])
print("max tasks:", caps["max_tasks"])

var log = []

def counter(name, limit, delay_ms)
    var runs = task.lifecycle_result(task.current())["runs"]
    log.push(name + str(runs))
    print("task run:", name, runs)
    if runs >= limit
        return task.done
    end
    return task.sleep(delay_ms)
end

var a = task.start(counter, "A", 2, 1)
var b = task.start(counter, "B", 3, 2)

var steps = task.run(80)

print("handles:", a, b)
print("steps:", steps)
print("status A:", task.status(a))
print("status B:", task.status(b))
print("log size:", log.size())
var i = 0
while i < log.size()
    print("log item:", i, log[i])
    i += 1
end
print("task scheduler example done")
