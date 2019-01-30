
local markup = require "src.markup"

require "src.parse"

local format = {}

format.filters = {}

function format.filters.type(...)
	local types = {...}

	if #types == 1 then
		local type = types[1]
		
		return function(t)
			return t.type == type
		end
	end

	return function(t)
		for i = 1, #types do
			if t.type == types[i] then
				return true
			end
		end

		return false
	end
end

function format.filters.hasChildren()
	return function(t)
		return type(t.content) == "table"
	end
end

function format.filters.either(a, b)
	return function(...)
		return a(...) or b(...)
	end
end

function format.filters.both(a, b)
	return function(...)
		return a(...) and b(...)
	end
end

local containerInlines = {
	[markup.LINK] = true,
	[markup.RELATIVE_LINK] = true,
	[markup.REFERENCE] = true,
	[markup.UNDERLINE] = true,
	[markup.BOLD] = true,
	[markup.ITALIC] = true,
	[markup.STRIKETHROUGH] = true
}

function format.blockToString(block)
	if block.type == markup.PARAGRAPH then
		return format.inlinesToString(block.content)

	elseif block.type == markup.HEADER then
		return ("#"):rep(block.size) .. " " .. format.inlinesToString(block.content)

	elseif block.type == markup.LIST then
		local s = {}

		for i = 1, #block.items do
			s[i] = ("\t"):rep(block.items[i].level) .. format.inlinesToString(block.items[i].content)
		end

		return table.concat(s, "\n")

	elseif block.type == markup.BLOCK_CODE then
		return "```" .. (block.language or "") .. "\n" .. block.content .. "\n```"

	elseif block.type == markup.BLOCK_QUOTE then
		return "> " .. format.blocksToString(block.content):gsub("\n", "\n> ")

	elseif block.type == markup.RESOURCE then
		return "@" .. block.resource

	elseif block.type == markup.HORIZONTAL_RULE then
		return "---"

	end
end

function format.blocksToString(blocks)
	local s = {}

	for i = 1, #blocks do
		s[i] = format.blockToString(blocks[i])
	end

	return table.concat(s, "\n\n")
end

function format.inlineToString(text)
	if text.type == markup.TEXT then
		return text.content

	elseif text.type == markup.VARIABLE then
		return "$(" .. text.variable .. ")"

	elseif text.type == markup.CODE then
		return "`" .. text.content .. "`"

	elseif text.type == markup.UNDERLINE then
		return "__" .. format.inlinesToString(text.content) .. "__"

	elseif text.type == markup.BOLD then
		return "*" .. format.inlinesToString(text.content) .. "*"

	elseif text.type == markup.ITALIC then
		return "_" .. format.inlinesToString(text.content) .. "_"

	elseif text.type == markup.STRIKETHROUGH then
		return "~~" .. format.inlinesToString(text.content) .. "~~"

	elseif text.type == markup.IMAGE then
		return "![" .. text.alt_text .. "](" .. text.source .. ")"

	elseif text.type == markup.LINK then
		return "[" .. format.inlinesToString(text.content) .. "](" .. text.url .. ")"

	elseif text.type == markup.RELATIVE_LINK then
		return "[[" .. format.inlinesToString(text.content) .. "]](" .. text.url .. ")"

	elseif text.type == markup.REFERENCE then
		return "@(" .. format.inlinesToString(text.content) .. " :: " .. text.reference .. ")"

	end

end

function format.inlinesToString(text)
	local s = {}

	for i = 1, #text do
		s[i] = format.inlineToString(text[i])
	end

	return table.concat(s)
end

return format
