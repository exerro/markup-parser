
local parse = require "src.parse"

local debug = {}

function debug.printBlock(block)
	if block.type == parse.PARAGRAPH then
		return debug.printInlineList(block.content)

	elseif block.type == parse.HEADER then
		return ("#"):rep(block.size) .. " " .. debug.printInlineList(block.content)

	elseif block.type == parse.LIST then
		local s = {}

		for i = 1, #block.items do
			s[i] = ("\t"):rep(block.items[i].level) .. debug.printInlineList(block.items[i].content)
		end

		return table.concat(s, "\n")

	elseif block.type == parse.BLOCK_CODE then
		return "```" .. (block.language or "") .. "\n" .. block.content .. "\n```"

	elseif block.type == parse.BLOCK_QUOTE then
		return "> " .. debug.printBlocks(block.content):gsub("\n", "\n> ")

	elseif block.type == parse.RESOURCE then
		return "@" .. block.resource

	elseif block.type == parse.HORIZONTAL_RULE then
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
	if text.type == parse.TEXT then
		return text.content

	elseif text.type == parse.VARIABLE then
		return "$(" .. text.variable .. ")"

	elseif text.type == parse.CODE then
		return "`" .. text.content .. "`"

	elseif text.type == parse.UNDERLINE then
		return "__" .. debug.printInlineList(text.content) .. "__"

	elseif text.type == parse.BOLD then
		return "*" .. debug.printInlineList(text.content) .. "*"

	elseif text.type == parse.ITALIC then
		return "_" .. debug.printInlineList(text.content) .. "_"

	elseif text.type == parse.STRIKETHROUGH then
		return "~~" .. debug.printInlineList(text.content) .. "~~"

	elseif text.type == parse.IMAGE then
		return "![" .. text.alt_text .. "](" .. text.source .. ")"

	elseif text.type == parse.LINK then
		return "[" .. debug.printInlineList(text.content) .. "](" .. text.url .. ")"

	elseif text.type == parse.RELATIVE_LINK then
		return "[[" .. debug.printInlineList(text.content) .. "]](" .. text.url .. ")"

	elseif text.type == parse.REFERENCE then
		return "@(" .. debug.printInlineList(text.content) .. ")"

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
