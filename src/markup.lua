
local HTML_MATH_URL = "https://chart.googleapis.com/chart?cht=tx&chl="

-- css classes, note that "~" is replaced with `${markup.html.CLASS_PREFIX}-`
local HTML_FORMAT_ERROR = "~format-error"
local HTML_BLOCK = "~block"
local HTML_CONTENT = "~content"

local HTML_PARAGRAPH = "~para"
local HTML_HEADER = "~header"
local HTML_LIST = "~list"
local HTML_LIST_ITEM = "~list-item"
local HTML_BLOCK_CODE = "~block-code"
local HTML_BLOCK_CODE_CONTENT = "~block-code-content"
local HTML_BLOCK_QUOTE = "~block-quote"
local HTML_HORIZONTAL_RULE = "~hr"

local HTML_TEXT = "~text"
local HTML_VARIABLE = "~variable"
local HTML_CODE = "~code"
local HTML_MATH = "~math"
local HTML_UNDERLINE = "~underline"
local HTML_BOLD = "~bold"
local HTML_ITALIC = "~italic"
local HTML_STRIKETHROUGH = "~strikethrough"
local HTML_IMAGE = "~image"
local HTML_LINK = "~link"
local HTML_REFERENCE = "~reference"

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
local DATA_SYM = ":"

local LINE_COMMENT = "//"
local EMPTY = "empty"

-- utility functions
local generic_scan
local split_content_into_lines, remove_comment_lines, group_code_lines, format_lines
local make_blocks_from_empty_lines, make_blocks_from_different_syms
local create_block
local find_matches
local insert, last, map, flat_map, index_of
local remove = table.remove
local get
local pattern_escape
local indent
local url_escape_table
local blocks_to_html, block_to_html, inlines_to_html, inline_to_html
local list_elements, list_item_to_html
local format_error, block_format_error

local markup = {}

markup.scan = {}
markup.update = {}
markup.html = {}
markup.filter = {}
markup.util = {}

-- HTML class prefix
markup.html.CLASS_PREFIX = "mu"

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
markup.DATA = "data"
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

function markup.data(data_type, data)
	return {
		type = markup.DATA,
		data_type = data_type,
		data = data
	}
end

function markup.reference(text, reference)
	if type(text) == "string" then
		text = markup.parse_text(text)
	end

	if not reference then
		reference = table.concat(map(get("content"), markup.scan.find_all_text(text, markup.filter.has_text)))
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

function markup.is_node(item)
	return type(item) == "table" and (markup.is_inline(item) or markup.is_block(item))
end

function markup.is_inline(item)
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
	    or item.type == markup.DATA
	    or item.type == markup.REFERENCE
end

function markup.is_block(item)
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
		elseif item.type == markup.DATA then
			return "{:" .. item.data_type .. " " .. item.data .. "}"
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

	return table.concat(ss, markup.is_block(item[1]) and "\n\n" or "")
end

function markup.scan.document(document, f, options)
	options = options or {}
	options.deep_scan = options.deep_scan == nil or options.deep_scan

	generic_scan(f, options, function(t)
		for i = 1, #document do
			t[i] = document[i]
		end
	end, function(block)
		if block.type == markup.BLOCK_QUOTE then
			return block.content
		else
			return {}
		end
	end)
end

