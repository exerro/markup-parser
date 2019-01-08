
--[[

	parse.parse(content) will return a list of "blocks"
	note that `inline-text` represents the inline text format, which is described below
	a block is one of the following:

		{
			type = parse.PARAGRAPH,
			content = inline-text
		}

		{
			type = parse.HEADER,
			size = N                          ; N is an integer 1-6 inclusive representing how "big" the header is (1 being largest)
			content = inline-text
		}

		{
			type = parse.LIST,
			items = {
				[n] = {                       ; n is an integer 1 to N where N is the number of items in the list
					content = inline-text,
					level = L                 ; L is the level at which the item is shown, e.g. 1 for indented once, 0 for no indentation
				}
			}
		}

		{
			type = parse.BLOCK_CODE,
			language = L,                     ; L is an optional string language which the code is in (may be nil)
			content = S                       ; S is the string content of the code
		}

		{
			type = parse.BLOCK_QUOTE,
			content = {
				[n] = block                   ; n is an integer 1 to N where N is the number of blocks in the list
			}
		}

		{
			type = parse.RESOURCE,
			resource = R                      ; R is a string representing the resource to insert
		}

		{
			type = parse.HORIZONTAL_RULE
		}

	the inline text format is a list of items as follows:

		{
			type = parse.TEXT,
			content = S                       ; S is the string content of the text
		}

		{
			type = parse.VARIABLE,
			variable = V                      ; V is the string variable name
		}

		{
			type = parse.CODE,
			content = S                       ; S is the string content of the code
		}

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
			type = parse.IMAGE,
			alt_text = A,                     ; A is the string alt-text to use
			source = S                        ; S is the string source of the image
		}

		{
			type = parse.LINK,
			content = inline-text,            ; this is the text to display
			url = U                           ; U is the string url target of the link
		}

		{
			type = parse.RELATIVE_LINK,
			content = inline-text,            ; this is the text to display
			url = U                           ; U is the string url target of the link
		}

		{
			type = parse.REFERENCE,
			content = inline-text             ; this is the text to display
			reference = T                     ; T is the string reference target
		}

]]

local parse = {}

-- inline types
parse.TEXT = "text"
parse.VARIABLE = "variable"
parse.CODE = "code"
parse.UNDERLINE = "underline"
parse.BOLD = "bold"
parse.ITALIC = "italic"
parse.STRIKETHROUGH = "strikethrough"
parse.IMAGE = "image"
parse.LINK = "link"
parse.RELATIVE_LINK = "relative-link"
parse.REFERENCE = "reference"

-- block types
parse.PARAGRAPH = "paragraph"
parse.HEADER = "header"
parse.LIST = "list"
parse.BLOCK_CODE = "block-code"
parse.BLOCK_QUOTE = "block-quote"
parse.RESOURCE = "resource"
parse.HORIZONTAL_RULE = "horizontal-rule"

-- symbols
parse.HEADER_SYM = "#"
parse.LIST_SYM = "*"
parse.LIST_SYM2 = "-"
parse.RULE_SYM = "---"
parse.CODE_SYM = "```"
parse.BLOCK_QUOTE_SYM = ">"
parse.RESOURCE_SYM = ":"

parse.UNDERLINE_SYM = "__"
parse.BOLD_SYM = "*"
parse.ITALIC_SYM = "_"
parse.STRIKETHROUGH_SYM = "~~"
parse.VARIABLE_SYM = "$"
parse.CODE_SYM = "`"
parse.REFERENCE_SYM = "@"

parse.EMPTY = "empty"

local toLines, formatCodeLines, makeBlocksFromEmptyLines, makeBlocksFromDifferentSyms, formatBlock
local parseTextInline, applyItemInlines, applyItemInline, textFrom
local findMatch
local insert, last, map, flatMap, indexOf
local remove = table.remove
local get
local quote

