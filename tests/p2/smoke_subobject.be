print("P2_SMOKE_BEGIN subobject")

class P2ListSub : classof([])
    var tag
    def init(tag)
        self.tag = tag
    end
    def add_pair(a, b)
        self.push(a)
        self.push(b)
        return self
    end
end

var sublist = P2ListSub("list-tag")
assert(classof(sublist) == P2ListSub)
assert(sublist.tag == "list-tag")
assert(issubclass(P2ListSub, list) == true)
assert(issubclass(P2ListSub, []) == true)
assert(issubclass(sublist, list) == false)
assert(issubclass(sublist, []) == false)
assert(isinstance(P2ListSub, list) == false)
assert(isinstance(P2ListSub, []) == false)
assert(isinstance(sublist, list) == true)
assert(isinstance(sublist, []) == true)
assert(issubclass(list, list) == true)
assert(issubclass(list, []) == true)
assert(isinstance([], list) == true)
assert(isinstance([], P2ListSub) == false)
assert(issubclass(list, P2ListSub) == false)
assert(sublist.add_pair(4, 5) == sublist)
assert(sublist[0] == 4)
assert(sublist[1] == 5)
var sublist_copy = sublist.copy()
assert(sublist_copy == [4, 5])
sublist_copy.push(6)
assert(sublist == [4, 5])

class P2MapSub : map
    var tag
    def init(tag)
        super(self).init()
        self.tag = tag
    end
    def put_value(k, v)
        self[k] = v
        return self[k]
    end
end

var submap = P2MapSub("map-tag")
submap["answer"] = 42
assert(classof(submap) == P2MapSub)
assert(submap.tag == "map-tag")
assert(submap["answer"] == 42)
assert(issubclass(P2MapSub, map) == true)
assert(issubclass(submap, map) == false)
assert(isinstance(P2MapSub, map) == false)
assert(isinstance(submap, map) == true)
assert(isinstance({}, map) == true)
assert(isinstance({}, P2MapSub) == false)
assert(issubclass(map, P2MapSub) == false)
assert(submap.put_value("extra", 7) == 7)
assert(submap["extra"] == 7)
assert(submap.keys().find("answer") != nil)
assert(submap.keys().find("extra") != nil)
var submap_keys = submap.keys()
submap["later"] = 9
assert(submap_keys.find("later") == nil)
assert(submap.keys().find("later") != nil)

print("P2_SMOKE_PASS subobject")
