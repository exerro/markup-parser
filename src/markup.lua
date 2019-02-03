
-- symbols
local HEADER_SYM = "#"
local LIST_SYM = "*"
local LIST_SYM2 = "-"
local RULE_SYM = "---"
local BLOCK_CODE_SYM = "```"
local BLOCK_QUOTE_SYM = ">"
local RESOURCE_SYM = "::"

local UNDERLINE_SYM = "__"
local BOLD_SYM = "*"
local ITALIC_SYM = "_"
local STRIKETHROUGH_SYM = "~~"
local VARIABLE_SYM = "$"
local CODE_SYM = "`"
local MATH_SYM = "$$"
local REFERENCE_SYM = "@"

local LINE_COMMENT = "//"
local EMPTY = "empty"

-- utility functions
local genericScan
local splitContentIntoLines, removeCommentLines, groupCodeLines, formatLines
local makeBlocksFromEmptyLines, makeBlocksFromDifferentSyms
local createBlock
local parseTextInline, applyItemInlines, applyItemInline
local findMatch
local insert, last, map, flatMap, indexOf
local remove = table.remove
local get
local patternEscape

local markup = {}

markup.scan = {}
markup.update = {}
markup.html = {}
markup.filter = {}
markup.util = {}

-- inline types
markup.TEXT = "text"
markup.VARIABLE = "variable"
markup.CODE = "code"
markup.MATH = "math"
markup.UNDERLINE = "underline"
markup.BOLD = "bold"
markup.ITALIC = "italic"
markup.STRIKETHROUGH = "strikethrough"
markup.IMAGE = "image"
markup.LINK = "link"
markup.REFERENCE = "reference"

-- block types
markup.PARAGRAPH = "paragraph"
markup.HEADER = "header"
markup.LIST = "list"
markup.BLOCK_CODE = "block-code"
markup.BLOCK_QUOTE = "block-quote"
markup.RESOURCE = "resource"
markup.HORIZONTAL_RULE = "horizontal-rule"

function markup.text(text)
	return {
		type = markup.TEXT,
		content = text
	}
end

function markup.variable(text)
	return {
		type = markup.VARIABLE,
		content = text
	}
end

function markup.code(text)
	return {
		type = markup.CODE,
		content = text
	}
end

function markup.math(text)
	return {
		type = markup.MATH,
		content = text
	}
end

function markup.underline(text)
	if type(text) == "string" then
		text = markup.parse_text(text)
	end

	return {
		type = markup.UNDERLINE,
		content = text
	}
end

function markup.bold(text)
	if type(text) == "string" then
		text = markup.parse_text(text)
	end

	return {
		type = markup.BOLD,
		content = text
	}
end

function markup.italic(text)
	if type(text) == "string" then
		text = markup.parse_text(text)
	end

	return {
		type = markup.ITALIC,
		content = text
	}
end

function markup.strikethrough(text)
	if type(text) == "string" then
		text = markup.parse_text(text)
	end

	return {
		type = markup.STRIKETHROUGH,
		content = text
	}
end

function markup.image(alt_text, source)
	return {
		type = markup.IMAGE,
		alt_text = alt_text,
		source = source
	}
end

function markup.link(text, url)
	if type(text) == "string" then
		text = markup.parse_text(text)
	end
	
	return {
		type = markup.LINK,
		content = text,
		url = url
	}
end

function markup.reference(text, reference)
	if type(text) == "string" then
		text = markup.parse_text(text)
	end

	if not reference then
		reference = table.concat(map(get("content"), markup.scan.findAllText(text, markup.filter.hasText)))
	end
	
	return {
		type = markup.REFERENCE,
		content = text,
		reference = reference
	}
end

function markup.paragraph(text)
	if type(text) == "string" then
		text = markup.parse_text(text)
	end

	return {
		type = markup.PARAGRAPH,
		content = text
	}
end

function markup.header(text, size)
	if type(text) == "string" then
		text = markup.parse_text(text)
	end

	return {
		type = markup.HEADER,
		content = text,
		size = size or 1
	}
end

