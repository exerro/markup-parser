
local parse = require "src.parse"

--[[
		{
			type = parse.UNDERLINE,
			content = inline-text
		}

		{
			type = parse.BOLD,
			content = inline-text
		}

		{
			type = parse.ITALIC,
			content = inline-text
		}

		{
			type = parse.STRIKETHROUGH,
			content = inline-text
		}

		{
			type = parse.RELATIVE_LINK,
			content = inline-text,            ; this is the text to display
			url = U                           ; U is the string url target of the link
		}

		{
			type = parse.REFERENCE,
			content = inline-text             ; this is the text to display
			target = T                        ; T is the string reference target
		}
]]

local html = {}
local highlighters = {}
local resourceLoader
local relativeLinkFormatter
local referenceFormatter

-- configurable
html.CLASS_PREFIX = "md-"

-- css classes, note that "~" is replaced with `html.CLASS_PREFIX`
html.FORMAT_ERROR = "~format-error"

html.PARAGRAPH = "~para"
html.HEADER = "~header"
html.LIST = "~list"
html.LIST_ITEM = "~list-item"
html.BLOCK_CODE = "~block-code"
html.BLOCK_QUOTE = "~block-quote"
html.HORIZONTAL_RULE = "~hr"

html.TEXT = "~text"
html.VARIABLE = "~variable"
html.CODE = "~code"
html.UNDERLINE = "~underline"
html.BOLD = "~bold"
html.ITALIC = "~italic"
html.STRIKETHROUGH = "~strikethrough"
html.IMAGE = "~image"
html.LINK = "~link"
html.REFERENCE = "~reference"

local getClass
local map, flatMap, get, indent

function html.blocksToHTML(blocks)
	return table.concat(map(html.blockToHTML, blocks), "\n\n")
end

function html.blockToHTML(block)

	if block.type == parse.PARAGRAPH then
		return "<p class=\"" .. getClass(html.PARAGRAPH) .. "\">\n"
		.. indent(html.inlinesToHTML(block.content))
		.. "\n</p>"

	elseif block.type == parse.HEADER then
		return "<h" .. block.size .. " class=\"" .. getClass(html.HEADER) .. " " .. getClass(html.HEADER) .. block.size .. "\">\n"
		.. indent(html.inlinesToHTML(block.content))
		.. "\n</h" .. block.size .. ">"

	elseif block.type == parse.LIST then
		return "<ul class=\"" .. getClass(html.LIST) .. "\">\n"
		.. table.concat(map(html.listItemToHTML, block.items), "\n")
		.. "\n</ul>"

	elseif block.type == parse.BLOCK_CODE then
		local lang = block.language:lower()
		local content = block.content

		if highlighters[lang] then
			content = tostring(highlighters[lang])
		end

		-- TODO: maybe have some kind of box around the code? an indication of language? idk
		return "<p class=\"" .. getClass(html.BLOCK_CODE) .. "\"><pre>\n"
		.. content
		.. "\n</pre></p>"

	elseif block.type == parse.BLOCK_QUOTE then
		return "<div class=\"" .. getClass(html.BLOCK_QUOTE) .. "\">\n"
		.. html.blocksToHTML(block.content)
		.. "\n</div>"

	elseif block.type == parse.RESOURCE then
		if resourceLoader then
			return tostring(resourceLoader(block.resource))
		else
			return "<p class=\"" .. getClass(html.FORMAT_ERROR) .. "\"> No resource loader for '" .. block.resource .. "' :( </p>"
		end

	elseif block.type == parse.HORIZONTAL_RULE then
		return "<hr class=\"" .. getClass(html.HORIZONTAL_RULE) .. "\">"

	else
		return error("internal markup error: unknown block type (" .. tostring(block.type) .. ")")

	end
end

function html.listItemToHTML(li)
	--  TODO: use li.level
	return "<li class=\"" .. getClass(html.LIST_ITEM) .. "\">\n"
	.. html.inlinesToHTML(li.content)
	.. "\n</li>"
end

function html.inlinesToHTML(inlines)
	return table.concat(map(html.inlineToHTML, inlines))
end

function html.inlineToHTML(inline)
	if inline.type == parse.TEXT then
		return "<span class=\"" .. getClass(html.TEXT) .. "\"> " .. inline.content .. " </span>"

	elseif inline.type == parse.VARIABLE then
		return "<span class=\"" .. getClass(html.VARIABLE) .. "\"> " .. inline.variable .. " </span>"

	elseif inline.type == parse.CODE then
		return "<pre class=\"" .. getClass(html.CODE) .. "\"> " .. inline.content .. " </pre>"

	elseif inline.type == parse.UNDERLINE then
		return "<u class=\"" .. getClass(html.STRIKETHROUGH) .. "\"> "
		.. html.inlinesToHTML(inline.content)
		.. " </u>"

	elseif inline.type == parse.BOLD then
		return "<strong class=\"" .. getClass(html.STRIKETHROUGH) .. "\"> "
		.. html.inlinesToHTML(inline.content)
		.. " </strong>"

	elseif inline.type == parse.ITALIC then
		return "<i class=\"" .. getClass(html.STRIKETHROUGH) .. "\"> "
		.. html.inlinesToHTML(inline.content)
		.. " </i>"

	elseif inline.type == parse.STRIKETHROUGH then
		return "<del class=\"" .. getClass(html.STRIKETHROUGH) .. "\"> "
		.. html.inlinesToHTML(inline.content)
		.. " </del>"

	elseif inline.type == parse.IMAGE then
		return "<img class=\"" .. getClass(html.IMAGE) .. "\" alt=\"" .. inline.alt_text .. "\" src=\"" .. inline.source .. "\">"

	elseif inline.type == parse.LINK then
		return "<a class=\"" .. getClass(html.LINK) .. "\" href=\"" .. inline.url .. "\"> " .. html.inlinesToHTML(inline.content) .. " </a>"

	elseif inline.type == parse.RELATIVE_LINK then
		if relativeLinkFormatter then
			return "<a class=\"" .. getClass(html.LINK) .. "\" href=\"" .. relativeLinkFormatter(inline.url) .. "\"> " .. inline.content .. " </a>"
		else
			return "<p class=\"" .. getClass(html.FORMAT_ERROR) .. "\"> No relative link formatter for '" .. inline.url .. "' :( </p>"
		end

	elseif inline.type == parse.REFERENCE then
		if referenceFormatter then
			return "<a class=\"" .. getClass(html.LINK) .. "\" href=\"" .. referenceFormatter(inline.reference) .. "\"> " .. inline.content .. " </a>"
		else
			return "<p class=\"" .. getClass(html.FORMAT_ERROR) .. "\"> No reference formatter for '" .. inline.reference .. "' :( </p>"
		end

	end
end

function html.setSyntaxHighligher(language, highlighter)
	highlighters[language:lower()] = highlighter
end

function html.setResourceLoader(loader)
	resourceLoader = loader
end

function html.setRelativeLinkFormatter(formatter)
	relativeLinkFormatter = formatter
end

function html.setReferenceFormatter(formatter)
	referenceFormatter = formatter
end


function getClass(s)
	return s:gsub("~", html.CLASS_PREFIX)
end

function map(f, list)
	local result = {}

	for i = 1, #list do
		result[i] = f(list[i])
	end

	return result
end

function flatMap(f, list)
	local result = {}

	for i = 1, #list do
		local r = f(list[i])

		for j = 1, #r do
			insert(result, r[j])
		end
	end

	return result
end

function get(index)
	return function(object)
		return object[index]
	end
end

function indent(text)
	return "\t" .. text:gsub("\n", "\n\t")
end

return html
