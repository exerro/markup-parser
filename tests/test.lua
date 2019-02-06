
local markup = require "src.markup"

local h = io.open("docs/util.md", "r")
local content = h:read("*a")
local parsed, topics
h:close()

content = [[
A
{:date 4/2/19}
B
{:time 18:00-20:00}
C
]]

parsed = markup.parse(content)

parsed, changed = markup.update.replace(
	markup.update.text,
	parsed,
	markup.filter.has_data_type("date"),
	function(node)
		return markup.parse_text("Date: *" .. node.data .. "*")
	end
)

parsed, changed = markup.update.replace(
	markup.update.text,
	parsed,
	markup.filter.has_data_type("time"),
	function(node)
		return markup.parse_text("Time: ~~__" .. node.data .. "__~~")
	end
)

parsed, changed = markup.update.remove(
	markup.update.text,
	parsed,
	markup.filter.type(markup.TEXT) * markup.filter.property_contains("content", "C")
)

local h = io.open("out.html", "w")
h:write("<style> @import url('src/style.css'); </style>\n")
h:write("<style> @import url('tests/global-style.css'); </style>\n")
h:write(markup.html.render(parsed))
h:close()