function parse.parse(content)
	local lines = formatCodeLines(toLines(content))
	local blocks

	for i = 1, #lines do
		local s, r = lines[i]:match("^(%s*)(.*)")
		local indentation = select(2, s:gsub("  ", "\t"):gsub("\t", ""))
		local sym = r:sub(1, 1)
		local result = { indentation = indentation, sym = "", content = r }

		if r:sub(1, #parse.RULE_SYM) == parse.RULE_SYM then
			result.sym = parse.RULE_SYM
			result.content = ""

		elseif r:sub(1, #parse.CODE_SYM) == parse.CODE_SYM then
			result.sym = parse.CODE_SYM
			result.content = r:sub(#parse.CODE_SYM + 1)

		elseif sym == parse.HEADER_SYM or sym == parse.LIST_SYM or sym == parse.LIST_SYM2 or sym == parse.BLOCK_QUOTE_SYM or sym == parse.RESOURCE_SYM then
			result.sym = r:match(sym == parse.HEADER_SYM and "^#+" or "^[^%w%s]")
			result.content = r:match(sym == parse.HEADER_SYM and "^#+%s*(.+)" or "^[^%w%s]%s*(.+)")

		elseif not r:find("%S") then
			result.sym = parse.EMPTY
			result.content = ""
		end

		lines[i] = result
	end

	blocks = flatMap(makeBlocksFromDifferentSyms, makeBlocksFromEmptyLines(lines))

	return map(formatBlock, blocks)
end

function toLines(text)
	local lines = {}
	local p = 1
	local s, f = text:find("\n")

	while s do
		insert(lines, text:sub(p, s - 1))
		p = f + 1
		s, f = text:find("\n", p)
	end

	insert(lines, text:sub(p))

	return lines
end

function formatCodeLines(lines)
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

			insert(result, lines[i])
		end
	end

	return result
end

function makeBlocksFromEmptyLines(lines)
	local i = 1
	local blocks = {{}}

	while i <= #lines and lines[i].sym == parse.EMPTY do
		i = i + 1
	end

	while i <= #lines do
		if lines[i].sym == parse.EMPTY then
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

function makeBlocksFromDifferentSyms(lines)
	if #lines == 0 then
		return {}
	end

	local blocks = {{lines[1]}}
	local lastLineSym = lines[1].sym

	for i = 2, #lines do
		if lastLineSym ~= lines[i].sym            -- different block types can't be in the same block
		or lastLineSym:find(parse.HEADER_SYM)     -- multiple headers can't be in the same block
		or lastLineSym:find(parse.CODE_SYM)       -- multiple code blocks can't be in the same block
		or lastLineSym:find(parse.RULE_SYM)       -- multiple horizontal rules can't be in the same block
		or lastLineSym == parse.RESOURCE_SYM then -- multiple resources can't be in the same block
			insert(blocks, {})
		end

		insert(last(blocks), lines[i])
		lastLineSym = lines[i].sym
	end

	return blocks
end

function formatBlock(lines)
	local blockSym = lines[1].sym

	if blockSym == "" then
		return {
			type = parse.PARAGRAPH,
			content = parseTextInline(table.concat(map(get("content"), lines), "\n"))
		}

	elseif blockSym:find(parse.HEADER_SYM) then
		return {
			type = parse.HEADER,
			size = math.max(1, math.min(6, #blockSym)),
			content = parseTextInline(lines[1].content)
		}

	elseif blockSym == parse.LIST_SYM or blockSym == parse.LIST_SYM2 then
		return {
			type = parse.LIST,
			items = map(function(line)
				return {
					content = parseTextInline(line.content),
					level = line.indentation
				}
			end, lines)
		}

	elseif blockSym == parse.CODE_SYM then
		return {
			type = parse.BLOCK_CODE,
			language = lines[1].content:match("([^\n]+)\n"),
			content = lines[1].content:match("\n(.+)")
		}

	elseif blockSym == parse.BLOCK_QUOTE_SYM then
		return {
			type = parse.BLOCK_QUOTE,
			content = parse.parse(table.concat(map(get("content"), lines), "\n"))
		}

	elseif blockSym == parse.RESOURCE_SYM then
		return {
			type = parse.RESOURCE,
			resource = lines[1].content
		}

	elseif blockSym == parse.RULE_SYM then
		return {
			type = parse.HORIZONTAL_RULE
		}

	else
		return error("internal markup parse error: unknown block sym (" .. blockSym .. ")", 0)

	end
end

function parseTextInline(text)
	local result = {}
	local stack = {result}
	local i = 1
	local modifiers = {}
	local inCode = false
	local excluded = {}
	local activeModifiers = {} -- currently active modifiers
	local ignoreModifiersEnds = {} -- lookup table of modifier ends to ignore ("*_ abc * def _" is equivalent to "*_ abc _* def ")

	local function char(c)
		if last(last(stack)) == nil or last(last(stack)).type ~= parse.TEXT then
			insert(last(stack), { type = parse.TEXT, content = "" })
		end

		insert(last(stack), { type = parse.TEXT, content = remove(last(stack)).content .. c })
	end

	while i <= #text do
		local s, f = findMatch(text, i, {
			"!?%b[]%b()",
			"%[%[[^%]]+%]%]",
			parse.REFERENCE_SYM .. "[%w%-]+",
			parse.REFERENCE_SYM .. "%b()",
			parse.VARIABLE_SYM .. "[%w%-]+",
			parse.VARIABLE_SYM .. "%b()",
			{"`+", function(s) return s end}
		})

		if s then
			for n = s, f do
				excluded[n] = true
			end

			i = f + 1
		else
			excluded[i] = false
			i = i + 1
		end
	end

	i = 1

	-- EWW, this code is gross
	-- TODO: fix this shitty code
	while i <= #text do
		if excluded[i] then
			char(text:sub(i, i))
			i = i + 1
		else
			local modifier

			if text:sub(i, i + #parse.UNDERLINE_SYM - 1) == parse.UNDERLINE_SYM then
				modifier = parse.UNDERLINE_SYM

			elseif text:sub(i, i + #parse.BOLD_SYM - 1) == parse.BOLD_SYM then
				modifier = parse.BOLD_SYM

			elseif text:sub(i, i + #parse.ITALIC_SYM - 1) == parse.ITALIC_SYM then
				modifier = parse.ITALIC_SYM

			elseif text:sub(i, i + #parse.STRIKETHROUGH_SYM - 1) == parse.STRIKETHROUGH_SYM then
				modifier = parse.STRIKETHROUGH_SYM
				
			end

			if modifier then
				local index = indexOf(modifier, activeModifiers)

				if index then
					for j = #activeModifiers, index + 1, -1 do
						ignoreModifiersEnds[activeModifiers[j]] = true
						remove(activeModifiers, j)
						remove(stack)
					end

					remove(activeModifiers)
					remove(stack)
				elseif ignoreModifiersEnds[modifier] then
					ignoreModifiersEnds[modifier] = nil
				else
					local type

					insert(activeModifiers, modifier)

					if modifier == parse.UNDERLINE_SYM then
						type = parse.UNDERLINE

					elseif modifier == parse.BOLD_SYM then
						type = parse.BOLD

					elseif modifier == parse.ITALIC_SYM then
						type = parse.ITALIC

					elseif modifier == parse.STRIKETHROUGH_SYM then
						type = parse.STRIKETHROUGH
					end

					local item = {
						type = type,
						content = {}
					}

					insert(last(stack), item)
					insert(stack, item.content)

				end

				i = i + #modifier
			else
				char(text:sub(i, i))
				i = i + 1
			end
		end
	end

	return applyItemInlines(result)
end

function applyItemInlines(inlines)
	return flatMap(applyItemInline, inlines)
end

function applyItemInline(inline)
	if inline.type == parse.TEXT then
		local text = inline.content
		local i = 1
		local items = {}

		local function append(c)
			if last(items) == nil or last(items).type ~= parse.TEXT then
				insert(items, {type = parse.TEXT, content = "" })
			end

			insert(items, { type = parse.TEXT, content = remove(items).content .. c })
			i = i + 1
		end

		while i <= #text do
			if text:sub(i, i + #parse.VARIABLE_SYM - 1) == parse.VARIABLE_SYM then
				local bracket = text:sub(i + #parse.VARIABLE_SYM) == "("
				local s = text:match(bracket and "^%b()" or "^[%w%-]+", i + #parse.VARIABLE_SYM)

				if s then
					i = i + #s + #parse.VARIABLE_SYM
					insert(items, { type = parse.VARIABLE, variable = bracket and s:sub(2, -2) or s })
				else
					append(parse.VARIABLE_SYM:sub(1, 1))
				end

			elseif text:sub(i, i) == parse.CODE_SYM then
				local len = #text:match("^" .. parse.CODE_SYM .. "+", i)
				local pos = text:find("^" .. parse.CODE_SYM:rep(len), i + len)

				if pos then
					insert(items, { type = parse.CODE, content = text:sub(i + len, pos - 1) })
					i = pos + len
				else
					append(parse.CODE_SYM)
				end

			elseif text:sub(i, i + 1) == "![" then
				local alt, source = text:match("^!(%b[])(%b())", i)

				if alt then
					insert(items, { type = parse.IMAGE, alt_text = alt:sub(2, -2), source = source:sub(2, -2) } )
					i = i + 1 + #alt + #source
				else
					append("!")
				end

			elseif text:sub(i, i + 1) == "[[" then
				local inner = text:match("^%[%[([^%]]+)%]%]", i)

				if inner then
					local parsed = parseTextInline(inner)

					insert(items, { type = parse.RELATIVE_LINK, content = parsed, url = textFrom(parsed) } )
					i = i + 4 + #inner
				else
					append("[")
				end

			elseif text:sub(i, i) == "[" then
				local content, url = text:match("^(%b[])(%b())", i)

				if content then
					insert(items, { type = parse.LINK, content = parseTextInline(content:sub(2, -2)), url = url:sub(2, -2) } )
					i = i + #content + #url
				else
					append("[")
				end

			elseif text:sub(i, i + #parse.REFERENCE_SYM - 1) == parse.REFERENCE_SYM then
				local bracket = text:sub(i + #parse.REFERENCE_SYM) == "("
				local s = text:match(bracket and "^%b()" or "^[%w%-]+", i + #parse.REFERENCE_SYM)
				local parsed

				if s then
					i = i + #s + #parse.REFERENCE_SYM
					parsed = parseTextInline(bracket and s:sub(2, -2) or s)

					insert(items, {
						type = parse.REFERENCE,
						content = parsed,
						reference = textFrom(parsed)
					})
				else
					append(parse.REFERENCE_SYM:sub(1, 1))
				end

			else
				append(text:sub(i, i))
			end
		end

		return items

	else
		return { { type = inline.type, content = applyItemInlines(inline.content) } }
	end
end

function textFrom(inlines)
	return table.concat(map(function(inline)
		if inline.type == parse.TEXT then
			return inline.content
		elseif inline.type == parse.CODE then
			return inline.content
		elseif inline.type == parse.UNDERLINE or inline.type == parse.BOLD or inline.type == parse.ITALIC or inline.type == parse.STRIKETHROUGH then
			return textFrom(inline.content)
		end
	end, inlines))
end

function findMatch(text, pos, patterns)
	for i = 1, #patterns do
		local pat = type(patterns[i]) == "table" and patterns[i][1] or patterns[i]
		local s, f = text:find("^" .. pat, pos)

		if s then
			if type(patterns[i]) == "table" then
				if text:find("^" .. patterns[i][2](text:sub(s, f)), f + 1) then
					return s, select(2, text:find("^" .. patterns[i][2](text:sub(s, f)), f + 1))
				end
			else
				return s, f
			end
		end
	end
end

function insert(table, item, ...)
	if item then
		table[#table + 1] = item
		return insert(table, ...)
	end
end

function last(list)
	return list[#list]
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

function indexOf(item, list)
	for i = 1, #list do
		if list[i] == item then
			return i
		end
	end

	return nil
end

function get(index)
	return function(object)
		return object[index]
	end
end

function quote(s)
	return ("%q"):format(s)
end

return parse
