local core = require "core"

local source = core.parseSource("AngelJumbo/gruvbox-wallpapers/wallpapers")
eq(source.repo, "AngelJumbo/gruvbox-wallpapers", "source: repo")
eq(source.path, "wallpapers", "source: path")
eq(core.parseSource("Nix3l/gruvbox-bgs").path, "", "source: no path")
eq(core.parseSource("a/b/c/d e/").path, "c/d e", "source: deep path, trailing slash dropped")
eq(pcall(core.parseSource, "just-a-name"), false, "source: owner/repo is required")
eq(pcall(core.parseSource, 42), false, "source: must be a string")

local function upper(text) return text:upper() end
eq(core.contentsURL("a/b", "", upper), "https://api.github.com/repos/a/b/contents/", "url: root")
eq(core.contentsURL("a/b", "c d", upper), "https://api.github.com/repos/a/b/contents/C D", "url: path goes through the encoder")
eq(core.join("", "x"), "x", "join: from the root")
eq(core.join("a", "x"), "a/x", "join: nested")

local listing = {
    { type = "file", name = "one.PNG", download_url = "u1" },
    { type = "file", name = "_two.jpg", download_url = "u2" },
    { type = "file", name = "README.md", download_url = "u3" },
    { type = "file", name = "three.webp", download_url = "u4" },
    { type = "file", name = "big.heic", download_url = nil },
    { type = "dir", name = "anime" },
    { type = "dir", name = ".github" },
    { type = "symlink", name = "x.png", download_url = "u5" },
}
local images, dirs = core.split(listing)
eq(#images, 3, "split: images only, a file without a download url skipped")
eq(images[1].name, "one.PNG", "split: name kept")
eq(images[2].url, "u2", "split: url kept")
eq(#dirs, 1, "split: hidden dirs skipped")
eq(dirs[1], "anime", "split: dir name")
eq(#core.split({ message = "API rate limit exceeded" }), 0, "split: an error object is not a listing")

eq(core.key("_two.jpg"), "two.jpg", "key: leading underscore dropped")
eq(core.key("two.jpg"), "two.jpg", "key: plain")

local fresh = core.unseen(images, { ["two.jpg"] = true, ["three.webp"] = true })
eq(#fresh, 1, "unseen: seen keys removed")
eq(fresh[1].name, "one.PNG", "unseen: the rest kept")

local order = { 1, 2, 3, 4 }
local picks = { 1, 1, 1 }
core.shuffle(order, function() return table.remove(picks, 1) end)
eq(table.concat(order, ""), "2341", "shuffle: Fisher-Yates with the given random")

eq(table.concat(core.tail({ "a", "b", "c" }, 2), ""), "bc", "tail: last two")
eq(table.concat(core.tail({ "a" }, 2), ""), "a", "tail: shorter than the limit")

eq(core.fileName(1700000000, "Some Art.PNG"), "Fresh4kWallpaper-1700000000.png", "fileName: timestamp and lowercase extension")
eq(core.isOurs("Fresh4kWallpaper-1700000000.png"), true, "isOurs: our file")
eq(core.isOurs("holiday.png"), false, "isOurs: somebody's picture")
eq(core.isOurs("Fresh4kWallpaper-notes.txt"), false, "isOurs: only the exact shape")
eq(core.isOurs("history.log"), false, "isOurs: state file")

eq(core.is4k(3840, 2160), true, "4k: exactly")
eq(core.is4k(5120, 2880), true, "4k: larger")
eq(core.is4k(3840, 2159), false, "4k: too short")
eq(core.is4k(2560, 2160), false, "4k: too narrow")
eq(core.is4k(nil, nil), false, "4k: unreadable image")

local w, h = core.pixels("  pixelWidth: 3840\n  pixelHeight: 2160\n")
eq(w, 3840, "pixels: width"); eq(h, 2160, "pixels: height")
eq(core.pixels("Error 4: not an image"), nil, "pixels: no numbers")
