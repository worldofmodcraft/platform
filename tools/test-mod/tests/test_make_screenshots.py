"""Tests for tools/test-mod/make_screenshots.py (task 010a). Run: python3 -m unittest discover -s tools/test-mod/tests -t tools/test-mod/tests"""
import hashlib
import importlib.util
import os
import struct
import tempfile
import unittest
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
SHOTS = os.path.join(ROOT, "docs", "test-mod", "hello-world", "assets", "screenshots")


def _load():
    spec = importlib.util.spec_from_file_location("make_screenshots", os.path.join(os.path.dirname(HERE), "make_screenshots.py"))
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


ms = _load()


class GeneratorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.first = {n: ms.generate_png(n) for n in ms.NAMES}

    def test_same_run_double_generation_is_byte_identical(self):
        for n in ms.NAMES:
            self.assertEqual(self.first[n], ms.generate_png(n), n)

    def test_png_structure(self):
        for n, png in self.first.items():
            self.assertEqual(png[:8], b"\x89PNG\r\n\x1a\n")
            kinds = [k for k, _ in ms._chunks(png)]
            self.assertEqual(kinds, [b"IHDR", b"IDAT", b"IEND"], n)
            self.assertTrue(png.endswith(b"\x00\x00\x00\x00IEND\xaeB`\x82"), n)
            w, h = struct.unpack(">II", png[16:24])
            self.assertEqual((w, h), (1280, 720))

    def test_decoded_pixels_equal_rendered_pixels(self):
        for n, png in self.first.items():
            self.assertEqual(ms.raw_pixels_sha256(png), ms.expected_pixels_sha256(n), n)

    def test_the_three_images_differ(self):
        self.assertEqual(len({ms.raw_pixels_sha256(p) for p in self.first.values()}), 3)

    def test_committed_pngs_decode_to_the_generated_pixels(self):
        for n in ms.NAMES:
            with open(os.path.join(SHOTS, n + ".png"), "rb") as f:
                self.assertEqual(ms.raw_pixels_sha256(f.read()), ms.expected_pixels_sha256(n), n)

    def test_check_mode_exit_codes(self):
        self.assertEqual(ms.main(["--check", SHOTS]), 0)
        with tempfile.TemporaryDirectory() as d:
            for n in ms.NAMES:
                with open(os.path.join(SHOTS, n + ".png"), "rb") as f:
                    data = f.read()
                if n == "gallery":  # a different (valid) image under the gallery name must be caught
                    data = self.first["spare"]
                with open(os.path.join(d, n + ".png"), "wb") as f:
                    f.write(data)
            self.assertEqual(ms.main(["--check", d]), 1)
            os.unlink(os.path.join(d, "welcome.png"))
            self.assertEqual(ms.main(["--check", d]), 1)

    def test_pixel_comparison_ignores_compression_level(self):
        # Same pixels, different zlib level => different file bytes, same raw-pixel hash (why the spec compares pixels).
        png = self.first["gallery"]
        chunks = ms._chunks(png)
        idat = dict(chunks)[b"IDAT"]
        recompressed = ms.PNG_SIGNATURE + ms._chunk(b"IHDR", dict(chunks)[b"IHDR"]) + \
            ms._chunk(b"IDAT", zlib.compress(zlib.decompress(idat), 1)) + ms._chunk(b"IEND", b"")
        self.assertNotEqual(recompressed, png)
        self.assertEqual(ms.raw_pixels_sha256(recompressed), ms.raw_pixels_sha256(png))


if __name__ == "__main__":
    unittest.main()
