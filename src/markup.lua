
--[[

	a list of blocks contains items as follows:
	note that `inline-text` represents the inline text format, which is described below

		{
			type = markup.PARAGRAPH,
			content = inline-text
		}

		{
			type = markup.HEADER,
			size = N                          ; N is an integer 1-6 inclusive representing how "big" the header is (1 being largest)
			content = inline-text
		}

		{
			type = markup.LIST,
			items = {
				[n] = {                       ; n is an integer 1 to N where N is the number of items in the list
					content = inline-text,
					level = L                 ; L is the level at which the item is shown, e.g. 1 for indented once, 0 for no indentation
				}
			}
		}

		{
			type = markup.BLOCK_CODE,
			language = L,                     ; L is an optional string language which the code is in (may be nil)
			content = S                       ; S is the string content of the code
		}

		{
			type = markup.BLOCK_QUOTE,
			content = {
				[n] = block                   ; n is an integer 1 to N where N is the number of blocks in the list
			}
		}

		{
			type = markup.RESOURCE,
			resource = R                      ; R is a string representing the resource to insert
		}

		{
			type = markup.HORIZONTAL_RULE
		}

	the inline text format is a list of items as follows:

		{
			type = markup.TEXT,
			content = S                       ; S is the string content of the text
		}

		{
			type = markup.VARIABLE,
			variable = V                      ; V is the string variable name
		}

		{
			type = markup.CODE,
			content = S                       ; S is the string content of the code
		}

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
			type = markup.IMAGE,
			alt_text = A,                     ; A is the string alt-text to use
			source = S                        ; S is the string source of the image
		}

		{
			type = markup.LINK,
			content = inline-text,            ; this is the text to display
			url = U                           ; U is the string url target of the link
		}

		{
			type = markup.RELATIVE_LINK,
			content = inline-text,            ; this is the text to display
			url = U                           ; U is the string url target of the link
		}

		{
			type = markup.REFERENCE,
			content = inline-text             ; this is the text to display
			reference = T                     ; T is the string reference target
		}

]]

local markup = {}

-- inline types
markup.TEXT = "text"
markup.VARIABLE = "variable"
markup.CODE = "code"
markup.UNDERLINE = "underline"
markup.BOLD = "bold"
markup.ITALIC = "italic"
markup.STRIKETHROUGH = "strikethrough"
markup.IMAGE = "image"
markup.LINK = "link"
markup.RELATIVE_LINK = "relative-link"
markup.REFERENCE = "reference"

-- block types
markup.PARAGRAPH = "paragraph"
markup.HEADER = "header"
markup.LIST = "list"
markup.BLOCK_CODE = "block-code"
markup.BLOCK_QUOTE = "block-quote"
markup.RESOURCE = "resource"
markup.HORIZONTAL_RULE = "horizontal-rule"

return markup
