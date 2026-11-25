#!/usr/bin/env python3
"""Repack stock boot.img (header v3): keep header page + ramdisk, swap in a new kernel.
usage: python repack_boot.py <stock boot.img> <Image.gz> <out.img> [extra cmdline]
v3: fixed 4096 page, no load addresses -> only kernel_size (offset 8) changes.
v3 header: cmdline[1536] at offset 44 (appended by the bootloader to vendor_boot's cmdline)."""
import hashlib, struct, sys

stock, newk, out = sys.argv[1:4]
extra = sys.argv[4] if len(sys.argv) > 4 else ""
PAGE = 4096
rup = lambda n: (n + PAGE - 1) // PAGE * PAGE
data = open(stock, "rb").read()
assert data[:8] == b"ANDROID!", "not an android boot image"
ksz, rsz = struct.unpack_from("<II", data, 8)
assert struct.unpack_from("<I", data, 40)[0] == 3, "expected header v3"
ramdisk = data[PAGE + rup(ksz):PAGE + rup(ksz) + rsz]
assert len(ramdisk) == rsz
kernel = open(newk, "rb").read()
assert kernel[:2] == b"\x1f\x8b", "expected gzip Image.gz like stock"
hdr = bytearray(data[:PAGE]); struct.pack_into("<I", hdr, 8, len(kernel))
if extra:
    cur = bytes(hdr[44:44 + 1536]).split(b"\0")[0].decode()
    cmd = (cur + " " + extra).strip().encode()
    assert len(cmd) < 1536
    hdr[44:44 + 1536] = cmd + b"\0" * (1536 - len(cmd))
    print("cmdline:", cmd.decode())
blob = bytes(hdr) + kernel + b"\0" * (rup(len(kernel)) - len(kernel)) + ramdisk + b"\0" * (rup(rsz) - rsz)
open(out, "wb").write(blob)
print(f"kernel {ksz} -> {len(kernel)}, ramdisk {rsz} kept, out {len(blob)} bytes")
print("sha256", hashlib.sha256(blob).hexdigest())
