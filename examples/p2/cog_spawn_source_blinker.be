# Source-backed P2 cog blinker example.
# This path is experimental. It reports the capability state before attempting
# source-backed cog launch, because normal builds only guarantee the native
# closure blinker shape.

import p2

var caps = p2.cog.capabilities()
print("spawn_source supported", caps["spawn_source"])

if !caps["spawn_source"]
    print("source-backed cog spawning is not supported on this build")
else
    var source = "import p2\n" +
             "def blinker(pin, ms)\n" +
             "  p2.pin.dir_high(pin)\n" +
             "  while true\n" +
             "    p2.pin.toggle(pin)\n" +
             "    p2.clock.waitms(ms)\n" +
             "  end\n" +
             "end\n"

    var h38 = p2.cog.spawn_source(source, "blinker", 38, 250)
    var h39 = p2.cog.spawn_source(source, "blinker", 39, 700)

    print("handles", h38, h39)
    p2.clock.waitms(750)
    print("stop h38", p2.cog.stop(h38)["running"])
    print("stop h39", p2.cog.stop(h39)["running"])
    p2.pin.float(38)
    p2.pin.float(39)
end
print("p2 source blinker done")
