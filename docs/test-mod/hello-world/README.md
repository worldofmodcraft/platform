# Hello World

**Hello World** (`test:hello-world`) is the *permanent pipeline canary* of World of Modcraft.
It contains no code. It is published once, kept forever, and used to check that the whole
publishing chain still works: a git tag becomes a registry entry, a built and signed archive,
and a mod page.

![The welcome screenshot: concentric rings around a warm disc](assets/screenshots/welcome.png)

## What it proves

When this mod's page renders correctly, each of these held:

- the registry accepted a reserved-namespace entry from an authorised account;
- the pipeline fetched the exact commit, scanned every file and signed the archive;
- the site built the page from the archived source, not from the live web;
- this README was rendered as Markdown, including the table and code block below.

## The files

| File | Purpose |
| --- | --- |
| `mod.lua` | The manifest: a literal table, read but never executed |
| `README.md` | This page |
| `LICENSE` | MIT, so anyone may copy it |
| `assets/screenshots/` | Original abstract images made by a script |

## Reading the manifest

The manifest is plain data. Its first lines look like this:

```lua
return {
  id = "test:hello-world",
  name = "Hello World",
  version = "1.0.0",
}
```

## More

- The screenshots are generated, not drawn from any game: abstract shapes only.
- Read about the platform at [worldofmodcraft.com](https://worldofmodcraft.com).
- The page you are reading is the first thing a new mod author is shown, so it stays small on purpose.
