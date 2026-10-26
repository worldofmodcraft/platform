#!/usr/bin/env python3
"""Deterministic generator for the three original screenshots of the test:hello-world canary mod (task 010a).

    python3 tools/test-mod/make_screenshots.py [--out DIR]     write welcome.png, gallery.png, spare.png into DIR
    python3 tools/test-mod/make_screenshots.py --check DIR     exit 0 only if DIR's PNGs decode to the same pixels

Everything is original abstract geometry (gradients, rings, tiles, stripes): no fonts, no scene, no game motif,
nothing derived from any game asset. The art uses integer arithmetic only (no trigonometry, no floats), so
the pixels are identical on every platform. The PNG writer pins: 8-bit RGB, filter type 1 (Sub) on every row,
zlib level 9, a single IDAT chunk, no ancillary chunks (so no timestamps), fixed 1280x720.

Determinism, stated precisely: two runs of this script produce byte-identical files *with the same zlib build*.
A different zlib build may compress the same pixels to different bytes, so the committed files are compared by
`raw_pixels_sha256` (sha256 of the decompressed, un-filtered pixel rows), never by file bytes.
Python standard library only (zlib, struct, hashlib).
"""

from __future__ import annotations

import argparse
import hashlib
import os
import struct
import sys
import zlib

WIDTH, HEIGHT = 1280, 720
NAMES = ("welcome", "gallery", "spare")
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
DEFAULT_OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
                           "docs", "test-mod", "hello-world", "assets", "screenshots")


def _lerp(a, b, t, tmax):
    return a + (b - a) * t // tmax


def _mix(c1, c2, t, tmax):
    return (_lerp(c1[0], c2[0], t, tmax), _lerp(c1[1], c2[1], t, tmax), _lerp(c1[2], c2[2], t, tmax))


def _welcome(x, y):
    """Diagonal teal-to-indigo gradient, concentric rings around a warm disc."""
    base = _mix((12, 74, 92), (46, 36, 110), x * HEIGHT + y * WIDTH, 2 * WIDTH * HEIGHT)
    dx, dy = x - 640, y - 360
    d2 = dx * dx + dy * dy
    if d2 < 110 * 110:
        return _mix((255, 214, 120), (240, 130, 90), d2, 110 * 110)
    ring = (d2 - 110 * 110) // 4000  # rings 4000 squared-pixels apart
    if d2 < 330 * 330 and ring % 3 == 0:
        return _mix(base, (210, 235, 240), 1, 3)
    return base


def _gallery(x, y):
    """A 3x2 grid of gradient tiles, each carrying one diamond, on a dark ground."""
    gx, gy = 40, 40
    tw, th = (WIDTH - 4 * gx) // 3, (HEIGHT - 3 * gy) // 2
    col, rem_x = divmod(x - gx, tw + gx)
    row, rem_y = divmod(y - gy, th + gy)
    if not (0 <= col < 3 and 0 <= row < 2 and 0 <= rem_x < tw and 0 <= rem_y < th and x >= gx and y >= gy):
        return (22, 24, 34)
    palettes = (((200, 80, 90), (250, 190, 100)), ((60, 150, 120), (170, 230, 150)), ((70, 100, 200), (160, 190, 250)),
                ((150, 70, 170), (240, 150, 200)), ((220, 140, 60), (250, 230, 130)), ((40, 130, 160), (130, 220, 230)))
    top, bottom = palettes[row * 3 + col]
    px = _mix(top, bottom, rem_y, th)
    if abs(rem_x - tw // 2) + abs(rem_y - th // 2) < 70:
        return _mix(px, (255, 255, 255), 2, 3)
    return px


def _spare(x, y):
    """Diagonal warm stripes of varying width over a cool vertical gradient."""
    base = _mix((20, 30, 60), (60, 90, 120), y, HEIGHT)
    s = (x + 2 * y) % 160
    if s < 40:
        return _mix((250, 170, 80), (230, 90, 110), (x + y) % 320, 320)
    if s < 52:
        return (245, 240, 225)
    return base


_RENDERERS = {"welcome": _welcome, "gallery": _gallery, "spare": _spare}


def render_rows(name):
    """Yield the pixel rows (bytes, 3 per pixel) of the named image."""
    fn = _RENDERERS[name]
    for y in range(HEIGHT):
        row = bytearray()
        for x in range(WIDTH):
            row.extend(fn(x, y))
        yield bytes(row)


def _sub_filter(row):
    prev = bytes(3) + row[:-3]
    return bytes([1]) + bytes((a - b) & 0xFF for a, b in zip(row, prev))


def _chunk(kind, data):
    body = kind + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)


