"""Task 058 client matrix + filename behaviour.  Loopback only.  Exit 0 iff every named check passes.
WOM058_MUTATE=status   (fixture) 302/301 answer 200
WOM058_MUTATE=sha      runner compares nothing (always 'equal')
WOM058_MUTATE=swallow  runner discards client errors"""
import hashlib, json, os, re, subprocess, sys, tempfile, urllib.error, urllib.request
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.dont_write_bytecode = True  # python3 -I ignores PYTHONDONTWRITEBYTECODE; a stale __pycache__ reddens 049/051/059
import fixture_server as fx

MUT = os.environ.get("WOM058_MUTATE", "")
srv = fx.start()
BASE = "http://127.0.0.1:%d" % srv.server_address[1]
tmp = tempfile.mkdtemp(prefix="wom058-")


def sha_eq(data):
    if MUT == "sha":
        return True
    return hashlib.sha256(data).hexdigest() == fx.TARGET_SHA256


def run(cmd, cwd=tmp):
    p = subprocess.run(cmd, capture_output=True, cwd=cwd, timeout=30)
    return p


def c_curl(url, follow):
    out = os.path.join(tmp, "o.bin")
    if os.path.exists(out): os.remove(out)
    cmd = ["curl", "-s", "-S", "-m", "10", "-o", out, "-w", "%{url_effective}|%{http_code}|%{redirect_url}", url]
    if follow: cmd.insert(1, "-L")
    p = run(cmd)
    parts = p.stdout.decode().split("|")
    data = open(out, "rb").read() if os.path.exists(out) else b""
    return dict(final=parts[0], status=int(parts[1] or 0), loc=parts[2] if len(parts) > 2 else "", eq=sha_eq(data), error=p.stderr.decode().strip())


def c_wget(url):
    out = os.path.join(tmp, "o.bin")
    if os.path.exists(out): os.remove(out)
    p = run(["wget", "-nv", "-S", "-T", "10", "-t", "1", "-O", out, url])
    err = p.stderr.decode()
    stat = re.findall(r"HTTP/1\.\d (\d+)", err)
    urls = re.findall(r"URL:(\S+)", err)
    data = open(out, "rb").read() if os.path.exists(out) else b""
    return dict(final=urls[-1] if urls else url, status=int(stat[-1]) if stat else 0, loc="", eq=sha_eq(data),
                error="" if p.returncode == 0 else "exit=%d" % p.returncode)


def c_py(url):
    try:
        with urllib.request.urlopen(url, timeout=10) as r:
            return dict(final=r.geturl(), status=r.status, loc="", eq=sha_eq(r.read()), error="")
    except urllib.error.HTTPError as e:
        return dict(final=e.geturl(), status=e.code, loc="", eq=False, error="HTTPError %d" % e.code)
    except Exception as e:
        return dict(final="", status=0, loc="", eq=False, error=repr(e))


def c_node(url):
    p = run(["node", os.path.join(HERE, "node_client.mjs"), url])
    j = json.loads(p.stdout.decode().strip().splitlines()[-1])
    return dict(final=j["final"], status=j["status"], loc="", eq=sha_eq_hex(j["sha"]), error=j["error"])


def sha_eq_hex(h):
    return True if MUT == "sha" else h == fx.TARGET_SHA256


CLIENTS = [("curl -L", lambda u: c_curl(u, True)), ("curl (no -L)", lambda u: c_curl(u, False)),
           ("wget", c_wget), ("python urllib", c_py), ("node fetch", c_node)]
ROUTES = [("302", "/r302"), ("301", "/r301"), ("meta-refresh", "/meta.html"), ("js-redirect", "/js.html"), ("dir-no-slash", "/dir")]

res = {}
print("which wget: %s" % (subprocess.run(["which", "wget"], capture_output=True).stdout.decode().strip() or "NOT INSTALLED"))
print("\n| mechanism | client | final URL | status | bytes == target SHA-256 | client error |\n|---|---|---|---|---|---|")
for rname, path in ROUTES:
    for cname, fn in CLIENTS:
        r = fn(BASE + path)
        if MUT == "swallow": r["error"] = ""
        res[(rname, cname)] = r
        print("| %s | %s | %s | %s | %s | %s |" % (rname, cname, r["final"].replace(BASE, "BASE"), r["status"], r["eq"], r["error"] or "-"))

FOLLOW = [c for c, _ in CLIENTS if c != "curl (no -L)"]
checks = []
def chk(name, ok, detail=""):
    checks.append((name, ok, detail)); print("%s %s %s" % ("PASS" if ok else "FAIL", name, detail))

