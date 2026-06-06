import libstore
import p2mem

print("Initial memory/cache stats:")
print(p2mem.stats())

print("Caching available source modules where supported...")
try
    print(libstore.cache_all())
except .. as e, m
    print("cache_all skipped:", e, m)
end

print("Cache report:")
print(p2mem.cache())

print("Evicting cache:")
print(p2mem.evict())
