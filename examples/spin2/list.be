import introspect

var spin2 = introspect.module("spin2")

if spin2 == nil
    print("spin2 default build:", "module archived")
else
    var path = spin2.path()
    var files = spin2.list()

    print("spin2 path:", path)
    print("spin2 binary count:", files.size())

    var i = 0
    while i < files.size()
        var file = files[i]
        print("spin2 binary:", file)
        i += 1
    end
end

print("spin2 list done")
