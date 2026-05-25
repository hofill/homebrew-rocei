class Rocei < Formula
  desc "Sign PDFs and files with the Romanian eID card, without IDPlugManager"
  homepage "https://github.com/hofill/rocei_cli"
  license "Unlicense"
  head "https://github.com/hofill/rocei_cli.git", branch: "main"

  def install
    system "make", "-C", "rocei_pkcs11"
    system "make", "-C", "rocei_cli",
           "DEFAULT_SIGN_PY=#{libexec}/rocei_sign.py"
    bin.install "rocei_cli/rocei"
    lib.install "rocei_pkcs11/rocei_pkcs11.dylib"
    libexec.install "rocei_sign.py"
    libexec.install "requirements.txt"
    (libexec/"rocei_pkcs11").mkpath
    ln_s lib/"rocei_pkcs11.dylib", libexec/"rocei_pkcs11/rocei_pkcs11.dylib"
  end

  def caveats
    <<~EOS
      For PDF signing, install the Python dependencies:
        pip install -r #{libexec}/requirements.txt

      If you see SCARD_E_SHARING_VIOLATION:
        sudo pkill -x ctkd ctkahp
    EOS
  end

  test do
    assert_predicate bin/"rocei", :exist?
    assert_predicate lib/"rocei_pkcs11.dylib", :exist?
  end
end
