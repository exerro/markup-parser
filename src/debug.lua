
local markup = require "src.markup"

local debug = {}

function debug.printBlock(block)
	if block.type == markup.PARAGRAPH then
		return debug.printInlineList(block.content)

	elseif block.type == markup.HEADER then
		return ("#"):rep(block.size) .. " " .. debug.printInlineList(block.content)

	elseif block.type == markup.LIST then
		local s = {}

		for i = 1, #block.items do
			s[i] = ("\t"):rep(block.items[i].level) .. debug.printInlineList(block.items[i].content)
		end

		return table.concat(s, "\n")

	elseif block.type == markup.BLOCK_CODE then
		return "```" .. (block.language or "") .. "\n" .. block.content .. "\n```"

	elseif block.type == markup.BLOCK_QUOTE then
		return "> " .. debug.printBlocks(block.content):gsub("\n", "\n> ")

	elseif block.type == markup.RESOURCE then
		return "@" .. block.resource

	elseif block.type == markup.HORIZONTAL_RULE then
		return "---"

	end
end

function debug.printBlocks(blocks)
	local s = {}

	for i = 1, #blocks do
		s[i] = debug.printBlock(blocks[i])
	end

	return table.concat(s, "\n\n")
end

function debug.printInline(text)
	if text.type == markup.TEXT then
		return text.content

	elseif text.type == markup.VARIABLE then
		return "$(" .. text.variable .. ")"

	elseif text.type == markup.CODE then
		return "`" .. text.content .. "`"

	elseif text.type == markup.UNDERLINE then
		return "__" .. debug.printInlineList(text.content) .. "__"

	elseif text.type == markup.BOLD then
		return "*" .. debug.printInlineList(text.content) .. "*"

	elseif text.type == markup.ITALIC then
		return "_" .. debug.printInlineList(text.content) .. "_"

	elseif text.type == markup.STRIKETHROUGH then
		return "~~" .. debug.printInlineList(text.content) .. "~~"

	elseif text.type == markup.IMAGE then
		return "![" .. text.alt_text .. "](" .. text.source .. ")"

	elseif text.type == markup.LINK then
		return "[" .. debug.printInlineList(text.content) .. "](" .. text.url .. ")"

	elseif text.type == markup.RELATIVE_LINK then
		return "[[" .. debug.printInlineList(text.content) .. "]](" .. text.url .. ")"

	elseif text.type == markup.REFERENCE then
		return "@(" .. debug.printInlineList(text.content) .. " :: " .. text.reference .. ")"

	end

end

function debug.printInlineList(text)
	local s = {}

	for i = 1, #text do
		s[i] = debug.printInline(text[i])
	end

	return table.concat(s)
end

return debug
