
local parse = require "src.parse"
local debug = require "src.debug"
local markup = require "src.markup"
local html = require "src.html"

local h = io.open("docs.md", "r")
local content = h:read("*a")
local parsed, topics
h:close()

parsed = markup.parse(content)

local h = io.open("out.html", "w")
h:write(html.render(parsed, {"src/style.css", "global-style.css"}))
h:close()
