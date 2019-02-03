
local markup = require "src.markup"
local scan = require "src.scan"

local h = io.open("docs/util.md", "r")
local content = h:read("*a")
local parsed, topics
h:close()

content = [[
{:date 4/2/19}
{:time 18:00-20:00}
]]

parsed = markup.parse(content)

markup.scan.text(parsed, function(node)
	print(node.data_type, node.data)
end, {
	filter = markup.filter.type(markup.DATA)
	       * markup.filter.property_equals("data_type", "date")
})

local h = io.open("out.html", "w")
h:write("<style> @import url('src/style.css'); </style>\n")
h:write("<style> @import url('tests/global-style.css'); </style>\n")
h:write(markup.html.render(parsed))
h:close()
