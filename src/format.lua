
local markup = require "src.markup"

require "src.parse"

local format = {}

local containerInlines = {
	[markup.LINK] = true,
	[markup.RELATIVE_LINK] = true,
	[markup.REFERENCE] = true,
	[markup.UNDERLINE] = true,
	[markup.BOLD] = true,
	[markup.ITALIC] = true,
	[markup.STRIKETHROUGH] = true
}

function format.headerID(header)
	if header.type ~= markup.HEADER then
		return nil
	end

	local content = ""
	local queue = {}

	local function addt(t)
		for i = 1, #t do
			table.insert(queue, i, t[i])
		end
	end

	addt(header.content)

	while queue[1] do
		local text = table.remove(queue, 1)

		if text.type == markup.TEXT then
			content = content .. text.content

		elseif text.type == markup.VARIABLE then
			content = content .. "$" .. text.variable

		elseif text.type == markup.CODE then
			content = content .. text.content

		elseif text.type == markup.UNDERLINE
			or text.type == markup.BOLD
			or text.type == markup.ITALIC
			or text.type == markup.STRIKETHROUGH
			or text.type == markup.LINK
			or text.type == markup.RELATIVE_LINK
			or text.type == markup.REFERENCE
		then
			addt(text.content)
		end
	end

	return content
			:gsub("<.->", "")
			:gsub("^%s+", "")
			:gsub("%s+$", "")
			:gsub("(%s)%s+", "%1")
			:gsub("[^%w%-%:%.%_%s]", "")
			:gsub("[^%w_]", "-")
			:lower()
end

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
