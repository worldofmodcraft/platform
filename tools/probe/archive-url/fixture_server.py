"""Throwaway loopback HTTP server for task 058.  Serves the same TARGET bytes behind each redirect mechanism.
Mutation hooks (verify script only): WOM058_MUTATE=status makes the 302/301 routes answer 200 without Location."""
import hashlib
import os
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

TARGET = b"WOM058-target-bytes\n" + bytes(range(256)) * 8  # binary-ish, deterministic
TARGET_SHA256 = hashlib.sha256(TARGET).hexdigest()
META = b'<!doctype html><meta charset="utf-8"><meta http-equiv="refresh" content="0; url=/target.bin"><link rel="canonical" href="/target.bin"><title>redirect</title>'
JS = b'<!doctype html><meta charset="utf-8"><script>location.replace("/target.bin")</script><title>redirect</title>'
MUTATE = os.environ.get("WOM058_MUTATE", "")


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *a):  # silence
        pass

    def _send(self, code, body=b"", ctype="text/plain", extra=()):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Connection", "close")
        for k, v in extra:
            self.send_header(k, v)
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)

    def do_GET(self):
        p = self.path
        if p == "/target.bin":
            return self._send(200, TARGET, "application/octet-stream")
        if p in ("/r302", "/r301"):
            if MUTATE == "status":
                return self._send(200, b"not a redirect", "text/plain")
            return self._send(302 if p == "/r302" else 301, b"", "text/plain", [("Location", "/target.bin")])
        if p == "/meta.html":
            return self._send(200, META, "text/html")
        if p == "/js.html":
            return self._send(200, JS, "text/html")
        if p == "/dir":  # directory without trailing slash: 301 to the slashed form (the shape a static host may use)
            return self._send(301, b"", "text/plain", [("Location", "/dir/")])
        if p == "/dir/":
            return self._send(200, TARGET, "application/octet-stream")
        if p == "/dl/ct-html.tar.gz":
            return self._send(200, TARGET, "text/html")
        if p == "/dl/ct-gzip.tar.gz":
            return self._send(200, TARGET, "application/gzip")
        if p == "/dl/cd.tar.gz":
            return self._send(200, TARGET, "application/gzip", [("Content-Disposition", 'attachment; filename="named-by-header.tar.gz"')])
        return self._send(404, b"nope")

    do_HEAD = do_GET


def start():
    srv = ThreadingHTTPServer(("127.0.0.1", 0), Handler)  # port 0 = kernel picks a free port
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    return srv
