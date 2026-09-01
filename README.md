# homebrew-harmony

Homebrew tap for [harmony](https://github.com/pH14/harmony), the deterministic
hypervisor testing tool.

```
brew tap ph14/harmony
brew install harmony-cli
harmony preflight
harmony oci run <image>
```

The formula installs a `harmony` binary plus the per-ISA guest artifacts
(kernel and initramfs) it boots. Supported hosts: Apple silicon macOS (HVF)
and Linux with `/dev/kvm` on x86-64 or arm64 — including GitHub-hosted
runners. `harmony preflight` reports exactly what the current host supports.

The formula tracks release assets of pH14/harmony; the sha256 pins are
updated by that repo's release workflow. Until the first release is
published, `brew install` will fail on the placeholder checksums.

Formula code is BSD-2-Clause (see LICENSE); harmony itself is
AGPL-3.0-or-later.
