import sys, urllib.request, urllib.error, hashlib
B=sys.argv[1]
for p in sys.argv[2:]:
    try:
        r=urllib.request.urlopen(B+p); b=r.read(); print("py", p, "final=",r.geturl(), "status=",r.status, "ctype=",r.headers.get("content-type"), "sha16=",hashlib.sha256(b).hexdigest()[:16])
    except urllib.error.HTTPError as e:
        b=e.read(); print("py", p, "HTTPError", e.code, "final=",e.geturl(), "sha16=",hashlib.sha256(b).hexdigest()[:16])
