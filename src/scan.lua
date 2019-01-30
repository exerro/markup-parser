
local markup = require "src.markup"

local scan = {}

local update, updateIgnoreUnfiltered, genericScan, updateBlocks, updateBlockChildren, updateInlines, updateInlineChildren

-- options includes filter, single_pass, include_unfiltered

function scan.updateDocument(document, f, options)
	return updateBlocks(document, f, options or {})
end

function scan.updateBlocks(document, f, options)
	return updateIgnoreUnfiltered(document, f, options or {}, markup.isBlock)
end

function scan.updateInlines(document, f, options)
	return updateIgnoreUnfiltered(document, f, options or {}, markup.isInline)
end

function scan.scanDocument(document, f, options)
	return genericScan(scan.updateDocument, document, f, options or {})
end

function scan.scanBlocks(document, f, options)
	return genericScan(scan.updateBlocks, document, f, options or {})
end

function scan.scanInlines(document, f, options)
	return genericScan(scan.updateInlines, document, f, options or {})
end

function update(t, f, options, upd, updc)
	local res = {}
	local changed, cchanged = false, false

	for i = 1, #t do
		local item = t[i]

		if not options.filter or options.filter(item) then
			local res_f = f(item)

			if res_f == nil or #res_f == 1 and res_f[1] == item then
				res[#res + 1] = item
			else
				if not options.single_pass then
					res_f = upd(res_f, f, options)
				end

				changed = true

				for j = 1, #res_f do
					res[#res + 1] = res_f[j]
				end
			end
		elseif options.include_unfiltered then
			res[#res + 1] = item
		else
			changed = true
		end
	end

	for i = 1, #res do
		cchanged = updc(res[i], f, options) or cchanged
	end

	if cchanged and not options.single_pass then
		return update(res, f, options, upd, updc)
	end

	if not changed and not cchanged then
		return t, false
	end

	return res, changed or cchanged
end

function updateIgnoreUnfiltered(document, f, options, testFilter)
	local filter = options.filter
	local include_unfiltered = options.include_unfiltered

	return scan.updateDocument(
		document,
		function(node, ...)
			if not filter or filter(node) then
				return f(node, ...)
			elseif include_unfiltered then
				return nil
			else
				return {}
			end
		end,
		{
			filter = testFilter,
			include_unfiltered = true,
			single_pass = options.single_pass
		}
	)
end

function genericScan(func, document, f, options)
	return func(
		document,
		function(...)
			f(...)
			return nil
		end,
		setmetatable({
			include_unfiltered = true,
		}, {
			__index = options
		})
	)
end

function updateBlocks(blocks, f, options)
	return update(blocks, f, options, updateBlocks, updateBlockChildren)
end

function updateBlockChildren(block, f, options)
	local changed = false

	if block.type == markup.PARAGRAPH or block.type == markup.HEADER then
		block.content, changed = updateInlines(block.content, f, options)
	elseif block.type == markup.LIST then
		local _changed

		for i = 1, #block.items do
			block.items[i].content, _changed = updateInlines(block.items[i].content, f, options)
		end

		changed = changed or _changed
	elseif block.type == markup.BLOCK_QUOTE then
		block.content, changed = updateBlocks(block.content, f, options)
	end

	return changed
end

function updateInlines(inlines, f, options)
	return update(inlines, f, options, updateInlines, updateInlineChildren)
end

function updateInlineChildren(inline, f, options)
	local changed = false

	if inline.type == markup.UNDERLINE
	or inline.type == markup.BOLD
	or inline.type == markup.ITALIC
	or inline.type == markup.STRIKETHROUGH
	or inline.type == markup.LINK
	or inline.type == markup.RELATIVE_LINK
	or inline.type == markup.REFERENCE
	then
		inline.content, changed = updateInlines(inline.content, f, options)
	end

	return changed
end

return scan
