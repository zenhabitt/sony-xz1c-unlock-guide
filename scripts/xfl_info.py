#!/usr/bin/env python3
"""xfl_info.py — 解析 Android boot 镜像 / SIN 文件的基本信息。

用法:
    python3 xfl_info.py boot.img
    python3 xfl_info.py kernel.sin

用来确认拿到的确实是 boot 镜像（ANDROID! 魔数、kernel/ramdisk 大小、page size）。
"""
import struct
import sys
import zlib


def parse_boot(d: bytes) -> None:
    if d[:8] != b"ANDROID!":
        print("not a raw boot image, magic =", d[:8])
        return
    kernel_size, kernel_addr, ramdisk_size, ramdisk_addr = struct.unpack_from("<IIII", d, 8)
    page_size = struct.unpack_from("<I", d, 36)[0]
    print(f"kernel_size  = {kernel_size} ({kernel_size/1024/1024:.2f} MiB)")
    print(f"kernel_addr  = 0x{kernel_addr:08x}")
    print(f"ramdisk_size = {ramdisk_size}")
    print(f"page_size    = {page_size}")
    kern = d[page_size:page_size + kernel_size]
    print("kernel head  =", kern[:4].hex())


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    path = sys.argv[1]
    data = open(path, "rb").read()
    print(f"file      : {path}")
    print(f"size      : {len(data)}")
    print(f"head(8)   : {data[:8]!r}")

    if data[:8] == b"ANDROID!":
        parse_boot(data)
        return

    # 可能是 gzip（SIN 的外壳），尝试解压
    if data[:2] == b"\x1f\x8b":
        print("gzip detected, trying to decompress ...")
        out = bytearray()
        try:
            dec = zlib.decompressobj(16 + zlib.MAX_WBITS)
            out += dec.decompress(data, 512 * 1024 * 1024)
            out += dec.flush()
        except zlib.error as e:
            print("partial decompress:", e)
        print(f"decompressed: {len(out)} bytes, head={bytes(out[:8])!r}")
        if out[:8] == b"ANDROID!":
            parse_boot(bytes(out))
        elif out[2560:2568] == b"ANDROID!":
            print("boot image found at offset 2560")
            parse_boot(bytes(out[2560:]))
    else:
        print("unknown container; check offset 0x000 / 0xA00 for 'ANDROID!'")
        if data[2560:2568] == b"ANDROID!":
            print("boot image found at offset 2560")
            parse_boot(data[2560:])


if __name__ == "__main__":
    main()
