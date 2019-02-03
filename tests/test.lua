
local markup = require "src.markup"
local scan = require "src.scan"

-- local h = io.open("docs.md", "r")
-- local content = h:read("*a")
-- local parsed, topics
-- h:close()

local content = [[
```
code
```
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
h:write(markup.html.render(parsed, {
	loaders = {
		["rtype"] = function(text)
			return "Resource " .. text
		end
	},
	reference_link = function(ref)
		return "/" .. ref
	end
}))
h:close()
