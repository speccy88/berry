# Public type() reports Berry value kinds; class names are a separate API.
assert(type([]) == 'instance')
assert(type({}) == 'instance')
assert(classname([]) == 'list')
assert(classname({}) == 'map')
assert(isinstance([], list))
assert(isinstance({}, map))

# Merely naming a user class after a builtin must not alter its value kind.
def check_class_names()
    class list end
    class map end
    assert(type(list()) == 'instance')
    assert(type(map()) == 'instance')
end
check_class_names()
