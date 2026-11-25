#!/bin/bash
# Build the Huawei nova 9 Pro (TINA-AN00) kernel so that it is KMI-compatible with the stock
# HarmonyOS 4.3 firmware (stock vendor modules, vendor_boot and system stay untouched).
#
# Usage:   tina/build.sh [all|defconfig|<make target>]          (default: all)
# Env:     OUT=<dir>        output directory            (default: <repo>/out)
#          CLANG_DIR=<dir>  AOSP clang r383902b          (default: ~/toolchains/clang-r383902b,
#                                                          fetch it with tina/get_toolchain.sh)
#          JOBS=<n>         parallel jobs               (default: nproc)
#          SIZE_OPT=0       build -O2 instead of -Os    (the image will then be too big to boot!)
#
# Output:  $OUT/arch/arm64/boot/Image.gz  -> pack it into a boot.img with tina/tools/repack_boot.py
set -e
TINA="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$(dirname "$TINA")"
OUT="${OUT:-$SRC/out}"
CLANG_DIR="${CLANG_DIR:-$HOME/toolchains/clang-r383902b}"
JOBS="${JOBS:-$(nproc)}"
[ -x "$CLANG_DIR/bin/clang" ] || { echo "clang not found in $CLANG_DIR - run tina/get_toolchain.sh"; exit 1; }
export PATH="$CLANG_DIR/bin:$PATH"
# reproducible, anonymous build identity (otherwise user@host ends up in /proc/version)
export KBUILD_BUILD_USER="${KBUILD_BUILD_USER:-tina}" KBUILD_BUILD_HOST="${KBUILD_BUILD_HOST:-build}"
mkdir -p "$OUT"
LOG="$OUT/build.log"

# Symbol CRCs must equal the stock kernel's: compile with a wrapper that puts the stock kernel's
# own headers (kheaders) first, only for the genksyms preprocessing pass.
CC_KH="$(bash "$TINA/kh_overlay.sh" "$OUT/kh" "$CLANG_DIR")"

MAKE_ARGS=(
  -C "$SRC" O="$OUT" ARCH=arm64 -j"$JOBS" -k
  CC="$CC_KH" LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy
  OBJDUMP=llvm-objdump STRIP=llvm-strip READELF=llvm-readelf
  HOSTCC=gcc HOSTCXX=g++ CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-gnu-
  # Android build variables Huawei's Makefiles consult (retail = user build)
  TARGET_BUILD_VARIANT=user TARGET_PRODUCT=lahaina TARGET_BOARD_PLATFORM=lahaina
)

# Huawei's Makefiles reference their internal Android tree ($(srctree)/../../vendor/huawei/...
# and -Ivendor/huawei/... relative to $OUT). The release flattened those files into the kernel
# tree; recreate the expected layout with symlinks. NOTE: this creates vendor/huawei/ two levels
# above the repository.
make_vendor_shim() {
  local base="$1"
  mkdir -p "$base/vendor/huawei/kernel/kernel/sched" \
           "$base/vendor/huawei/chipset_common/plugins/kernel" \
           "$base/vendor/huawei/extra_qcom/kernel/drivers"
  ln -sfn "$SRC/kernel/sched/hw_rtg"    "$base/vendor/huawei/kernel/kernel/sched/hw_rtg"
  ln -sfn "$SRC/include/chipset_common" "$base/vendor/huawei/chipset_common/plugins/kernel/include"
  # the camera Makefile runs `find` on this dir, which does not descend a symlinked start point
  rm -rf "$base/vendor/huawei/extra_qcom/kernel/drivers/camera"
  cp -rs "$SRC/techpack/camera/drivers/cam_vendor" "$base/vendor/huawei/extra_qcom/kernel/drivers/camera"
  ln -sfn "$SRC/drivers/hwsensor"       "$base/vendor/huawei/extra_qcom/kernel/drivers/hwsensor"
}
make_vendor_shim "$(realpath "$SRC/../..")"
make_vendor_shim "$OUT"

clang --version | head -1 | tee "$LOG"
target="${1:-all}"
if [ "$target" = defconfig ] || [ ! -f "$OUT/.config" ]; then
  # .config = the stock kernel's own config (/proc/config.gz of the phone) ...
  cp -f "$TINA/configs/stock.config" "$OUT/.config"
  C="$SRC/scripts/config --file $OUT/.config"
  # ... with LTO + CFI as in the stock build (the published defconfig lacks them)
  $C -d LTO_NONE -e LTO_CLANG -e THINLTO -e CFI_CLANG -e CFI_CLANG_SHADOW -d CFI_PERMISSIVE
  $C -d RELR                     # stock had no RELR relocations
  # stock HW_MEMCHECK/MM_PAGE_TRACE are called DFX_MEMCHECK in this tree (gates zone_stat_item)
  $C -e DFX_MEMCHECK -d DFX_ZEROHUNG -d DFX_RAINBOW_TRACE -d DFX_RAINBOW_HIMNTN
  # with GOV_SCHEDUTIL_COMMON the scheduler reports load changes only through
  # sugov_check_freq_update(), whose flag reaches the governor only in this mode
  $C -e HW_CPU_FREQ_UNIFIED_UPDATE_FREQ
  # the bootloader refuses an Image whose image_size exceeds the stock one (~50.7 MiB);
  # HOS3 + LTO/CFI at -O2 is 51.1 MiB, at -Os 49.1 MiB. Codegen only, no KMI effect.
  [ "${SIZE_OPT:-1}" = 1 ] && $C -d CC_OPTIMIZE_FOR_PERFORMANCE -e CC_OPTIMIZE_FOR_SIZE
  make "${MAKE_ARGS[@]}" olddefconfig 2>&1 | tee -a "$LOG"
  [ "$target" = defconfig ] && exit 0
fi
# no dtbs: the device tree is not in the release; the stock DTB lives in vendor_boot (header v3)
[ "$target" = all ] && target="Image.gz modules"
set +e
make "${MAKE_ARGS[@]}" $target 2>&1 | tee -a "$LOG"
rc=${PIPESTATUS[0]}
echo "exit code $rc - kernel release $(cat "$OUT/include/config/kernel.release" 2>/dev/null)" | tee -a "$LOG"
[ -f "$OUT/arch/arm64/boot/Image.gz" ] && ls -l "$OUT/arch/arm64/boot/Image.gz"
exit $rc