function markup.list(items)
	for i = 1, #items do
		if type(items[i]) == "string" then
			items[i] = { content = markup.parse_text(items[i]), level = 1 }
		end
	end

	return {
		type = markup.LIST,
		items = items
	}
end

function markup.code_block(code, language)
	return {
		type = markup.BLOCK_CODE,
		language = language,
		content = code
	}
end

function markup.block_quote(content)
	if type(content) == "string" then
		content = markup.parse(content)
	end

	return {
		type = markup.BLOCK_QUOTE,
		content = content
	}
end

function markup.resource(resource_type, data)
	return {
		type = markup.RESOURCE,
		resource_type = resource_type,
		data = data
	}
end

function markup.rule()
	return { type = markup.HORIZONTAL_RULE }
end

-- returns true if an item is an inline
function markup.isInline(item)
	return item.type == markup.TEXT
	    or item.type == markup.VARIABLE
	    or item.type == markup.CODE
	    or item.type == markup.MATH
	    or item.type == markup.UNDERLINE
	    or item.type == markup.BOLD
	    or item.type == markup.ITALIC
	    or item.type == markup.STRIKETHROUGH
	    or item.type == markup.IMAGE
	    or item.type == markup.LINK
	    or item.type == markup.REFERENCE
end

-- returns true if an item is a block
function markup.isBlock(item)
	return item.type == markup.PARAGRAPH
	    or item.type == markup.HEADER
	    or item.type == markup.LIST
	    or item.type == markup.BLOCK_CODE
	    or item.type == markup.BLOCK_QUOTE
	    or item.type == markup.RESOURCE
	    or item.type == markup.HORIZONTAL_RULE
end

function markup.tostring(item)
	if type(item) == "string" then
		return item
	end

	if item.type then
		if item.type == markup.PARAGRAPH then
			return markup.tostring(item.content)
		elseif item.type == markup.HEADER then
			return ("#"):rep(item.size) .. " " .. markup.tostring(item.content)
		elseif item.type == markup.LIST then
			local s = {}

			for i = 1, #item.items do
				s[i] = ("\t"):rep(item.items[i].level) .."* " .. markup.tostring(item.items[i].content)
			end

			return table.concat(s, "\n")
		elseif item.type == markup.BLOCK_CODE then
			return "```" .. (item.language or "") .. "\n" .. item.content .. "\n```"
		elseif item.type == markup.BLOCK_QUOTE then
			return "> " .. markup.tostring(item.content):gsub("\n", "\n> ")
		elseif item.type == markup.RESOURCE then
			return "@" .. item.resource
		elseif item.type == markup.HORIZONTAL_RULE then
			return "---"
		elseif item.type == markup.TEXT then
			return item.content
		elseif item.type == markup.VARIABLE then
			return "$`" .. item.content .. "`"
		elseif item.type == markup.CODE then
			return "`" .. item.content .. "`"
		elseif item.type == markup.UNDERLINE then
			return "__" .. markup.tostring(item.content) .. "__"
		elseif item.type == markup.BOLD then
			return "*" .. markup.tostring(item.content) .. "*"
		elseif item.type == markup.ITALIC then
			return "_" .. markup.tostring(item.content) .. "_"
		elseif item.type == markup.STRIKETHROUGH then
			return "~~" .. markup.tostring(item.content) .. "~~"
		elseif item.type == markup.IMAGE then
			return "![" .. item.alt_text .. "](" .. item.source .. ")"
		elseif item.type == markup.LINK then
			return "[" .. markup.tostring(item.content) .. "](" .. item.url .. ")"
		elseif item.type == markup.REFERENCE then
			return "@{" .. markup.tostring(item.content) .. " :: " .. item.reference .. "}"
		else
			return "<invalid markup object>"
		end
	end

	if #item == 0 then
		return ""
	end

	local ss = {}

	for i = 1, #item do
		ss[i] = markup.tostring(item[i])
	end

	return table.concat(ss, markup.isBlock(item[1]) and "\n\n" or "")
end

