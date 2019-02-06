
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

parsed = markup.update.remove(
	markup.update.text,
	parsed,
	markup.filter.type(markup.DATA)
	/ (markup.filter.type(markup.TEXT)
	* -markup.filter.property_contains("content", "%S")),
	true
)

parsed = markup.update.remove(
	markup.update.document,
	parsed,
	markup.filter.type(markup.PARAGRAPH)
	* function(para)
		return #para.content == 0
	end,
	true
)

local h = io.open("out.html", "w")
h:write("<style> @import url('src/style.css'); </style>\n")
h:write("<style> @import url('tests/global-style.css'); </style>\n")
h:write(markup.html.render(parsed))
h:close()
