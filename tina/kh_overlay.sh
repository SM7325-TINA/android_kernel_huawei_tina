#!/bin/bash
# kh_overlay.sh <dir> <clang dir>
# Build the "stock headers first" overlay + compiler wrapper in <dir>, print the wrapper path.
#   overlay: tina/kmi/stock_kheaders.tar.xz = /sys/kernel/kheaders.tar.xz of the stock kernel (the
#            headers it was really built with), minus include/config and minus the headers listed
#            in tina/kmi/kh_drop.txt (those fall back to the source tree).
#   wrapper: clang that adds -I<overlay> ONLY for the genksyms pass (-D__GENKSYMS__), so symbol
#            CRCs are computed from the stock type text while code is compiled with our headers.
set -e
D="$1"; CLANG_DIR="$2"
TINA="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OV="$D/overlay"
rm -rf "$D"; mkdir -p "$D/stock" "$OV"
tar xJf "$TINA/kmi/stock_kheaders.tar.xz" -C "$D/stock"
cp -a "$D/stock/include" "$D/stock/arch" "$OV/"
rm -rf "$OV/include/config"
while read -r h; do
  h="${h%%#*}"; h="$(echo "$h" | xargs)"; [ -z "$h" ] && continue
  rm -rf "${OV:?}/$h"
done < "$TINA/kmi/kh_drop.txt"
# (the stock include/generated/autoconf.h inside the overlay already carries the stock config)
cat > "$D/cc-kh" <<EOF
#!/bin/bash
for a in "\$@"; do
  if [ "\$a" = "-D__GENKSYMS__" ]; then
    # __sched: stock pagemap.h no longer pulls in linux/sched/debug.h - define it identically
    exec "$CLANG_DIR/bin/clang" -I$OV/arch/arm64/include -I$OV/include \\
      -I$OV/arch/arm64/include/uapi -I$OV/include/uapi -I$OV/include/generated/uapi \\
      '-D__sched=__attribute__((__section__(".sched.text")))' "\$@"
  fi
done
exec "$CLANG_DIR/bin/clang" "\$@"
EOF
chmod +x "$D/cc-kh"
echo "$D/cc-kh"