def encode_png(rows):
    raw = b"".join(_sub_filter(r) for r in rows)
    ihdr = struct.pack(">IIBBBBB", WIDTH, HEIGHT, 8, 2, 0, 0, 0)
    return PNG_SIGNATURE + _chunk(b"IHDR", ihdr) + _chunk(b"IDAT", zlib.compress(raw, 9)) + _chunk(b"IEND", b"")


def generate_png(name):
    return encode_png(render_rows(name))


def _chunks(png):
    if png[:8] != PNG_SIGNATURE:
        raise ValueError("not a PNG: bad signature")
    pos, out = 8, []
    while pos < len(png):
        (length,) = struct.unpack(">I", png[pos:pos + 4])
        kind = png[pos + 4:pos + 8]
        out.append((kind, png[pos + 8:pos + 8 + length]))
        pos += 12 + length
    return out


def decode_pixels(png):
    """The un-filtered pixel bytes of an 8-bit RGB PNG made by this generator (any filter type 0-4)."""
    chunks = _chunks(png)
    ihdr = dict(chunks)[b"IHDR"]
    w, h, depth, ctype, _, _, interlace = struct.unpack(">IIBBBBB", ihdr)
    if (w, h, depth, ctype, interlace) != (WIDTH, HEIGHT, 8, 2, 0):
        raise ValueError(f"unexpected PNG header {(w, h, depth, ctype, interlace)}")
    raw = zlib.decompress(b"".join(d for k, d in chunks if k == b"IDAT"))
    stride = w * 3
    if len(raw) != h * (stride + 1):
        raise ValueError("IDAT length does not match the header")
    out, prev = bytearray(), bytes(stride)
    for y in range(h):
        base = y * (stride + 1)
        ft, line = raw[base], raw[base + 1:base + 1 + stride]
        cur = bytearray(stride)
        for i in range(stride):
            a = cur[i - 3] if i >= 3 else 0
            b = prev[i]
            c = prev[i - 3] if i >= 3 else 0
            if ft == 0:
                p = 0
            elif ft == 1:
                p = a
            elif ft == 2:
                p = b
            elif ft == 3:
                p = (a + b) // 2
            elif ft == 4:
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                p = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
            else:
                raise ValueError(f"bad filter type {ft}")
            cur[i] = (line[i] + p) & 0xFF
        out += cur
        prev = bytes(cur)
    return bytes(out)


def raw_pixels_sha256(png):
    return hashlib.sha256(decode_pixels(png)).hexdigest()


def expected_pixels_sha256(name):
    return hashlib.sha256(b"".join(render_rows(name))).hexdigest()


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--out", default=None, help="directory to write the three PNGs into (default: the staging tree)")
    g.add_argument("--check", metavar="DIR", help="compare DIR's PNGs with freshly rendered pixels; exit 1 on any difference")
    a = ap.parse_args(argv)
    if a.check:
        bad = 0
        for n in NAMES:
            path = os.path.join(a.check, n + ".png")
            try:
                with open(path, "rb") as f:
                    got = raw_pixels_sha256(f.read())
            except (OSError, ValueError, zlib.error) as exc:
                print(f"DIFFERENT {n}: cannot decode {path}: {exc}", file=sys.stderr)
                bad += 1
                continue
            want = expected_pixels_sha256(n)
            if got == want:
                print(f"same {n}.png pixels sha256 {got}")
            else:
                print(f"DIFFERENT {n}.png: pixels sha256 {got}, expected {want}", file=sys.stderr)
                bad += 1
        return 1 if bad else 0
    out = a.out or DEFAULT_OUT
    os.makedirs(out, exist_ok=True)
    for n in NAMES:
        data = generate_png(n)
        with open(os.path.join(out, n + ".png"), "wb") as f:
            f.write(data)
        print(f"wrote {os.path.join(out, n + '.png')} ({len(data)} bytes, pixels sha256 {raw_pixels_sha256(data)})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