function markup.scan.text(document, f, options)
	options = options or {}
	options.deep_scan = options.deep_scan == nil or options.deep_scan

	if document[1] and markup.is_inline(document[1]) then
		document = {{ type = markup.PARAGRAPH, content = document }}
	end

	return markup.scan.document(document, function(block)
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

		return generic_scan(f, options, populate, function(inline)
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

function markup.scan.find_first(f, document, matching, deep_scan)
	local result

	if f ~= markup.scan.document and f ~= markup.scan.text then
		return error("invalid first parameter: must be either markup.scan.document or markup.scan.text")
	end

	f(document, function(item)
		result = item
		return true
	end, {
		filter = matching,
		no_filter_stop = false,
		deep_scan = deep_scan
	})

	return result
end

function markup.scan.find_all(f, document, matching, deep_scan)
	local results = {}

	if f ~= markup.scan.document and f ~= markup.scan.text then
		return error("invalid first parameter: must be either markup.scan.document or markup.scan.text")
	end

	f(document, function(item)
		results[#results + 1] = item
	end, {
		filter = matching,
		no_filter_stop = false,
		deep_scan = deep_scan
	})

	return results
end

-- filter
-- deep_update
-- no_filter_stop
-- include_unfiltered
function markup.update.document(document, f, options)
	options = options or {}
	options.deep_update = options.deep_update == nil or options.deep_update

	return generic_update(f, options, document, function(node)
		return node.type == markup.BLOCK_QUOTE and node.content or {}
	end, function(node, children)
		-- this must be a block quote
		return {
			type = node.type,
			content = children
		}
	end)
end

function markup.update.text(document, f, options)
	options = options or {}
	options.deep_scan = options.deep_scan == nil or options.deep_scan

	local changed = false

	if document[1] and markup.is_inline(document[1]) then
		local res, changed = markup.update.text(document, {markup.paragraph(document)}, options)
		return res[1].content, changed
	end

	local function children_of(inline)
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
	end

	local function set_children(inline, children)
		local new = {}

		for k, v in pairs(inline) do
			new[k] = v
		end

		new.content = children

		return new
	end

	return markup.update.document(document, function(block)
		if block.type == markup.PARAGRAPH or block.type == markup.HEADER then
			local new_children, changed = generic_update(f, options, block.content, children_of, set_children)

			return {changed and {
				type = block.type,
				content = new_children,
				size = block.size -- for headers
			} or block}

		elseif block.type == markup.LIST then
			local new_items = {}
			local sub_changed = true

			for i = 1, #block.items do
				new_items[#new_items + 1], sub_changed = generic_update(f, options, block.items[i].content, children_of, set_children)
				changed = changed or sub_changed
			end

			return {changed and {
				type = markup.LIST,
				items = new_items
			} or block}
		end
	end, {
		filter = options.block_filter,
		include_unfiltered = options.block_include_unfiltered,
		deep_update = true
	})
end

function markup.update.insert_after(f, document, filter, insertion, many, deep_update)
	local changed = false

	if f ~= markup.update.document and f ~= markup.update.text then
		return error("invalid first parameter: must be either markup.update.document or markup.update.text")
	end

	return markup.update.document(document, function(node)
		changed = not many
		return {node, insertion}
	end, {
		filter = function(...)
			return not changed and filter(...)
		end,
		include_unfiltered = true,
		deep_update = deep_update
	})
end

function markup.update.insert_before(f, document, filter, insertion, many, deep_update)
	local changed = false

	if f ~= markup.update.document and f ~= markup.update.text then
		return error("invalid first parameter: must be either markup.update.document or markup.update.text")
	end

	return markup.update.document(document, function(node)
		changed = not many
		return {insertion, node}
	end, {
		filter = function(...)
			return not changed and filter(...)
		end,
		include_unfiltered = true,
		deep_update = deep_update
	})
end

-- this works, seriously, it doesn't look like it should but it does and I love it
-- filtering the nodes to _remove_, you say? yep, note `include_unfiltered` and the `{}` return value
-- am I mad? maybe. do I write cool code? fuck yeah
function markup.update.remove(f, document, filter, many, deep_update)
	local changed = false

	if f ~= markup.update.document and f ~= markup.update.text then
		return error("invalid first parameter: must be either markup.update.document or markup.update.text")
	end

	return f(document, function(node)
		changed = not many
		return {}
	end, {
		filter = function(...)
			return not changed and filter(...)
		end,
		include_unfiltered = true,
		deep_update = deep_update
	})
end

function markup.update.remove_after(f, document, filter, deep_update)
	local include = true

	if f ~= markup.update.document and f ~= markup.update.text then
		return error("invalid first parameter: must be either markup.update.document or markup.update.text")
	end

	return f(document, function(node)
		include = not filter(node)
		return nil
	end, {
		filter = function(...)
			return include
		end,
		no_filter_stop = true,
		include_unfiltered = false,
		deep_update = deep_update
	})
end

function markup.update.remove_before(f, document, filter, deep_update)
	local include = false

	if f ~= markup.update.document and f ~= markup.update.text then
		return error("invalid first parameter: must be either markup.update.document or markup.update.text")
	end

	return f(document, function(node)
		return nil
	end, {
		filter = function(...)
			include = filter(...)
			return include
		end,
		include_unfiltered = false,
		deep_update = deep_update
	})
end

function markup.update.replace(f, document, filter, map, many, deep_update)
	local changed = false

	if f ~= markup.update.document and f ~= markup.update.text then
		return error("invalid first parameter: must be either markup.update.document or markup.update.text")
	end

	return f(document, function(node)
		changed = not many
		return type(map) == "table" and map or map(node)
	end, {
		filter = function(...)
			return not many and filter(...)
		end,
		include_unfiltered = true,
		deep_update = deep_update
	})
end

function markup.html.render(document, options)
	options = options or {}
	options = {
		highlighters = options.highlighters or {},
		loaders = options.loaders or {},
		reference_link = options.reference_link
	}

	if type(document) == "string" then
		document = markup.parse(document)
	end

	return "\n<div class=\"" .. markup.html.class(HTML_CONTENT) .. "\">\n"
	    .. blocks_to_html(document, options)
	    .. "\n</div>"
end

function markup.html.headerID(headerNode)
	return table.concat(map(get("content"), markup.scan.find_all_text(
		headerNode.content,
		markup.filter.has_text
	))):gsub("<.->", "")
	   :gsub("^%s+", "")
	   :gsub("%s+$", "")
	   :gsub("(%s)%s+", "%1")
	   :gsub("[^%w%-%:%.%_%s]", "")
	   :gsub("[^%w_]", "-")
	   :lower()
end

function markup.html.class(...)
	return table.concat(map(function(item) return item:gsub("~", markup.html.CLASS_PREFIX .. "-") end, {...}), " ")
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
		__sub = function(self, other)
			return markup.filter.new(function(...)
				return self(...) and not other(...)
			end)
		end,
		__div = function(self, other)
			return markup.filter.new(function(...)
				return self(...) or other(...)
			end)
		end,
		__unm = function(self)
			return markup.filter.new(function(...)
				return not self(...)
			end)
		end
	})
end

function markup.filter.equals(object)
	return markup.filter.new(function(item)
		return item == object
	end)
end

function markup.filter.type(type)
	return markup.filter.new(function(item)
		return item.type == type
	end)
end

function markup.filter.property_equals(property, value)
	return markup.filter.new(function(item)
		return item[property] == value
	end)
end

function markup.filter.property_contains(property, value)
	return markup.filter.new(function(item)
		return tostring(item[property]):find(value)
	end)
end

function markup.filter.property_matches(property, predicate)
	return markup.filter.new(function(item)
		return predicate(item[property])
	end)
end

function markup.filter.has_data_type(data_type)
	return markup.filter.type(markup.DATA)
	     * markup.filter.property_equals("data_type", data_type)
end

markup.filter.inline
= markup.filter.new(markup.is_inline)

markup.filter.block
= markup.filter.new(markup.is_block)

markup.filter.has_text
= markup.filter.type(markup.TEXT)
/ markup.filter.type(markup.VARIABLE)
/ markup.filter.type(markup.CODE)

function markup.util.html_escape(text)
	return text:gsub("[&/<>\"]", {
		["&"] = "&amp;",
		["/"] = "&#47;",
		["<"] = "&lt;",
		[">"] = "&gt;",
		["\""] = "&quot;"
	})
end

function markup.util.url_escape(text)
	return text:gsub("[^a-zA-Z0-9_\\]", url_escape_table)
end

function markup.parse(content)
	local lines = format_lines(remove_comment_lines(group_code_lines(split_content_into_lines(content))))
	local blocks = flat_map(make_blocks_from_different_syms, make_blocks_from_empty_lines(lines))

	return map(create_block, blocks)
end

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
		local idx = index_of(sym, modifiers)

		if idx then
			for i = idx, #value_stack - 1 do
				pop()
			end
		else
			insert(modifiers, sym)
			insert(create_stack, create)
			insert(value_stack, {})
		end
	end

	while i <= #text do
		local b, s, f, r = find_matches(text, i, {
			"%[[^%[%]]+%]%([^%(%)]+%)", -- link
			"!%[[^%[%]]*%]%([^%(%)]+%)", -- image
			"%[%[[^%[%]]+%]%]", -- relative link
			pattern_escape(REFERENCE_SYM) .. "{[^{}]+}", -- reference 1
			pattern_escape(REFERENCE_SYM) .. "%S+", -- reference 2
			pattern_escape(MATH_SYM) .. "[^" .. pattern_escape(MATH_SYM) .. "]+" .. pattern_escape(MATH_SYM), -- math
			pattern_escape(VARIABLE_SYM) .. "`[^`]+`", -- variable
			{pattern_escape(CODE_SYM) .. "+"}, -- code
			pattern_escape(UNDERLINE_SYM), -- underline
			pattern_escape(BOLD_SYM), -- bold
			pattern_escape(ITALIC_SYM), -- italic
			pattern_escape(STRIKETHROUGH_SYM), -- strikethrough
			"{" .. pattern_escape(DATA_SYM) .. ".-}" -- data
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
					r:match "^!%[(.-)%]",
					r:match "^!%[.-%]%((.+)%)"
				))
			elseif b == 3 then
				local p = markup.parse_text(r:sub(3, -3))
				push(markup.link(p, table.concat(map(get("content"), markup.scan.find_all_text(p, markup.filter.has_text)))))
			elseif b == 4 then
				push(markup.reference(r:sub(#REFERENCE_SYM + 2, -2)))
			elseif b == 5 then
				push(markup.reference(r:sub(#REFERENCE_SYM + 1)))
			elseif b == 6 then
				push(markup.math(r:sub(#MATH_SYM + 1, -#MATH_SYM - 1)))
			elseif b == 7 then
				push(markup.variable(r:sub(#VARIABLE_SYM + 2, -2)))
			elseif b == 8 then
				local l = #r:match(pattern_escape(CODE_SYM) .. "+")
				push(markup.code(r:sub(l + 1, -l - 1)))
			elseif b == 9 then
				mod(UNDERLINE_SYM, markup.underline)
			elseif b == 10 then
				mod(BOLD_SYM, markup.bold)
			elseif b == 11 then
				mod(ITALIC_SYM, markup.italic)
			elseif b == 12 then
				mod(STRIKETHROUGH_SYM, markup.strikethrough)
			elseif b == 13 then
				local s = r:sub(#DATA_SYM + 2, -2)
				local dt = s:match "^[%w+_%-]+" or ""
				push(markup.data(dt, s:sub(#dt + 1):gsub("^%s*", "")))
			end

			i = f + 1
		else
			local segment = text:match("^[^"
			.. "%[%]{}%(%)!`\\"
			.. pattern_escape(REFERENCE_SYM)
			.. pattern_escape(REFERENCE_SYM)
			.. pattern_escape(MATH_SYM)
			.. pattern_escape(VARIABLE_SYM)
			.. pattern_escape(CODE_SYM)
			.. pattern_escape(UNDERLINE_SYM)
			.. pattern_escape(BOLD_SYM)
			.. pattern_escape(ITALIC_SYM)
			.. pattern_escape(STRIKETHROUGH_SYM)
			.. pattern_escape(DATA_SYM)
			.. "]+", i)
			or text:match("^\\.", i)
			or text:sub(i, i)

			push(markup.text(segment:gsub("^\\", "")))
			i = i + #segment
		end
	end

	while #value_stack > 1 do
		pop()
	end

	return result

end

function generic_scan(f, options, populate, children_of)
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

-- filter
-- deep_update
-- no_filter_stop
-- include_unfiltered
function generic_update(f, options, children, children_of, set_children)
	local result = {}
	local changed = false
	local children_changed = false

	for i = 1, #children do
		local elem = children[i]

		if not options.filter or options.filter(elem) then
			local upd = f(elem)

			if upd and (#upd ~= 1 or upd[1] ~= elem) then
				for j = 1, #upd do
					result[#result + 1] = upd[j]
				end
				changed = true
			else
				result[#result + 1] = elem
			end
		elseif options.include_unfiltered then
			result[#result + 1] = elem
		else
			changed = true
		end

		if options.no_filter_stop then
			return result, changed or i ~= #children
		end
	end

	if options.deep_update then
		for i = 1, #result do
			local elem = result[i]
			local sub_children = children_of(elem)
			local upd_sub_children, sub_changed = generic_update(f, options, sub_children, children_of, set_children)

			if sub_changed then
				result[i] = set_children(elem, sub_children)
				children_changed = true
			end
		end

		if children_changed then
			return generic_update(f, options, result, children_of, set_children)
		end
	end

	return result, changed
end

-- splits a string into a list of its lines
function split_content_into_lines(text)
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

-- groups lines between multi-line code tags into a single line
function group_code_lines(lines)
	local result = {}
	local inCode = false

	for i = 1, #lines do
		if inCode then
			if lines[i]:find("^%s*" .. ("`"):rep(inCode) .. "%s*$") then
				inCode = false
			else
				insert(result, remove(result) .. "\n" .. lines[i])
			end
		else
			if lines[i]:find "^%s*```+[%w_%-]*%s*$" then
				inCode = #lines[i]:match "^%s*(```+)[%w_%-]*%s*$"
			end

			insert(result, (lines[i]:gsub("%s+$", "")))
		end
	end

	return result
end

-- removes lines containing only a comment
function remove_comment_lines(lines)
	local result = {}

	for i = 1, #lines do
		if lines[i]:find("^%s*" .. pattern_escape(LINE_COMMENT)) then
			result[i] = ""
		else
			result[i] = lines[i]
		end
	end

	return result
end

-- turns a list of lines into a structure with { indentation, sym, content }
-- `sym` is the beginning symbolic operator (e.g. '#' for a header)
function format_lines(lines)
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
			result.content = r:sub(#LIST_SYM + 1):gsub("^%s+", "")

		elseif r:sub(1, #LIST_SYM2 + 1) == LIST_SYM2 .. " " then
			result.sym = LIST_SYM
			result.content = r:sub(#LIST_SYM2 + 1):gsub("^%s+", "")

		elseif r:sub(1, #BLOCK_QUOTE_SYM + 1) == BLOCK_QUOTE_SYM .. " " then
			result.sym = BLOCK_QUOTE_SYM
			result.content = r:sub(#BLOCK_QUOTE_SYM + 2)

		elseif r:find("^" .. pattern_escape(HEADER_SYM) .. "+%s") then
			result.sym = HEADER_SYM
			result.size = #r:match("^" .. pattern_escape(HEADER_SYM) .. "+")
			result.content = r:match("^" .. pattern_escape(HEADER_SYM) .. "+%s+(.+)")

		elseif r:sub(1, #RESOURCE_SYM) == RESOURCE_SYM then
			result.sym = RESOURCE_SYM
			result.content = r:sub(#RESOURCE_SYM + 1)

		elseif not r:find("%S") then
			result.sym = EMPTY
			result.content = ""
		end

		output[i] = result
	end

	return output
end

-- makes groups of lines, delimited by EMPTY lines (not included in return)
function make_blocks_from_empty_lines(lines)
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
function make_blocks_from_different_syms(lines)
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
function create_block(lines)
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
			lines[1].content:match("^([^\n]+)\n")
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
function find_matches(text, pos, patterns)
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

function flat_map(f, list)
	local result = {}

	for i = 1, #list do
		local r = f(list[i])

		for j = 1, #r do
			insert(result, r[j])
		end
	end

	return result
end

function index_of(item, list)
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

function pattern_escape(pat)
	return pat:gsub("[%-%+%*%?%.%(%)%[%]%$%^]", "%%%1")
end

function indent(text, count)
	return ("\t"):rep(count or 1) .. text:gsub("\n", "\n" .. ("\t"):rep(count or 1))
end

function blocks_to_html(blocks, options)
	return table.concat(markup.util.map(function(block) return block_to_html(block, options) end, blocks), "\n\n")
end

function block_to_html(block, options)
	if block.type == markup.PARAGRAPH then
		if #block.content == 1 and block.content[1].type == markup.MATH then
			-- math paragraphs are rendered larger than their inline equivalent
			return "<img class=\"" .. markup.html.class(HTML_MATH, HTML_BLOCK) .. "\" "
			.. "alt=\"" .. markup.util.html_escape(block.content[1].content) .. "\" "
			.. "src=\"" .. HTML_MATH_URL .. "%5CLarge%20" .. markup.util.url_escape(block.content[1].content)
			.. "\">"
		else
			return "<p class=\"" .. markup.html.class(HTML_PARAGRAPH, HTML_BLOCK) .. "\">\n"
			.. markup.util.indent(inlines_to_html(block.content, options):gsub("\n", "<br>"))
			.. "\n</p>"
		end
	elseif block.type == markup.HEADER then
		local content = inlines_to_html(block.content, options)
		local id = markup.html.headerID(block)
		return "<h" .. block.size .. " id=\"" .. id .. "\" "
		.. "class=\"" .. markup.html.class(HTML_HEADER, HTML_HEADER .. block.size, HTML_BLOCK) .. "\">\n"
		.. markup.util.indent(content)
		.. "\n</h" .. block.size .. ">"
	elseif block.type == markup.LIST then
		return "<ul class=\"" .. markup.html.class(HTML_LIST, HTML_BLOCK) .. "\">\n"
		.. markup.util.indent(list_elements(block.items, options))
		.. "\n</ul>"
	elseif block.type == markup.BLOCK_CODE then
		local lang = block.language and block.language:lower():gsub("%s", "")
		local highlighted

		if options.highlighters[lang] then
			highlighted = tostring(options.highlighters[lang](block.content))
		else
			highlighted = "<pre class=\"" .. markup.html.class(HTML_BLOCK_CODE_CONTENT) .. "\">\n"
			.. markup.util.html_escape(block.content)
			.. "\n</pre>"
		end

		return "<div"
		.. (lang and " data-language=" .. lang or "")
		.. " class=\"" .. markup.html.class(HTML_BLOCK_CODE, HTML_BLOCK) .. "\">"
		.. highlighted
		.. "</div>"
	elseif block.type == markup.BLOCK_QUOTE then
		return "<blockquote class=\"" .. markup.html.class(HTML_BLOCK_QUOTE, HTML_BLOCK) .. "\">\n"
		.. blocks_to_html(block.content, options)
		.. "\n</blockquote>"
	elseif block.type == markup.RESOURCE then
		if options.loaders[block.resource_type] then
			return "<div class=\"" .. markup.html.class(HTML_BLOCK) .. "\">"
			.. tostring(options.loaders[block.resource_type](block.data))
			.. "</div>"
		else
			return block_format_error("no resource loader for '" .. block.resource_type .. "' :(")
		end
	elseif block.type == markup.HORIZONTAL_RULE then
		return "<hr class=\"" .. markup.html.class(HTML_HORIZONTAL_RULE, HTML_BLOCK) .. "\">"
	else
		return error("internal markup error: unknown block type (" .. tostring(block.type) .. ")")
	end
end

function inlines_to_html(inlines, options)
	return table.concat(markup.util.map(function(inline) return inline_to_html(inline, options) end, inlines))
end

function inline_to_html(inline, options)
	if inline.type == markup.TEXT then
		return "<span class=\"" .. markup.html.class(HTML_TEXT) .. "\">"
		.. markup.util.html_escape(inline.content)
		.. "</span>"
	elseif inline.type == markup.VARIABLE then
		return "<span class=\"" .. markup.html.class(HTML_VARIABLE) .. "\">"
		.. markup.util.html_escape(inline.content)
		.. "</span>"
	elseif inline.type == markup.CODE then
		return "<code class=\"" .. markup.html.class(HTML_CODE) .. "\">"
		.. markup.util.html_escape(inline.content)
		.. "</code>"
	elseif inline.type == markup.MATH then
		return "<img class=\"" .. markup.html.class(HTML_MATH) .. "\" "
		.. "alt=\"" .. markup.util.html_escape(inline.content) .. "\" "
		.. "src=\"" .. HTML_MATH_URL .. markup.util.url_escape(inline.content) .. "\">"
	elseif inline.type == markup.UNDERLINE then
		return "<u class=\"" .. markup.html.class(HTML_UNDERLINE) .. "\">"
		.. inlines_to_html(inline.content, options)
		.. "</u>"
	elseif inline.type == markup.BOLD then
		return "<strong class=\"" .. markup.html.class(HTML_BOLD) .. "\">"
		.. inlines_to_html(inline.content, options)
		.. "</strong>"
	elseif inline.type == markup.ITALIC then
		return "<i class=\"" .. markup.html.class(HTML_ITALIC) .. "\">"
		.. inlines_to_html(inline.content, options)
		.. "</i>"
	elseif inline.type == markup.STRIKETHROUGH then
		return "<del class=\"" .. markup.html.class(HTML_STRIKETHROUGH) .. "\">"
		.. inlines_to_html(inline.content, options)
		.. "</del>"
	elseif inline.type == markup.IMAGE then
		return "<img class=\"" .. markup.html.class(HTML_IMAGE) .. "\" "
		.. "alt=\"" .. markup.util.html_escape(inline.alt_text) .. "\" "
		.. "src=\"" .. inline.source .. "\">"
	elseif inline.type == markup.LINK then
		return "<a class=\"" .. markup.html.class(HTML_LINK) .. "\" "
		.. "href=\"" .. inline.url .. "\">"
		.. inlines_to_html(inline.content, options)
		.. "</a>"
	elseif inline.type == markup.DATA then
		return ""
	elseif inline.type == markup.REFERENCE then
		local link
		
		if type(options.reference_link) == "function" then
			link = options.reference_link(inline.reference)
		elseif type(options.reference_link) == "table" then
			link = options.reference_link[inline.reference]
		end

		if link then
			return "<a class=\"" .. markup.html.class(HTML_REFERENCE) .. "\" "
			.. "href=\"" .. tostring(link) .. "\">"
			.. inlines_to_html(inline.content, options)
			.. "</a>"
		else
			return format_error("no reference link for '" .. inline.reference .. "'")
		end
	else
		return error("internal markup error: unknown inline type (" .. tostring(inline.type) .. ")", 0)
	end
end

function list_elements(items, options)
	local lastIndent = items[1].level
	local baseIndent = lastIndent
	local s = list_item_to_html(items[1], options)

	local function line(content)
		s = s .. "\n" .. markup.util.indent(content, lastIndent - baseIndent)
	end

	for i = 2, #items do
		for _ = lastIndent, math.max(items[i].level, baseIndent) - 1 do
			line("<ul class=\"" .. markup.html.class(HTML_LIST) .. "\">"); lastIndent = lastIndent + 1; end
		for _ = math.max(items[i].level, baseIndent), lastIndent - 1 do
			lastIndent = lastIndent - 1; line("</ul>"); end

		line(list_item_to_html(items[i]))
	end

	for i = baseIndent, lastIndent - 1 do
		lastIndent = lastIndent - 1; line("</ul>"); end

	return s
end

function list_item_to_html(li, options)
	return "<li class=\"" .. markup.html.class(HTML_LIST_ITEM) .. "\">\n"
	.. markup.util.indent(inlines_to_html(li.content, options))
	.. "\n</li>"
end

function format_error(err)
	return "<span class=\"" .. markup.html.class(HTML_FORMAT_ERROR) .. "\">&lt; " .. markup.util.html_escape(err) .. " &gt;</span>"
end

function block_format_error(err)
	return "<p class=\"" .. markup.html.class(HTML_FORMAT_ERROR, HTML_BLOCK) .. "\">&lt; " .. markup.util.html_escape(err) .. " &gt;</p>"
end

markup.util.map = map
markup.util.get = get
markup.util.flat_map = flat_map
markup.util.index_of = index_of
markup.util.pattern_escape = pattern_escape
markup.util.last = last
markup.util.indent = indent

url_escape_table = {}

for i = 0, 255 do
	url_escape_table[string.char(i)] = "%" .. ("%02X"):format(i)
end

return markup
