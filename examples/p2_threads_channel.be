import threads

threads.channel("sensor")
threads.put("sensor", 123)
print(threads.get("sensor"))

threads.update("last", "ok")
print(threads.value("last"))
