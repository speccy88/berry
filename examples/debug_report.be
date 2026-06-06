import p2
import p2mem

print("P2 debug snapshot:")
print(p2.debug_snapshot())

print("P2 memory stats:")
print(p2mem.stats())

print("P2 module records:")
for rec : p2mem.modules()
    print(rec["module"], rec["storage_tier"], rec["source_path"])
end
