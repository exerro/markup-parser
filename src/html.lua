
local markup = require "src.markup"
local format = require "src.format"

require "src.parse"

local html = {}
local highlighters = {}
local resourceLoader
local relativeLinkFormatter
local referenceFormatter

-- configurable
html.CLASS_PREFIX = "md-"

-- css classes, note that "~" is replaced with `html.CLASS_PREFIX`
html.FORMAT_ERROR = "~format-error"
html.BLOCK = "~block"
html.CONTENT = "~content"

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
html.MATH = "~math"
html.UNDERLINE = "~underline"
html.BOLD = "~bold"
html.ITALIC = "~italic"
html.STRIKETHROUGH = "~strikethrough"
html.IMAGE = "~image"
html.LINK = "~link"
html.REFERENCE = "~reference"

html.latex_render_script = latex_render_script

local getClass
local blocksToHTML, blockToHTML, inlinesToHTML, inlineToHTML
local listElements, listItemToHTML
local map, indent, urlEscape, urlEscapeTable

function html.render(blocks)
	if type(blocks) == "string" then
		blocks = markup.parse(blocks)
	end

	return "\n<div class=\"" .. getClass(html.CONTENT) .. "\">\n"
	    .. blocksToHTML(blocks)
	    .. "\n</div>"
end

function html.escape(text)
	return text:gsub("[&/<>\"]", {
		["&"] = "&amp;",
		["/"] = "&frasl;",
		["<"] = "&lt;",
		[">"] = "&gt;",
		["\""] = "&quot;"
	})
end

function html.codeEnclose(text, language)
	return "<div class=\"" .. getClass(html.BLOCK_CODE, html.BLOCK) .. "\">" .. text .. "</div>"
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

function blocksToHTML(blocks)
	return table.concat(map(blockToHTML, blocks), "\n\n")
end

function blockToHTML(block)

	if block.type == markup.PARAGRAPH then
		if #block.content == 1 and block.content[1].type == markup.MATH then
			return "<img class=\"" .. getClass(html.MATH, html.BLOCK) .. "\" "
			.. "alt=\"" .. html.escape(block.content[1].content) .. "\" "
			.. "src=\"https://chart.googleapis.com/chart?cht=tx&chl=%5CLarge%20" .. urlEscape(block.content[1].content) .. "\">"
		else
			return "<p class=\"" .. getClass(html.PARAGRAPH, html.BLOCK) .. "\">\n"
			.. indent(inlinesToHTML(block.content):gsub("\n", "<br>"))
			.. "\n</p>"
		end

	elseif block.type == markup.HEADER then
		local content = inlinesToHTML(block.content)
		local id = format.headerID(block)

		return "<h" .. block.size .. " id=\"" .. html.escape(id) .. "\" class=\"" .. getClass(html.HEADER, html.HEADER .. block.size, html.BLOCK) .. "\">\n"
		.. indent(content)
		.. "\n</h" .. block.size .. ">"

	elseif block.type == markup.LIST then
		return "<ul class=\"" .. getClass(html.LIST, html.BLOCK) .. "\">\n"
		.. indent(listElements(block.items))
		.. "\n</ul>"

	elseif block.type == markup.BLOCK_CODE then
		local lang = block.language and block.language:lower()

		if highlighters[lang] then
			return tostring(highlighters[lang](block.content))
		end

		-- TODO: maybe have some kind of box around the code? an indication of language? idk
		return html.codeEnclose("<pre>\n"
		.. html.escape(block.content)
		.. "\n</pre>", lang)

	elseif block.type == markup.BLOCK_QUOTE then
		return "<blockquote class=\"" .. getClass(html.BLOCK_QUOTE, html.BLOCK) .. "\">\n"
		.. blocksToHTML(block.content)
		.. "\n</blockquote>"

	elseif block.type == markup.RESOURCE then
		if resourceLoader then
			return "<div class=\"" .. getClass(html.BLOCK) .. "\">" .. tostring(resourceLoader(block.resource)) .. "</div>"
		else
			return "<p class=\"" .. getClass(html.FORMAT_ERROR, html.BLOCK) .. "\">&lt; no resource loader for '" .. html.escape(block.resource) .. "' :( &gt;</p>"
		end

	elseif block.type == markup.HORIZONTAL_RULE then
		return "<hr class=\"" .. getClass(html.HORIZONTAL_RULE, html.BLOCK) .. "\">"

	else
		return error("internal markup error: unknown block type (" .. tostring(block.type) .. ")")

	end
end

function inlinesToHTML(inlines)
	return table.concat(map(inlineToHTML, inlines))
end

