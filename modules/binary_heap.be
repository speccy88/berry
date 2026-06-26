# https://en.wikipedia.org/wiki/Binary_heap
# This allows to choose the M first elements of an N-sized array
# with respect to a comparison predicate cmp that defines a total order.
# This avoids the overhead of sorting the entire array and then picking
# the first elements.  This is related to a priority queue.
# We also define a binary heap based sort() of an entire array.

var binary_heap = module("binary_heap")

binary_heap.capabilities = def()
  return {
    "make_heap": true,
    "remove_heap": true,
    "sort": true,
    "in_place_sort": true,
    "heap_copy_commit": true,
    "empty_singleton_sort": true,
    "exception_preserves_input": true,
    "comparator_required": true,
    "audit": true,
    "audit_policy": "tiny_in_memory_heap_self_check"
  }
end

binary_heap.capability = def(name)
  if type(name) != "string"
    return nil
  end
  var caps = binary_heap.capabilities()
  if caps.contains(name)
    return caps[name]
  end
  return nil
end

binary_heap.required_capability_keys = def()
  return [
    "make_heap",
    "remove_heap",
    "sort",
    "in_place_sort",
    "heap_copy_commit",
    "empty_singleton_sort",
    "exception_preserves_input",
    "comparator_required",
    "audit",
    "audit_policy"
  ]
end

binary_heap.audit = def()
  var caps = binary_heap.capabilities()
  var problems = []

  var missing_capability_keys = []
  for key : binary_heap.required_capability_keys()
    if !caps.contains(key)
      missing_capability_keys.push(key)
    end
  end
  if missing_capability_keys.size() != 0
    problems.push("missing_capability_keys")
  end

  if !caps["make_heap"]
    problems.push("make_heap_capability_disabled")
  end
  if !caps["remove_heap"]
    problems.push("remove_heap_capability_disabled")
  end
  if !caps["sort"]
    problems.push("sort_capability_disabled")
  end
  if !caps["in_place_sort"]
    problems.push("in_place_sort_capability_disabled")
  end
  if !caps["heap_copy_commit"]
    problems.push("heap_copy_commit_capability_disabled")
  end
  if !caps["empty_singleton_sort"]
    problems.push("empty_singleton_sort_capability_disabled")
  end
  if !caps["exception_preserves_input"]
    problems.push("exception_preserves_input_capability_disabled")
  end
  if !caps["comparator_required"]
    problems.push("comparator_required_capability_disabled")
  end
  if !caps["audit"]
    problems.push("audit_capability_disabled")
  end
  if caps["audit_policy"] != "tiny_in_memory_heap_self_check"
    problems.push("audit_policy_mismatch")
  end
  if binary_heap.capability("sort") != caps["sort"]
    problems.push("sort_lookup_mismatch")
  end
  if binary_heap.capability("missing") != nil
    problems.push("missing_lookup_not_nil")
  end
  if binary_heap.capability(nil) != nil
    problems.push("nil_lookup_not_nil")
  end

  var ascending = [4, 1, 3]
  binary_heap.sort(ascending, /a b -> a < b)
  if ascending != [1, 3, 4]
    problems.push("ascending_sort_failed")
  end

  var empty = []
  binary_heap.sort(empty, /a b -> a < b)
  if empty != []
    problems.push("empty_sort_failed")
  end

  var single = [7]
  binary_heap.sort(single, /a b -> a < b)
  if single != [7]
    problems.push("single_sort_failed")
  end

  var heap = [7, 2, 9, 1]
  binary_heap.make_heap(heap, /a b -> a > b)
  if binary_heap.remove_heap(heap, /a b -> a > b) != 9
    problems.push("remove_heap_first_failed")
  end
  if binary_heap.remove_heap(heap, /a b -> a > b) != 7
    problems.push("remove_heap_second_failed")
  end

  var preserved = [5, 1, 4, 2, 3]
  var state = {"count": 0}
  var raised = false
  try
    binary_heap.sort(preserved, def(a, b)
      state["count"] += 1
      if state["count"] > 4
        raise "value_error", "forced heap audit compare failure"
      end
      return a < b
    end)
  except .. as e, m
    raised = e == "value_error"
  end
  if !raised
    problems.push("exception_preservation_not_exercised")
  end
  if preserved != [5, 1, 4, 2, 3]
    problems.push("exception_preservation_failed")
  end

  return {
    "ok": problems.size() == 0,
    "problem_count": problems.size(),
    "problems": problems,
    "missing_capability_keys": missing_capability_keys,
    "audit_policy": caps["audit_policy"],
    "sort": caps["sort"],
    "make_heap": caps["make_heap"],
    "remove_heap": caps["remove_heap"],
    "heap_copy_commit": caps["heap_copy_commit"],
    "exception_preserves_input": caps["exception_preserves_input"]
  }
end

binary_heap.audit_problems = def()
  return binary_heap.audit()["problems"]
end

binary_heap.audit_ok = def()
  return binary_heap.audit()["ok"]
end

binary_heap._heapify = def(array, cmp, i)
  var m = i, child, e, am, ac
  while true
    child = 2 * i + 1
    if child >= array.size() return end
    ac = array[child]
    am = array[m]
    if cmp(ac, am) m = child am = ac end
    child += 1
    if child < array.size()
      ac = array[child]
      if cmp(ac, am) m = child am = ac end
    end
    if m == i break end
    array[m] = array[i]
    array[i] = am
    i = m
  end
end

# similar to C++11 std::make_heap
binary_heap.make_heap = def(array, cmp)
  var i = size(array) / 2
  while i >= 0 binary_heap._heapify(array, cmp, i) i -= 1 end
end

# similar to C++11 std::pop_heap, but removes and returns the element
binary_heap.remove_heap = def(array, cmp)
  var m = array.size()
  if m < 2 return m == 1 ? array.pop() : nil end
  m = array[0]
  array[0] = array.pop()
  binary_heap._heapify(array, cmp, 0)
  return m
end

# https://en.wikipedia.org/wiki/Heapsort
binary_heap.sort = def(array, cmp)
  var i = array.size(), heap = array.copy(), out = []
  binary_heap.make_heap(heap, cmp)
  while i > 0 out.push(binary_heap.remove_heap(heap, cmp)) i -= 1 end
  array.clear()
  for item : out array.push(item) end
end

return binary_heap
