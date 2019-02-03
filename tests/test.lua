
local markup = require "src.markup"
local html = require "src.html"
local scan = require "src.scan"

-- local h = io.open("docs.md", "r")
-- local content = h:read("*a")
-- local parsed, topics
-- h:close()

local content = [[
hello there

@ref

# header
]]

parsed = markup.parse(content)

markup.scan.text(
	parsed,
	function(node)
		print(node.reference)
	end,
	{
		filter = markup.filter.type(markup.REFERENCE)
	}
)

local h = io.open("out.html", "w")
h:write("<style> @import url('src/style.css'); </style>\n")
h:write(html.render(parsed))
h:close()