print()
for rt in ("302", "301", "dir-no-slash"):
    for c in FOLLOW:
        r = res[(rt, c)]
        chk("C1 positive control %s / %s reaches target" % (rt, c), r["eq"] and r["status"] == 200 and r["final"].endswith(("/target.bin", "/dir/")), "final=%s status=%s" % (r["final"].replace(BASE, ""), r["status"]))
for rt, want in (("302", 302), ("301", 301), ("dir-no-slash", 301)):
    r = res[(rt, "curl (no -L)")]
    chk("C2 curl without -L stops at %d for %s with a Location" % (want, rt), r["status"] == want and bool(r["loc"]), "status=%s loc=%s" % (r["status"], r["loc"].replace(BASE, "")))
for rt in ("meta-refresh", "js-redirect"):
    for c, _ in CLIENTS:
        r = res[(rt, c)]
        chk("C3 %s is NOT followed by %s (bytes differ from target)" % (rt, c), not r["eq"] and r["status"] == 200 and r["final"].endswith((".html")), "final=%s" % r["final"].replace(BASE, ""))
for (rt, c), r in res.items():
    if rt in ("302", "301", "dir-no-slash") and c != "curl (no -L)":
        chk("C4 no client error on positive route %s / %s" % (rt, c), r["error"] == "", r["error"])
    if rt in ("meta-refresh", "js-redirect"):
        chk("C4 no client error on %s / %s" % (rt, c), r["error"] == "", r["error"])

import socket
_s = socket.socket(); _s.bind(("127.0.0.1", 0)); DEAD = "http://127.0.0.1:%d/x" % _s.getsockname()[1]; _s.close()  # a port that was free and is now closed
print("\n== Error control: connection refused at %s (every client must report an error)" % DEAD)
for cname, fn in CLIENTS:
    r = fn(DEAD)
    if MUT == "swallow": r["error"] = ""
    print("| %s | status=%s | error=%s |" % (cname, r["status"], r["error"] or "-"))
    chk("C6 %s reports an error for a refused connection" % cname, r["error"] != "", r["error"])

print("\n== Criterion 2: saved file names (no browser here; browsers need criterion 6)")
print("| route | Content-Type | client | saved name(s) | sha == target |\n|---|---|---|---|---|")
names = {}
for route, ctype in (("/dl/ct-html.tar.gz", "text/html"), ("/dl/ct-gzip.tar.gz", "application/gzip"), ("/dl/cd.tar.gz", "application/gzip + Content-Disposition filename=named-by-header.tar.gz")):
    for label, cmd in (("curl -O -J", ["curl", "-s", "-S", "-m", "10", "-O", "-J", BASE + route]),
                       ("wget", ["wget", "-nv", "-T", "10", "-t", "1", BASE + route]),
                       ("wget --content-disposition", ["wget", "-nv", "-T", "10", "-t", "1", "--content-disposition", BASE + route])):
        d = tempfile.mkdtemp(prefix="wom058-dl-")
        p = run(cmd, cwd=d)
        got = sorted(os.listdir(d))
        eq = [sha_eq(open(os.path.join(d, g), "rb").read()) for g in got]
        names[(route, label)] = got
        print("| %s | %s | %s | %s | %s |" % (route, ctype, label, ", ".join(got) or "(none; rc=%d %s)" % (p.returncode, p.stderr.decode().strip()), eq))
for route, expect in (("/dl/ct-html.tar.gz", "ct-html.tar.gz"), ("/dl/ct-gzip.tar.gz", "ct-gzip.tar.gz")):
    for label in ("curl -O -J", "wget"):
        chk("C5 %s saves %s as URL basename" % (label, route), names[(route, label)] == [expect], str(names[(route, label)]))
chk("C5 curl -O -J honours Content-Disposition", names[("/dl/cd.tar.gz", "curl -O -J")] == ["named-by-header.tar.gz"], str(names[("/dl/cd.tar.gz", "curl -O -J")]))
chk("C5 wget --content-disposition honours it", names[("/dl/cd.tar.gz", "wget --content-disposition")] == ["named-by-header.tar.gz"], str(names[("/dl/cd.tar.gz", "wget --content-disposition")]))
chk("C5 wget without the flag keeps URL basename", names[("/dl/cd.tar.gz", "wget")] == ["cd.tar.gz"], str(names[("/dl/cd.tar.gz", "wget")]))

bad = [n for n, ok, _ in checks if not ok]
print("\nRESULT: %d checks, %d failed" % (len(checks), len(bad)))
for n in bad: print("RED:", n)
srv.shutdown()
sys.exit(1 if bad else 0)
