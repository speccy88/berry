# Hardware smoke for registry-backed source task descriptors.
# Expected on the current Catalina XMM profile: unsupported fast-fail.

import p2

source = "import p2\n" \
         "def once(pin, ms)\n" \
         "  p2.toggle(pin)\n" \
         "  p2.waitms(ms)\n" \
         "  return ms\n" \
         "end\n"

print("cap", p2.cog.capabilities()["spawn_source"], p2.cog.capabilities()["isolated_child_vm_cog"], p2.cog.capabilities()["berry_closure"])
p2.cog.task("source", source, "once", 38, 100)
