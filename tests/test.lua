
local markup = require "src.markup"
local html = require "src.html"
local format = require "src.format"
local parse = require "src.parse"
local scan = require "src.scan"

local h = io.open("docs.md", "r")
local content = h:read("*a")
local parsed, topics
h:close()

parsed = markup.parse(content)

parsed = scan.updateBlocks(parsed, function(node)
	-- print(format.inlinesToString(node.content))
end, {
	filter = function(node)
		return true
	end,
})

local h = io.open("out.html", "w")
h:write("<style> @import 'src/style.css'; </style>")
h:write("<style> @import 'global-style.css'; </style>")
h:write(html.render(parsed))
h:close()