function inlineToHTML(inline)
	if inline.type == markup.TEXT then
		return "<span class=\"" .. getClass(html.TEXT) .. "\">" .. html.escape(inline.content) .. "</span>"

	elseif inline.type == markup.VARIABLE then
		return "<span class=\"" .. getClass(html.VARIABLE) .. "\">" .. html.escape(inline.variable) .. "</span>"

	elseif inline.type == markup.CODE then
		return "<code class=\"" .. getClass(html.CODE) .. "\">" .. html.escape(inline.content) .. "</code>"

	elseif inline.type == markup.MATH then
		return "<img class=\"" .. getClass(html.MATH) .. "\" "
		.. "alt=\"" .. html.escape(inline.content) .. "\" "
		.. "src=\"https://chart.googleapis.com/chart?cht=tx&chl=" .. urlEscape(inline.content) .. "\">"

	elseif inline.type == markup.UNDERLINE then
		return "<u class=\"" .. getClass(html.UNDERLINE) .. "\">"
		.. inlinesToHTML(inline.content)
		.. "</u>"

	elseif inline.type == markup.BOLD then
		return "<strong class=\"" .. getClass(html.BOLD) .. "\">"
		.. inlinesToHTML(inline.content)
		.. "</strong>"

	elseif inline.type == markup.ITALIC then
		return "<i class=\"" .. getClass(html.ITALIC) .. "\">"
		.. inlinesToHTML(inline.content)
		.. "</i>"

	elseif inline.type == markup.STRIKETHROUGH then
		return "<del class=\"" .. getClass(html.STRIKETHROUGH) .. "\">"
		.. inlinesToHTML(inline.content)
		.. "</del>"

	elseif inline.type == markup.IMAGE then
		return "<img class=\"" .. getClass(html.IMAGE) .. "\" alt=\"" .. html.escape(inline.alt_text) .. "\" src=\"" .. (inline.source) .. "\">"

	elseif inline.type == markup.LINK then
		return "<a class=\"" .. getClass(html.LINK) .. "\" href=\"" .. (inline.url) .. "\">" .. inlinesToHTML(inline.content) .. "</a>"

	elseif inline.type == markup.RELATIVE_LINK then
		if relativeLinkFormatter then
			return "<a class=\"" .. getClass(html.LINK) .. "\" href=\"" .. (relativeLinkFormatter(inline.url)) .. "\">" .. inlinesToHTML(inline.content) .. "</a>"
		else
			return "<span class=\"" .. getClass(html.FORMAT_ERROR) .. "\">&lt; no relative link formatter for '" .. inline.url .. "' :( &gt;</span>"
		end

	elseif inline.type == markup.REFERENCE then
		if referenceFormatter then
			return "<a class=\"" .. getClass(html.REFERENCE) .. "\" href=\"" .. (referenceFormatter(inline.reference)) .. "\">" .. inline.content .. "</a>"
		else
			return "<span class=\"" .. getClass(html.FORMAT_ERROR) .. "\">&lt; no reference formatter for '" .. inline.reference .. "' :( &gt;</span>"
		end

	else
		return error("internal markup error: unknown inline type (" .. tostring(inline.type) .. ")")

	end
end

function listElements(items)
	local lastIndent = items[1].level
	local baseIndent = lastIndent
	local s = indent(listItemToHTML(items[1]), lastIndent - baseIndent)

	local function line(content)
		s = s .. "\n" .. indent(content, lastIndent - baseIndent)
	end

	for i = 2, #items do
		for _ = lastIndent, math.max(items[i].level, baseIndent) - 1 do
			line("<ul class=\"" .. getClass(html.LIST) .. "\">")
			lastIndent = lastIndent + 1
		end

		for _ = math.max(items[i].level, baseIndent), lastIndent - 1 do
			lastIndent = lastIndent - 1
			line("</ul>")
		end

		line(listItemToHTML(items[i]))
	end

	for i = baseIndent, lastIndent - 1 do
		lastIndent = lastIndent - 1
		line("</ul>")
	end

	return s
end

function listItemToHTML(li)
	--  TODO: use li.level
	return "<li class=\"" .. getClass(html.LIST_ITEM) .. "\">\n"
	.. indent(inlinesToHTML(li.content))
	.. "\n</li>"
end

function getClass(...)
	return table.concat(map(function(s) return s:gsub("~", html.CLASS_PREFIX) end, {...}), " ")
end

function map(f, list)
	local result = {}

	for i = 1, #list do
		result[i] = f(list[i])
	end

	return result
end

function indent(text, amount)
	return ("\t"):rep(amount or 1) .. text:gsub("\n", "\n" .. ("\t"):rep(amount or 1))
end

function urlEscape(text)
	return text:gsub("[^a-zA-Z0-9_\\]", urlEscapeTable)
end

urlEscapeTable = {}

for i = 0, 255 do
	urlEscapeTable[string.char(i)] = "%" .. ("%02X"):format(i)
end

return html
