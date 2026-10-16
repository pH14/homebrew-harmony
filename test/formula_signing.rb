require "fileutils"
require "open3"
require "pathname"
require "tmpdir"

module OS
  def self.mac?
    true
  end
end

class Formula
  class << self
    [:desc, :homepage, :version, :license, :url, :sha256, :resource, :test].each do |method|
      define_method(method) { |*args, &block| }
    end

    def on_macos(&block)
      block.call
    end

    def on_arm(&block)
      block.call
    end

    def on_linux(&block)
    end
  end

  def initialize(prefix)
    @prefix = Pathname.new(prefix)
  end

  def prefix
    @prefix
  end

  def bin
    prefix/"bin"
  end

  def system(*args)
    raise "command failed: #{args.inspect}" unless Kernel.system(*args)
  end
end

def command(*args)
  stdout, stderr, status = Open3.capture3(*args)
  raise "command failed: #{args.inspect}\n#{stderr}" unless status.success?

  [stdout, stderr]
end

load File.expand_path("../Formula/harmony-cli.rb", __dir__)

Dir.mktmpdir("harmony-formula-signing-") do |directory|
  prefix = Pathname.new(directory)
  bin = prefix/"bin"
  bin.mkpath
  host = bin/"harmony-consonance-host"
  FileUtils.cp("/usr/bin/true", host)

  HarmonyCli.new(prefix).post_install
  command("codesign", "--verify", "--strict", host.to_s)
  _, details = command("codesign", "-dvvv", host.to_s)
  raise "wrong host identifier" unless details.include?("Identifier=org.harmony.consonance-host")
  raise "missing library constraint" unless details.include?("Has Library Load Constraints")

  flags = details[/flags=0x([0-9a-fA-F]+)/, 1]
  required_flags = 0x100 | 0x200 | 0x10000
  raise "missing hardened signing flags" unless flags && flags.to_i(16) & required_flags == required_flags

  entitlements, = command("codesign", "-d", "--entitlements", ":-", host.to_s)
  keys = entitlements.scan(/<key>([^<]+)<\/key>/).flatten
  raise "wrong host entitlements" unless keys == ["com.apple.security.hypervisor"]
  raise "missing Hypervisor entitlement" unless entitlements.match?(/<key>com\.apple\.security\.hypervisor<\/key>\s*<true\s*\/>/)

  constraint = (prefix/"harmony-consonance-host.library-constraint").read
  raise "wrong library constraint" unless constraint.match?(/<key>validation-category<\/key>\s*<integer>1<\/integer>/)
  command(host.to_s)
end
