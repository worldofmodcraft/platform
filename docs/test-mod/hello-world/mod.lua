-- test:hello-world -- the permanent pipeline canary of World of Modcraft.
-- A literal table only: this file is read, never executed (no calls, no concatenation).
return {
  id = "test:hello-world",
  name = "Hello World",
  version = "1.0.0",
  api_version = "1.0",
  license = "MIT",
  source = "https://github.com/OWNER-PLACEHOLDER/wom-test-hello-world",
  type = "mod",
  description = "A mod with no code. It exists to prove the publishing pipeline, from a git tag to a signed archive and a page, works end to end.",
  tags = { "test", "canary", "example" },
  screenshots = {
    "assets/screenshots/welcome.png",
    "assets/screenshots/gallery.png",
  },
  ai_assisted = true,
}
