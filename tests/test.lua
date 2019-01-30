
local parse = require "src.parse"
local markup = require "src.markup"
local html = require "src.html"

local h = io.open("docs.md", "r")
local content = h:read("*a")
local parsed, topics
h:close()

parsed = markup.parse(content)

local h = io.open("out.html", "w")
h:write("<style> @import 'src/style.css'; </style>")
h:write("<style> @import 'global-style.css'; </style>")
h:write(html.render(parsed))
h:close()
