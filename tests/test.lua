
local markup = require "src.markup"
local scan = require "src.scan"

local h = io.open("docs/util.md", "r")
local content = h:read("*a")
local parsed, topics
h:close()

parsed = markup.parse(content)

local h = io.open("out.html", "w")
h:write("<style> @import url('src/style.css'); </style>\n")
h:write("<style> @import url('tests/global-style.css'); </style>\n")
h:write(markup.html.render(parsed))
h:close()