-- options.filter
-- options.no_filter_stop
-- options.deep_scan (defaults to true)
function markup.scan:document(f, options)
	options = options or {}
	options.deep_scan = options.deep_scan == nil or options.deep_scan

	genericScan(f, options, function(t)
		for i = 1, #self do
			t[i] = self[i]
		end
	end, function(block)
		if block.type == markup.BLOCK_QUOTE then
			return block.content
		else
			return {}
		end
	end)
end

-- options.filter
-- options.block_filter
-- options.no_filter_stop
-- options.deep_scan
function markup.scan:text(f, options)
	options = options or {}
	options.deep_scan = options.deep_scan == nil or options.deep_scan

	if self[1] and markup.isInline(self[1]) then
		self = {{ type = markup.PARAGRAPH, content = self }}
	end

	return markup.scan.document(self, function(block)
		local populate = function(t) end

		if block.type == markup.PARAGRAPH or block.type == markup.HEADER then
			populate = function(t)
				for i = 1, #block.content do
					t[i] = block.content[i]
				end
			end
		elseif block.type == markup.LIST then
			populate = function(t)
				for i = 1, #block.items do
					for j = 1, #block.items[i].content do
						t[#t + 1] = block.items[i].content[j]
					end
				end
			end
		end

		return genericScan(f, options, populate, function(inline)
			if inline.type == markup.UNDERLINE
			or inline.type == markup.BOLD
			or inline.type == markup.ITALIC
			or inline.type == markup.STRIKETHROUGH
			or inline.type == markup.LINK
			or inline.type == markup.REFERENCE
			then
				return inline.content
			else
				return {}
			end
		end)
	end, {
		filter = options.block_filter,
		deep_scan = true
	})
end

function markup.scan:findFirst(matching, deep_scan)
	local result

	options = options or {}
	markup.scan.document(self, function(item)
		result = item
		return true
	end, {
		filter = matching,
		no_filter_stop = false,
		deep_scan = deep_scan
	})

	return result
end

function markup.scan:findAll(matching, deep_scan)
	local results = {}

	options = options or {}
	markup.scan.document(self, function(item)
		results[#results + 1] = item
	end, {
		filter = matching,
		no_filter_stop = false,
		deep_scan = deep_scan
	})

	return results
end

function markup.scan:findFirstText(matching, deep_scan)
	local result

	options = options or {}
	markup.scan.text(self, function(item)
		result = item
		return true
	end, {
		filter = matching,
		no_filter_stop = false,
		deep_scan = deep_scan
	})

	return result
end

function markup.scan:findAllText(matching, deep_scan)
	local results = {}

	options = options or {}
	markup.scan.text(self, function(item)
		results[#results + 1] = item
	end, {
		filter = matching,
		no_filter_stop = false,
		deep_scan = deep_scan
	})

	return results
end

function markup.html.headerID(headerNode)
	return table.concat(map(get("content"), markup.scan.findAllText(
		headerNode.content,
		markup.filter.hasText
	))):gsub("<.->", "")
	   :gsub("^%s+", "")
	   :gsub("%s+$", "")
	   :gsub("(%s)%s+", "%1")
	   :gsub("[^%w%-%:%.%_%s]", "")
	   :gsub("[^%w_]", "-")
	   :lower()
end

function markup.filter.new(f)
	return setmetatable({test = f}, {
		__call = function(self, ...)
			return self.test(...)
		end,
		__mul = function(self, other)
			return markup.filter.new(function(...)
				return self(...) and other(...)
			end)
		end,
		__div = function(self, other)
			return markup.filter.new(function(...)
				return self(...) or other(...)
			end)
		end,
	})
end

function markup.filter.type(type)
	return markup.filter.new(function(item)
		return item.type == type
	end)
end

markup.filter.inline
= markup.filter.new(markup.isInline)

markup.filter.block
= markup.filter.new(markup.isBlock)

markup.filter.hasText
= markup.filter.type(markup.TEXT)
/ markup.filter.type(markup.VARIABLE)
/ markup.filter.type(markup.CODE)

-- parses a string into a list of blocks
function markup.parse(content)
	local lines = formatLines(groupCodeLines(removeCommentLines(splitContentIntoLines(content))))
	local blocks = flatMap(makeBlocksFromDifferentSyms, makeBlocksFromEmptyLines(lines))

	return map(createBlock, blocks)
end

-- parses a string of text into a list of inlines
function markup.parse_text(text)
	local result = {}
	local value_stack = {result}
	local create_stack = {false}
	local modifiers = {}
	local i = 1

	local function push(value)
		insert(last(value_stack), value)
	end

	local function pop()
		push(remove(create_stack)(remove(value_stack)))
		remove(modifiers)
	end

	local function mod(sym, create)
		local idx = indexOf(sym, modifiers)

		if idx then
			for i = idx, #value_stack do
				pop()
			end
		else
			insert(modifiers, sym)
			insert(create_stack, create)
			insert(value_stack, {})
		end
	end

	while i <= #text do
		local b, s, f, r = findMatch(text, i, {
			"%[[^%[%]]+%]%([^%(%)]+%)", -- link
			"!%[[^%[%]]+%]%([^%(%)]+%)", -- image
			"%[%[[^%[%]]+%]%]", -- relative link
			patternEscape(REFERENCE_SYM) .. "{[^{}]+}", -- reference 1
			patternEscape(REFERENCE_SYM) .. "%S+", -- reference 2
			patternEscape(MATH_SYM) .. "[^" .. patternEscape(MATH_SYM) .. "]+" .. patternEscape(MATH_SYM), -- math
			patternEscape(VARIABLE_SYM) .. "`[^`]+`", -- variable
			{patternEscape(CODE_SYM) .. "+"}, -- code
			patternEscape(UNDERLINE_SYM), -- underline
			patternEscape(BOLD_SYM), -- bold
			patternEscape(ITALIC_SYM), -- italic
			patternEscape(STRIKETHROUGH_SYM) -- strikethrough
		})

		if s then
			-- switch based on `b` (the branch e.g. which of the above patterns was matched)
			if b == 1 then
				push(markup.link(
					r:match "^%[(.-)%]",
					r:match "^%[.-%]%((.+)%)"
				))
			elseif b == 2 then
				push(markup.image(
					r:match "^%[(.-)%]",
					r:match "^%[.-%]%((.+)%)"
				))
			elseif b == 3 then
				local p = markup.parse_text(r:sub(3, -3))
				push(markup.link(p, table.concat(map(get("content"), markup.scan.findAllText(p, markup.filter.hasText)))))
			elseif b == 4 then
				push(markup.reference(r:sub(#REFERENCE_SYM + 2, -2)))
			elseif b == 5 then
				push(markup.reference(r:sub(#REFERENCE_SYM + 1)))
			elseif b == 6 then
				push(markup.math(r:sub(#MATH_SYM + 1, -#MATH_SYM - 1)))
			elseif b == 7 then
				push(markup.variable(r:sub(#VARIABLE_SYM + 2, -2)))
			elseif b == 8 then
				local l = #r:match(patternEscape(CODE_SYM) .. "+")
				push(markup.code(r:sub(l + 1, -l - 1)))
			elseif b == 9 then
				mod(UNDERLINE_SYM, markup.underline)
			elseif b == 10 then
				mod(BOLD_SYM, markup.bold)
			elseif b == 11 then
				mod(ITALIC_SYM, markup.italic)
			elseif b == 12 then
				mod(STRIKETHROUGH_SYM, markup.strikethrough)
			end

			i = f + 1
		else
			local segment = text:match("^[^"
			.. "%[%]{}%(%)!`"
			.. patternEscape(REFERENCE_SYM)
			.. patternEscape(REFERENCE_SYM)
			.. patternEscape(MATH_SYM)
			.. patternEscape(VARIABLE_SYM)
			.. patternEscape(CODE_SYM)
			.. patternEscape(UNDERLINE_SYM)
			.. patternEscape(BOLD_SYM)
			.. patternEscape(ITALIC_SYM)
			.. patternEscape(STRIKETHROUGH_SYM)
			.. "]+", i) or text:sub(i, i)

			push(markup.text(segment))
			i = i + #segment
		end
	end

	while #value_stack > 1 do
		pop()
	end

	return result

end

function genericScan(f, options, populate, children_of)
	local toScan = {}
	local i = 1

	populate(toScan)

	while i <= #toScan do
		local elem = toScan[i]

		if not options.filter or options.filter(elem) then
			if f(elem) then
				return true
			end
		elseif options.no_filter_stop then
			return true
		end

		if options.deep_scan then
			local children = children_of(elem)

			for j = 1, #children do
				table.insert(toScan, i + j, children[j])
			end
		end

		i = i + 1
	end
end

-- splits a string into a list of its lines
function splitContentIntoLines(text)
	local lines = {}
	local p = 1
	local s, f = text:find("\r?\n")

	while s do
		insert(lines, text:sub(p, s - 1))
		p = f + 1
		s, f = text:find("\r?\n", p)
	end

	insert(lines, text:sub(p))

	return lines
end

-- removes lines containing only a comment
function removeCommentLines(lines)
	local result = {}

	for i = 1, #lines do
		if lines[i]:find("^%s*" .. patternEscape(LINE_COMMENT)) then
			result[i] = ""
		else
			result[i] = lines[i]
		end
	end

	return result
end

-- groups lines between multi-line code tags into a single line
function groupCodeLines(lines)
	local result = {}
	local inCode = false

	for i = 1, #lines do
		if inCode then
			if lines[i]:find "^%s*```%s*$" then
				inCode = false
			else
				insert(result, remove(result) .. "\n" .. lines[i])
			end
		else
			if lines[i]:find "^%s*```[%w_%-]*%s*$" then
				inCode = true
			end

			insert(result, (lines[i]:gsub("%s+$", "")))
		end
	end

	return result
end

-- turns a list of lines into a structure with { indentation, sym, content }
-- `sym` is the beginning symbolic operator (e.g. '#' for a header)
function formatLines(lines)
	local output = {}

	for i = 1, #lines do
		local s, r = lines[i]:match("^(%s*)(.*)")
		local indentation = select(2, s:gsub("  ", "\t"):gsub("\t", ""))
		local result = { indentation = indentation, sym = "", content = r }

		if r:sub(1, #RULE_SYM) == RULE_SYM then
			result.sym = RULE_SYM
			result.content = ""

		elseif r:sub(1, #BLOCK_CODE_SYM) == BLOCK_CODE_SYM then
			result.sym = BLOCK_CODE_SYM
			result.content = r:sub(#BLOCK_CODE_SYM + 1)

		elseif r:sub(1, #LIST_SYM + 1) == LIST_SYM .. " " then
			result.sym = LIST_SYM
			result.content = r:match "^[^%w%s]%s+(.+)"

		elseif r:sub(1, #LIST_SYM2 + 1) == LIST_SYM2 .. " " then
			result.sym = LIST_SYM
			result.content = r:match "^[^%w%s]%s+(.+)"

		elseif r:sub(1, #BLOCK_QUOTE_SYM + 1) == BLOCK_QUOTE_SYM .. " " then
			result.sym = BLOCK_QUOTE_SYM
			result.content = r:match "^[^%w%s]%s+(.+)"

		elseif r:find("^" .. patternEscape(HEADER_SYM) .. "+%s") then
			result.sym = HEADER_SYM
			result.size = #r:match("^" .. patternEscape(HEADER_SYM) .. "+")
			result.content = r:match("^" .. patternEscape(HEADER_SYM) .. "+%s+(.+)")

		elseif r:sub(1, #RESOURCE_SYM) == RESOURCE_SYM then
			result.sym = RESOURCE_SYM
			result.content = r:match "^[^%w%s]%s*(.+)"

		elseif not r:find("%S") then
			result.sym = EMPTY
			result.content = ""
		end

		output[i] = result
	end

	return output
end

-- makes groups of lines, delimited by EMPTY lines (not included in return)
function makeBlocksFromEmptyLines(lines)
	local i = 1
	local blocks = {{}}

	while i <= #lines and lines[i].sym == EMPTY do
		i = i + 1
	end

	while i <= #lines do
		if lines[i].sym == EMPTY then
			if #last(blocks) > 0 then
				insert(blocks, {})
			end
		else
			insert(last(blocks), lines[i])
		end

		i = i + 1
	end

	if #last(blocks) == 0 then
		remove(blocks)
	end

	return blocks
end

-- splits a group of lines into more groups of lines, subject to the following rules
--  each group may only have one line type
--  only one line may exist in a group if its type is one of {HEADER_SYM, BLOCK_CODE_SYM, RULE_SYM, RESOURCE_SYM}
function makeBlocksFromDifferentSyms(lines)
	if #lines == 0 then
		return {}
	end

	local blocks = {{lines[1]}}
	local lastLineSym = lines[1].sym

	for i = 2, #lines do
		if lastLineSym ~= lines[i].sym      -- different block types can't be in the same block
		or lastLineSym == HEADER_SYM        -- multiple headers can't be in the same block
		or lastLineSym == BLOCK_CODE_SYM    -- multiple code blocks can't be in the same block
		or lastLineSym == RULE_SYM          -- multiple horizontal rules can't be in the same block
		or lastLineSym == RESOURCE_SYM then -- multiple resources can't be in the same block
			insert(blocks, {})
		end

		insert(last(blocks), lines[i])
		lastLineSym = lines[i].sym
	end

	return blocks
end

-- creates a markup block from a group of lines
function createBlock(lines)
	local blockSym = lines[1].sym

	if blockSym == "" then
		return markup.paragraph(table.concat(map(get("content"), lines), "\n"))

	elseif blockSym == HEADER_SYM then
		return markup.header(lines[1].content, math.max(1, math.min(6, lines[1].size)))

	elseif blockSym == LIST_SYM then
		return markup.list(map(function(line)
			return {
				content = markup.parse_text(line.content),
				level = line.indentation
			}
		end, lines))

	elseif blockSym == BLOCK_CODE_SYM then
		return markup.code_block(
			lines[1].content:match("\n(.*)$") or "",
			lines[1].content:match("([^\n]+)\n")
		)

	elseif blockSym == BLOCK_QUOTE_SYM then
		return markup.block_quote(table.concat(map(get("content"), lines), "\n"))

	elseif blockSym == RESOURCE_SYM then
		return markup.resource(
			lines[1].content:match "^%S*",
			lines[1].content:match "^%S*%s(.*)"
		)

	elseif blockSym == RULE_SYM then
		return markup.rule()

	else
		return error("internal markup parse error: unknown block sym (" .. blockSym .. ")", 0)

	end
end

-- finds a match of one of many patterns against a string
-- each pattern may be a table containing one item, indicating that match is an open/close tag
function findMatch(text, pos, patterns)
	for i = 1, #patterns do
		local pat = type(patterns[i]) == "table" and patterns[i][1] or patterns[i]
		local s, f = text:find("^" .. pat, pos)

		if s then
			local r = text:sub(s, f)

			if type(patterns[i]) == "table" then
				local s2, f2 = text:find(r, f + 1)

				if s2 then
					return i, s, f2, text:sub(s, f2)
				end
			else
				return i, s, f, r
			end
		end
	end
end

-- inserts items into a table
function insert(table, item, ...)
	if item then
		table[#table + 1] = item
		return insert(table, ...)
	end
end

-- returns the last item in a table
function last(list)
	return list[#list]
end

-- applies a function to every item in a list, returning a new list
function map(f, list)
	local result = {}

	for i = 1, #list do
		result[i] = f(list[i])
	end

	return result
end

-- applies a function to every item in a list, returning a new list which is the concatenation of results
-- 	f :: p -> [r]
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

-- finds the index of an item in a list
function indexOf(item, list)
	for i = 1, #list do
		if list[i] == item then
			return i
		end
	end

	return nil
end

-- returns a function which takes an object and returns the specified index in that object
function get(index)
	return function(object)
		return object[index]
	end
end

-- escapes a string w.r.t. Lua patterns
function patternEscape(pat)
	return pat:gsub("[%-%+%*%?%.%(%)%[%]%$%^]", "%%%1")
end

markup.util.map = map
markup.util.get = get
markup.util.flatMap = flatMap
markup.util.indexOf = indexOf
markup.util.patternEscape = patternEscape
markup.util.last = last

return markup
