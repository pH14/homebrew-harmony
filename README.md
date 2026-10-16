# homebrew-harmony

Homebrew tap for [harmony](https://github.com/pH14/harmony), the deterministic
hypervisor testing tool.

```
brew tap ph14/harmony
brew install harmony-cli
harmony --version
# In a project with harmony.toml:
harmony check --offline
harmony search --name baseline --for 10m
```

The formula installs the `harmony` frontend, its paired
`harmony-consonance-host`, and the per-ISA guest artifacts (kernel and
initramfs) it boots. The macOS host is signed after installation with the
Hypervisor entitlement, hardened runtime, and OS-only library constraint.
The Linux host is a static executable that the frontend seals before launching.
Supported hosts: Apple silicon macOS 14 or later (HVF) and Linux with
`/dev/kvm` on x86-64 or arm64 — including GitHub-hosted runners. In a
configured project, `harmony check --offline` reports runner admission.

The formula tracks release assets of pH14/harmony; the sha256 pins are
updated by that repo's release workflow. Until the first release is
published, `brew install` will fail on the placeholder checksums.

Formula code is BSD-2-Clause (see LICENSE); harmony itself is
AGPL-3.0-or-later.
