#!/bin/bash
# Fetch AOSP clang r383902b (clang 11.0.2) - the toolchain the stock kernel was built with
# (CONFIG_CC_VERSION_TEXT). Usage: tina/get_toolchain.sh [dir]  (default ~/toolchains/clang-r383902b)
set -e
TC="${1:-$HOME/toolchains/clang-r383902b}"
mkdir -p "$TC"; cd "$TC"
if [ ! -x bin/clang ]; then
  curl -L --fail --retry 3 -o clang-r383902b.tar.gz \
    "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/android11-release/clang-r383902b.tar.gz"
  tar xzf clang-r383902b.tar.gz && rm -f clang-r383902b.tar.gz
fi
bin/clang --version | head -1
