import task

var log = []

def counter(name, limit, delay_ms)
    var runs = task.task_info(task.current())["runs"]
    log.push(name + str(runs))
    print(name, runs)
    if runs >= limit
        return task.done
    end
    return task.sleep(delay_ms)
end

a = task.start(counter, "A", 2, 100)
b = task.start(counter, "B", 3, 150)

task.run(20)

print("tasks", task.list())
print("log", log)
