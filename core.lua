-- Everything that needs no Hammerspoon: tested with plain `lua tests/run.lua`.
local core = {}

local PREFIX = "Fresh4kWallpaper-"
local IMAGE_EXTENSIONS = { png = true, jpg = true, jpeg = true, webp = true, heic = true }

local function extension(name)
    return (name:match("%.(%w+)$") or ""):lower()
end

function core.parseSource(source)
    if type(source) ~= "string" then error("a source is \"owner/repo\" or \"owner/repo/path\", got " .. type(source)) end
    local owner, repo, path = source:match("^([^/]+)/([^/]+)/?(.*)$")
    if not owner then error("a source is \"owner/repo\" or \"owner/repo/path\", got \"" .. source .. "\"") end
    return { repo = owner .. "/" .. repo, path = (path:gsub("/+$", "")) }
end

function core.contentsURL(repo, path, encode)
    return "https://api.github.com/repos/" .. repo .. "/contents/" .. encode(path)
end

function core.join(path, name)
    return path == "" and name or path .. "/" .. name
end

function core.split(listing)
    local images, dirs = {}, {}
    for _, item in ipairs(listing) do
        if item.type == "file" and item.download_url and IMAGE_EXTENSIONS[extension(item.name)] then
            images[#images + 1] = { name = item.name, url = item.download_url }
        elseif item.type == "dir" and item.name:sub(1, 1) ~= "." then
            dirs[#dirs + 1] = item.name
        end
    end
    return images, dirs
end

-- Some collections mark files with a leading underscore and later drop it;
-- history and the blocklist must recognise the picture either way.
function core.key(name)
    return (name:gsub("^_", ""))
end

function core.unseen(images, seen)
    local fresh = {}
    for _, image in ipairs(images) do
        if not seen[core.key(image.name)] then fresh[#fresh + 1] = image end
    end
    return fresh
end

function core.shuffle(list, random)
    for i = #list, 2, -1 do
        local j = random(i)
        list[i], list[j] = list[j], list[i]
    end
    return list
end

function core.tail(lines, limit)
    local kept = {}
    for i = math.max(1, #lines - limit + 1), #lines do kept[#kept + 1] = lines[i] end
    return kept
end

-- A new name every time: macOS caches the desktop picture by path and keeps
-- showing the old one when a file is replaced in place.
function core.fileName(time, name)
    return PREFIX .. time .. "." .. extension(name)
end

function core.isOurs(file)
    return file:match("^" .. PREFIX:gsub("%-", "%%-") .. "%d+%.%w+$") ~= nil
end

function core.is4k(width, height)
    return width ~= nil and height ~= nil and width >= 3840 and height >= 2160
end

function core.pixels(sipsOutput)
    local width = tonumber(sipsOutput:match("pixelWidth: (%d+)"))
    local height = tonumber(sipsOutput:match("pixelHeight: (%d+)"))
    if width and height then return width, height end
    return nil
end

return core
