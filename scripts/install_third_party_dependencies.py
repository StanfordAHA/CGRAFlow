import sys
import platform
from subprocess import call

def run(command):
    print(" ".join(command))
    call(command)


apt_packages = [
    "gcc-4.9",
    "g++-4.9",
    "verilator",
    "luajit",
    "build-essential",
    "clang",
    "libedit-dev",
    "libpng-dev",
    "csh",
    "libgmp3-dev",
    "git",
    "cmake",
    "zlib1g",
    "zlib1g-dev",
    "graphviz-dev",
    "python3",
    "swig2.0",
    "libcln-dev",
    "imagemagick",
    "python-virtualenv",
    "libxml2-dev",
    "libxslt-dev",
    "python3-dev"
]

brew_packages = []

is_linux_platform = sys.platform == "linux" or sys.platform == "linux2"
if is_linux_platform:
    linux_distribution = platform.linux_distribution()[0]
    if linux_distribution in {"Ubuntu", "debian"}:
        run(["sudo", "add-apt-repository", "-y", "ppa:ubuntu-toolchain-r/test"])
        run(["sudo", "apt-get", "update", "-y"])
        run(["sudo", "apt-get", "install", "-y"] + apt_packages)
    else:
        raise NotImplementedError(linux_distribution)
elif sys.platform == "darwin":
    run(["brew", "install"] + brew_packages)
elif sys.platform == "win32":
    raise NotImplementedError("Windows")
