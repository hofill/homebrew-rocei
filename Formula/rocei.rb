class Rocei < Formula
  desc "Sign PDFs and files with the Romanian eID card, without IDPlugManager"
  homepage "https://github.com/hofill/rocei_cli"
  license "Unlicense"
  head "https://github.com/hofill/rocei_cli.git", branch: "main"

  depends_on "python@3.12"
  depends_on "swig" => :build

  def install
    system "make", "-C", "rocei_pkcs11"

    # Point the C CLI at the bundled venv's Python so PDF signing works
    # out of the box, with no manual `pip install` step required.
    venv_python = libexec/"venv/bin/python"
    inreplace "rocei_cli/src/main.c", '"python3"', "\"#{venv_python}\""

    system "make", "-C", "rocei_cli",
           "DEFAULT_SIGN_PY=#{libexec}/rocei_sign.py"

    bin.install "rocei_cli/rocei"
    lib.install "rocei_pkcs11/rocei_pkcs11.dylib"
    libexec.install "rocei_sign.py"
    (libexec/"rocei_pkcs11").mkpath
    ln_s lib/"rocei_pkcs11.dylib", libexec/"rocei_pkcs11/rocei_pkcs11.dylib"

    # Create an isolated venv and let pip resolve the full transitive
    # dep closure. We deliberately avoid `virtualenv_install_with_resources`
    # because it passes `--no-deps`, which would require declaring every
    # transitive PyPI dep (asn1crypto, cryptography, oscrypto, ...) as a
    # `resource` block. Direct pip install is the right trade-off for a tap.
    python = Formula["python@3.12"].opt_bin/"python3.12"
    system python, "-m", "venv", libexec/"venv"
    system libexec/"venv/bin/python", "-m", "pip", "install", "--quiet",
           "--disable-pip-version-check", "--no-input",
           "pyhanko[pkcs11]", "PyKCS11", "python-pkcs11"
  end

  def caveats
    <<~EOS
      If you see SCARD_E_SHARING_VIOLATION:
        sudo pkill -x ctkd ctkahp
    EOS
  end

  test do
    assert_predicate bin/"rocei", :exist?
    assert_predicate lib/"rocei_pkcs11.dylib", :exist?
    system libexec/"venv/bin/python", "-c",
           "import pyhanko, PyKCS11, pkcs11, asn1crypto, cryptography"
  end
end
