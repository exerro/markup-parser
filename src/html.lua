
local markup = require "src.markup"

--[[
		{
			type = markup.UNDERLINE,
			content = inline-text
		}

		{
			type = markup.BOLD,
			content = inline-text
		}

		{
			type = markup.ITALIC,
			content = inline-text
		}

		{
			type = markup.STRIKETHROUGH,
			content = inline-text
		}

		{
			type = markup.RELATIVE_LINK,
			content = inline-text,            ; this is the text to display
			url = U                           ; U is the string url target of the link
		}

		{
			type = markup.REFERENCE,
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
local map, indent

function html.blocksToHTML(blocks)
	return table.concat(map(html.blockToHTML, blocks), "\n\n")
end

function html.blockToHTML(block)

	if block.type == markup.PARAGRAPH then
		return "<p class=\"" .. getClass(html.PARAGRAPH) .. "\">\n"
		.. indent(html.inlinesToHTML(block.content):gsub("\n", "<br>"))
		.. "\n</p>"

	elseif block.type == markup.HEADER then
		local content = html.inlinesToHTML(block.content)

		return "<h" .. block.size .. " id=\"" .. content:gsub("<.->", ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("(%s)%s+", "%1"):gsub("%W", "-") .. "\" class=\"" .. getClass(html.HEADER) .. " " .. getClass(html.HEADER) .. block.size .. "\">\n"
		.. indent(content)
		.. "\n</h" .. block.size .. ">"

	elseif block.type == markup.LIST then
		return "<ul class=\"" .. getClass(html.LIST) .. "\">\n"
		.. table.concat(map(html.listItemToHTML, block.items), "\n")
		.. "\n</ul>"

	elseif block.type == markup.BLOCK_CODE then
		local lang = block.language:lower()

		if highlighters[lang] then
			return tostring(highlighters[lang](block.content))
		end

		-- TODO: maybe have some kind of box around the code? an indication of language? idk
		return html.codeEnclose("<pre>\n"
		.. block.content
		.. "\n</pre>", lang)

	elseif block.type == markup.BLOCK_QUOTE then
		return "<div class=\"" .. getClass(html.BLOCK_QUOTE) .. "\">\n"
		.. indent(html.blocksToHTML(block.content))
		.. "\n</div>"

	elseif block.type == markup.RESOURCE then
		if resourceLoader then
			return tostring(resourceLoader(block.resource))
		else
			return "<p class=\"" .. getClass(html.FORMAT_ERROR) .. "\">&lt; no resource loader for '" .. block.resource .. "' :( &gt;</p>"
		end

	elseif block.type == markup.HORIZONTAL_RULE then
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
	if inline.type == markup.TEXT then
		return "<span class=\"" .. getClass(html.TEXT) .. "\">" .. inline.content .. "</span>"

	elseif inline.type == markup.VARIABLE then
		return "<span class=\"" .. getClass(html.VARIABLE) .. "\">" .. inline.variable .. "</span>"

	elseif inline.type == markup.CODE then
		return "<span class=\"" .. getClass(html.CODE) .. "\">" .. inline.content .. "</span>"

	elseif inline.type == markup.UNDERLINE then
		return "<u class=\"" .. getClass(html.STRIKETHROUGH) .. "\">"
		.. html.inlinesToHTML(inline.content)
		.. "</u>"

	elseif inline.type == markup.BOLD then
		return "<strong class=\"" .. getClass(html.STRIKETHROUGH) .. "\">"
		.. html.inlinesToHTML(inline.content)
		.. "</strong>"

	elseif inline.type == markup.ITALIC then
		return "<i class=\"" .. getClass(html.STRIKETHROUGH) .. "\">"
		.. html.inlinesToHTML(inline.content)
		.. "</i>"

	elseif inline.type == markup.STRIKETHROUGH then
		return "<del class=\"" .. getClass(html.STRIKETHROUGH) .. "\">"
		.. html.inlinesToHTML(inline.content)
		.. "</del>"

	elseif inline.type == markup.IMAGE then
		return "<img class=\"" .. getClass(html.IMAGE) .. "\" alt=\"" .. inline.alt_text .. "\" src=\"" .. inline.source .. "\">"

	elseif inline.type == markup.LINK then
		return "<a class=\"" .. getClass(html.LINK) .. "\" href=\"" .. inline.url .. "\">" .. html.inlinesToHTML(inline.content) .. "</a>"

	elseif inline.type == markup.RELATIVE_LINK then
		if relativeLinkFormatter then
			return "<a class=\"" .. getClass(html.LINK) .. "\" href=\"" .. relativeLinkFormatter(inline.url) .. "\">" .. html.inlinesToHTML(inline.content) .. "</a>"
		else
			return "<span class=\"" .. getClass(html.FORMAT_ERROR) .. "\">&lt; no relative link formatter for '" .. inline.url .. "' :( &gt;</span>"
		end

	elseif inline.type == markup.REFERENCE then
		if referenceFormatter then
			return "<a class=\"" .. getClass(html.LINK) .. "\" href=\"" .. referenceFormatter(inline.reference) .. "\">" .. inline.content .. "</a>"
		else
			return "<span class=\"" .. getClass(html.FORMAT_ERROR) .. "\">&lt; no reference formatter for '" .. inline.reference .. "' :( &gt;</span>"
		end

	end
end

function html.codeEnclose(text, language)
	return "<p class=\"" .. getClass(html.BLOCK_CODE) .. "\">" .. text .. "</p>"
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

function html.defaultRelativeLinkFormatter(link)
	return link
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

function indent(text)
	return "\t" .. text:gsub("\n", "\n\t")
end

return html
