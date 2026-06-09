# Source-backed P2 cog blinker example.
# This path runs real Berry source in an isolated child VM on another cog and
# returns the same kind of p2.cog handle that can be stopped later.

import p2

source = "import p2\n" \
         "def blinker(pin, ms)\n" \
         "  p2.low(pin)\n" \
         "  while true\n" \
         "    p2.toggle(pin)\n" \
         "    p2.waitms(ms)\n" \
         "  end\n" \
         "end\n"

h38 = p2.cog.spawn_source(source, "blinker", 38, 250)
h39 = p2.cog.spawn_source(source, "blinker", 39, 700)

print("handles", h38, h39)
print("info", p2.cog.info())
print("stop later with:")
print("p2.cog.stop(h38); p2.cog.stop(h39)")
