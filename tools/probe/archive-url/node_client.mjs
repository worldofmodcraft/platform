// usage: node node_client.mjs URL  -> one JSON line
const url = process.argv[2];
try {
  const r = await fetch(url, { redirect: "follow" });
  const buf = Buffer.from(await r.arrayBuffer());
  const { createHash } = await import("node:crypto");
  console.log(JSON.stringify({ final: r.url, status: r.status, sha: createHash("sha256").update(buf).digest("hex"), error: "" }));
} catch (e) {
  console.log(JSON.stringify({ final: "", status: 0, sha: "", error: String(e) }));
}
