
/-
	If you're seeing this, the document hasn't been rendered with the correct markdown renderer.
	There may be slight issues in the body of the document as a result.
-/

# Using markup

### Contents

* [The language](#the-language)
	* [Overview](#overview)
	* [Comments](#comments)
	* [Variables](#variables)
	* [Resources](#resources)
	* [References](#references)
* [Using the library](#using-the-library)
	* [Library functions](#library-functions)
		* [`markup.parse`](#markup-parse)
* [HTML output](#html-output)
	* [`html.render()`](#html-render)
	* [`html.escape()`](#html-escape)
	* [`html.codeEnclose()`](#html-codeenclose)
	* [`html.setSyntaxHighligher()`](#html-setsyntaxhighligher)
	* [`html.setResourceLoader()`](#html-setresourceloader)
	* [`html.setRelativeLinkFormatter()`](#html-setrelativelinkformatter)
	* [`html.setReferenceFormatter()`](#html-setreferenceformatter)
	* [`html.defaultRelativeLinkFormatter()`](#html-defaultrelativelinkformatter)
* [AST structure](#ast-structure)
	* [Blocks](#blocks)
		* [Paragraph block](#paragraph-block)
		* [Header block](#header-block)
		* [List block](#list-block)
		* [Code block](#code-block)
		* [Block quote](#block-quote)
		* [Resource block](#resource-block)
		* [Horizontal rule](#horizontal-rule)
	* [Inlines](#inlines)
		* [Text](#text-inline)
		* [Variable](#variable-inline)
		* [Code](#code-inline)
		* [Underline](#underline-inline)
		* [Bold](#bold-inline)
		* [Italic](#italic-inline)
		* [Strikethrough](#strikethrough-inline)
		* [Image](#image-inline)
		* [Link](#link-inline)
		* [Relative link](#relative-link-inline)
		* [Reference](#reference-inline)
* [Configurability](#configurability)
	* [`CLASS_PREFIX`](#class_prefix)
	* [`LINE_COMMENT`](#line_comment)
	* [`MULTILINE_COMMENT_OPEN`](#multiline_comment_open)
	* [`MULTILINE_COMMENT_CLOSE`](#multiline_comment_close)
	* [`HEADER_SYM`](#header_sym)
	* [`LIST_SYM`](#list_sym)
	* [`LIST_SYM2`](#list_sym2)
	* [`RULE_SYM`](#rule_sym)
	* [`BLOCK_CODE_SYM`](#block_code_sym)
	* [`BLOCK_QUOTE_SYM`](#block_quote_sym)
	* [`RESOURCE_SYM`](#resource_sym)
	* [`UNDERLINE_SYM`](#underline_sym)
	* [`BOLD_SYM`](#bold_sym)
	* [`ITALIC_SYM`](#italic_sym)
	* [`STRIKETHROUGH_SYM`](#strikethrough_sym)
	* [`VARIABLE_SYM`](#variable_sym)
	* [`CODE_SYM`](#code_sym)
	* [`REFERENCE_SYM`](#reference_sym)

## The language

### Overview

The core of the language is very similar to markdown.

### Comments

The language supports single-line and multi-line comments, using the following syntax:

```
// single line comment
```

```
/- multi line
comment -/
```

### Variables

Variables are intended to act similar to `` `code` `` inlines, but specifically for referring to variables.

### Resources

Due to the extensible nature of the library, resources are intended to be arbitrary sections in the document. They won't render anything by default. Any custom sections in the document, for example an interactive area, should use a resource.

### References

References are intended to refer to other documents within the current context, for example within an application, website, or wiki. Similar to relative links, references embed an `<a>` tag in the document when rendered. The difference is that the link url must first pass through a reference formatter, turning the reference into a URL.

## Using the library

To load the library, use...

```lua
local markup = require("src.markup")
```

To load parsing capabilities, use...

```lua
local parse = require("src.parse")
```

### Library functions

#### markup.parse()

```
AST markup.parse(string markup_text)
```

Parses the markup text and returns its AST (a list of blocks).

## HTML output

To load the HTML renderer, use...

```lua
local html = require("src.html")
```

#### html.render()

```
string html.render(AST document, string[]? styles)
string html.render(string document, string[]? styles)
```

Renders the document to a HTML document. For any style in $`styles`, that style is `@import`-ed automatically. For example, the following example would insert `@import url("css/style.css");` into the top of the rendered document.

```
html.render(document, {"css/style.css"})
```

#### html.escape()

```
string html.escape(string text)
```

Returns the html-escaped version of $`text`. For example, `html.escape("<a>")` returns `"&lt;a&gt;"`.

#### html.codeEnclose()

```
string html.codeEnclose(string text, string language)
```

Encloses the text given in a code block (a `div` with correct classes).

#### html.setSyntaxHighligher()

```
html.setSyntaxHighligher(string language, (string -> string) highlighter)
```

Sets the syntax highlighter for a language. The highlighter is a function that should return highlighted HTML code for its input.

> Note that no formatting is done if there is a highlighter for a language. What is returned is what is rendered. Use [`html.codeEnclose()`](#html.codeenclose) to wrap the returned value in a properly formatted `div`.

#### html.setResourceLoader()

```
html.setResourceLoader((string -> string) loader)
```

Sets the resource loader. The loader is a function that should return HTML code for its input (the resource identifier).

> Note that the returned string is wrapped in a `div` element with class `md-block`.

#### html.setRelativeLinkFormatter()

```
html.setRelativeLinkFormatter((string -> string) formatter)
```

Sets the relative link formatter. The formatter is a function that should return the URL of the given relative link.

> Note the existence of [`html.defaultRelativeLinkFormatter`](#html-defaultrelativelinkformatter).

#### html.setReferenceFormatter()

```
html.setReferenceFormatter((string -> string) formatter)
```

Sets the reference formatter. The formatter is a function that should return the URL of the given reference.

#### html.defaultRelativeLinkFormatter()

```
string html.defaultRelativeLinkFormatter(string link)
```

Is the identity function (returns its input, $`link`).

## AST structure

The AST is comprised of blocks and inline text items.

### Blocks

#### Paragraph block

```
type = markup.PARAGRAPH
content : inline-text-item[]
```

The content of the paragraph, formatted as a list of inline text items.

#### Header block

```
type = markup.HEADER
size : [1, 6]
content : inline-text-item[]
```

The content of a header. $`size` ranges between 1 and 6, equal to the size of the header (`h1`, `h3`, `h6` etc).

#### List block

```
type = markup.LIST
items : {
	[n] : {
		content : inline-text-item[]
		level : int
	}
}
```

The content of a list. Each numerically indexed item (`1 .. #items`) is a table containing the content of that item, and its indentation ($`level`).

#### Code block

```
type = markup.BLOCK_CODE
language : string?
content : string
```

The content of a code block. Language may be `nil`.

#### Block quote

```
type = markup.BLOCK_QUOTE
content : block[]
```

The content of a block quote. $`content` is a list of blocks.

#### Resource block

```
type = markup.RESOURCE
resource : string
```

$`resource` is the string representing the resource to load. See [resources](#resources).

#### Horizontal rule

```
type = markup.HORIZONTAL_RULE
```

### Inlines

> Most inlines are self explanatory and therefore have no description.

#### Text (inline)

```
type = markup.TEXT
content : string
```

#### Variable (inline)

```
type = markup.VARIABLE
variable : string
```

#### Code (inline)

```
type = markup.CODE
content : string
```

#### Underline (inline)

```
type = markup.UNDERLINE
content : inline-text-item[]
```

#### Bold (inline)

```
type = markup.BOLD
content : inline-text-item[]
```

#### Italic (inline)

```
type = markup.ITALIC
content : inline-text-item[]
```

#### Strikethrough (inline)

```
type = markup.STRIKETHROUGH
content : inline-text-item[]
```

#### Image (inline)

```
type = markup.IMAGE,
alt_text : string
source : string
```

#### Link (inline)

```
type = markup.LINK
content : inline-text-item[]
url : string
```

#### Relative link (inline)

```
type = markup.RELATIVE_LINK
content : inline-text-item[]
url : string
```

#### Reference (inline)

```
type = markup.REFERENCE
content : inline-text-item[]
reference : string
```

## Configurability

Various aspects of the library are configurable. These can affect parsing and HTML code generation.

### `CLASS_PREFIX`

Defines the class prefix to prepend to all css classes when outputting html.

```
html.CLASS_PREFIX = "md-"
```

### `LINE_COMMENT`

Defines the line comment symbol.

```
parse.LINE_COMMENT = "//"
```

### `MULTILINE_COMMENT_OPEN`

Defines the multi-line comment opening symbol.

```
parse.MULTILINE_COMMENT_OPEN = "/-"
```

### `MULTILINE_COMMENT_CLOSE`

Defines the multi-line comment closing symbol.

```
parse.MULTILINE_COMMENT_CLOSE = "-/"
```

### `HEADER_SYM`

Defines the header-block symbol.

```
parse.HEADER_SYM = "#"
```

### `LIST_SYM`

Defines the list-item symbol.

```
parse.LIST_SYM = "*"
```

### `LIST_SYM2`

Defines the secondary list-item symbol.

```
parse.LIST_SYM2 = "-"
```

### `RULE_SYM`

Defines the horizontal rule symbol.

```
parse.RULE_SYM = "---"
```

### `BLOCK_CODE_SYM`

Defines the block code symbol.

```
parse.BLOCK_CODE_SYM = "```"
```

### `BLOCK_QUOTE_SYM`

Defines the block quote symbol.

```
parse.BLOCK_QUOTE_SYM = ">"
```

### `RESOURCE_SYM`

Defines the resource symbol.

```
parse.RESOURCE_SYM = ":"
```

### `UNDERLINE_SYM`

Defines the underline open/close symbol.

```
parse.UNDERLINE_SYM = "__"
```

### `BOLD_SYM`

Defines the bold open/close symbol.

```
parse.BOLD_SYM = "*"
```

### `ITALIC_SYM`

Defines the italic open/close symbol.

```
parse.ITALIC_SYM = "_"
```

### `STRIKETHROUGH_SYM`

Defines the strikethrough open/close symbol.

```
parse.STRIKETHROUGH_SYM = "~~"
```

### `VARIABLE_SYM`

Defines the variable symbol. Note that the syntax supports `` $`var` ``.

```
parse.VARIABLE_SYM = "$"
```

### `CODE_SYM`

Defines the code open/close symbol. Note that `n` repetitions of this can be used to open/close code sections. E.g. ``` `` `escaped` `` ```.

```
parse.CODE_SYM = "`"
```

### `REFERENCE_SYM`

Defines the reference symbol. Note that the syntax supports *_both_* `@ref` and `@(ref)`.

```
parse.REFERENCE_SYM = "@"
```

