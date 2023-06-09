class Jruby < Formula
  desc "Ruby implementation in pure Java"
  homepage "https://www.jruby.org/"
  url "https://search.maven.org/remotecontent?filepath=org/jruby/jruby-dist/9.4.2.0/jruby-dist-9.4.2.0-bin.tar.gz"
  sha256 "c2b065c5546d398343f86ddea68892bb4a4b4345e6c8875e964a97377733c3f1"
  license any_of: ["EPL-2.0", "GPL-2.0-only", "LGPL-2.1-only"]

  livecheck do
    url "https://www.jruby.org/download"
    regex(%r{href=.*?/jruby-dist[._-]v?(\d+(?:\.\d+)+)-bin\.t}i)
  end

  bottle do
    sha256 cellar: :any,                 arm64_ventura:  "f249618580493d1558bdebe2ba1d7d8eea6c16d457fe9af2bb90bb994f8dfc28"
    sha256 cellar: :any,                 arm64_monterey: "f249618580493d1558bdebe2ba1d7d8eea6c16d457fe9af2bb90bb994f8dfc28"
    sha256 cellar: :any,                 arm64_big_sur:  "94597932640a3705bddf074273d4f9eb8f44a9de337354ce69edbc5792115599"
    sha256 cellar: :any,                 ventura:        "5a86c336581d2efa53dbc6d6bfdab87388247724cd16cf8745a4534255ef311b"
    sha256 cellar: :any,                 monterey:       "5a86c336581d2efa53dbc6d6bfdab87388247724cd16cf8745a4534255ef311b"
    sha256 cellar: :any,                 big_sur:        "5a86c336581d2efa53dbc6d6bfdab87388247724cd16cf8745a4534255ef311b"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "2961231ee8820ecb96ac85208b26d3babd886f8d85115a870bc2f3eb228ee9fd"
  end

  depends_on "openjdk"

  def install
    # Remove Windows files
    rm Dir["bin/*.{bat,dll,exe}"]

    cd "bin" do
      # Prefix a 'j' on some commands to avoid clashing with other rubies
      %w[ast erb bundle bundler rake rdoc ri racc].each { |f| mv f, "j#{f}" }
      # Delete some unnecessary commands
      rm "gem" # gem is a wrapper script for jgem
      rm "irb" # irb is an identical copy of jirb
    end

    # Only keep the macOS native libraries
    rm_rf Dir["lib/jni/*"] - ["lib/jni/Darwin"]
    libexec.install Dir["*"]
    bin.install Dir["#{libexec}/bin/*"]
    bin.env_script_all_files libexec/"bin", Language::Java.overridable_java_home_env

    # Remove incompatible libfixposix library
    os = OS.kernel_name.downcase
    if OS.linux?
      arch = Hardware::CPU.intel? ? "x64" : Hardware::CPU.arch.to_s
    end
    libfixposix_binary = libexec/"lib/ruby/stdlib/libfixposix/binary"
    libfixposix_binary.children
                      .each { |dir| dir.rmtree if dir.basename.to_s != "#{arch}-#{os}" }

    # Replace (prebuilt!) universal binaries with their native slices
    # FIXME: Build libjffi-1.2.jnilib from source.
    deuniversalize_machos
  end

  test do
    assert_equal "hello\n", shell_output("#{bin}/jruby -e \"puts 'hello'\"")
  end
end
