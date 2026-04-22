# Third-Party Policy

This repository keeps third-party toolchains out of source control.

Use one of these approaches instead:

- point `FLEXPROP_DIR` or `CATALINA_DIR` at an existing installation
- bootstrap a local cache under `.third_party_cache/`

That keeps the git history smaller and upstream Berry merges cleaner.
