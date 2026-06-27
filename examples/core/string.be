text = "This is a long string test. 0123456789 abcdefg ABCDEFG"
print("text:", text)

print("float literal:", .5)

import string as string_mod

print("hex:", string_mod.hex(0x5678ABCD, 8))

def bin(x, num)
    assert(type(x) == 'int', 'the type of \'x\' must be integer')
    if x == 0
        return num == nil || num <= 1 ? '0' : '0' * num
    end
    var value = x
    var result = ''
    while value > 0
        result = (value % 2 ? '1' : '0') + result
        value = value / 2
    end
    if type(num) == 'int' && num > 0
        while size(result) < num
            result = '0' + result
        end
    end
    return result
end

print("binary:", bin(33, nil))
print("binary padded:", bin(33, 8))
print("string demo done")
