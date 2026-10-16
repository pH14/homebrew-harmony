# Installs the `harmony` frontend, its Consonance host, and per-ISA guest artifacts from
# pH14/harmony release assets. The sha256 fields are filled in when the
# release publishing those assets goes out.
class HarmonyCli < Formula
  desc "Deterministic hypervisor testing: run OCI workloads bit-identically"
  homepage "https://github.com/pH14/harmony"
  version "0.1.0"
  license "AGPL-3.0-or-later"

  on_macos do
    depends_on macos: :sonoma

    on_arm do
      url "https://github.com/pH14/harmony/releases/download/v0.1.0/harmony-v0.1.0-aarch64-apple-darwin.tar.gz"
      sha256 "PLACEHOLDER_CLI_DARWIN_ARM64"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/pH14/harmony/releases/download/v0.1.0/harmony-v0.1.0-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "PLACEHOLDER_CLI_LINUX_X86_64"
    end
    on_arm do
      url "https://github.com/pH14/harmony/releases/download/v0.1.0/harmony-v0.1.0-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "PLACEHOLDER_CLI_LINUX_ARM64"
    end
  end

  resource "guest-arm64" do
    url "https://github.com/pH14/harmony/releases/download/v0.1.0/harmony-guest-v0.1.0-arm64.tar.gz"
    sha256 "PLACEHOLDER_GUEST_ARM64"
  end

  resource "guest-x86_64" do
    url "https://github.com/pH14/harmony/releases/download/v0.1.0/harmony-guest-v0.1.0-x86_64.tar.gz"
    sha256 "PLACEHOLDER_GUEST_X86_64"
  end

  def install
    bin.install "harmony", "harmony-consonance-host"
    # The CLI locates guest artifacts at <prefix>/share/harmony/guest/<isa>/
    # relative to its own executable path.
    guest = Hardware::CPU.arm? ? "guest-arm64" : "guest-x86_64"
    resource(guest).stage do
      (share/"harmony/guest").install Dir["*"]
    end
  end

  def post_install
    # The Consonance host checks its exact loaded signing policy before dispatch.
    # Sign after installation so the signature covers the installed executable.
    return unless OS.mac?

    entitlements = prefix/"harmony-consonance-host.entitlements"
    entitlements.write <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>com.apple.security.hypervisor</key>
          <true/>
      </dict>
      </plist>
    XML
    library_constraint = prefix/"harmony-consonance-host.library-constraint"
    library_constraint.write <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>validation-category</key>
          <integer>1</integer>
      </dict>
      </plist>
    XML
    system "codesign", "--force", "--sign", "-",
           "--identifier", "org.harmony.consonance-host",
           "--options", "runtime,hard,kill",
           "--entitlements", entitlements.to_s,
           "--library-constraint", library_constraint.to_s,
           (bin/"harmony-consonance-host").to_s
  end

  def caveats
    <<~EOS
      Run `harmony check --offline` from a project with harmony.toml to check runner admission.
      On Linux you need read-write access to /dev/kvm (kvm group).
    EOS
  end

  test do
    system (bin/"harmony").to_s, "--version"
    assert_predicate bin/"harmony-consonance-host", :executable?
    if OS.mac?
      system "codesign", "--verify", "--strict", (bin/"harmony-consonance-host").to_s
      system (bin/"harmony-consonance-host").to_s, "--version"
    end
  end
end
