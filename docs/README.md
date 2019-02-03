
# Markup library

The markup library is used for parsing, manipulating, and rendering markup files.

## Submodules

* [filter](docs/filter.md)
* [HTML](docs/html.md)
* [scan](docs/scan.md)
* [update](docs/update.md)
* [util](docs/util.md)

## Syntax

The syntax is very similar to markdown.

* `##...` for headers
* `*` or `-` for lists
* ```` ``` ```` for multi-line code blocks
* `>` for block quotes
* `---` for horizontal rules
* `` ` `` for inline code sections
* `__` for underline
* `*` for bold
* `_` for italic
* `~~` for strikethrough
* `![alt-text](url)` for images
* `[display](url)` for links

There are a few other features, discussed below:

### Comments

Sometimes you want to annotate things, without them showing up in the document. For this, use `// stuff` on its own line - that line will be ignored.

### Resources

To allow maximum extensibility, the markup library allows for "resources" to be embedded in the document.

They're referenced like `::resource_type ...data`, and when the document goes to render, it'll use one of the render options to turn this into HTML.

For example, you might want to embed a code editor in the document. You might use `::interactive-editor lua`, and give in `function(language) return ... end` as `options.loaders["interactive-editor"]`.

### References

As the library is intended for use with not just single documents, but sets of documents, referencing between them will be a common thing. References are designed to handle this: `@ref` or `@{ref}`, with the latter supporting spaces. When a reference goes to be rendered, it'll pass through a function or table $`reference_link` in the HTML render options, to get its URL.

For example, you could set this up with a lookup table `{ ["ben"] = "/users/ben", ["eurobot"] = "/events/eurobot" }`.

### Variables

Variables are a different form of inline code section using the syntax `` $`var` ``. They're intended to be used when referencing parameters or variables. There's very little difference in what they look like by default, but they can have custom styling applied.

### Maths

Client-side LaTeX maths rendering is supported. Use `$$expr$$` to render some fancy maths. Note that if the maths section is in its own paragraph, it'll be rendered larger than if it is with other things. For example,

```
##### Big maths

$$ |v| = \sqrt{\sum v_i^2} $$

##### Small maths

Smaller: $$ |v| = \sqrt{\sum v_i^2} $$
```

##### Big maths

$$ |v| = \sqrt{\sum v_i^2} $$

##### Small maths

Smaller: $$ |v| = \sqrt{\sum v_i^2} $$

## Library

### markup.parse

```
block_node[] markup.parse(string document)
```

Parses a document, returning its AST.

### markup.parse\_text

```
inline_node[] markup.parse_text(string text)
```

Parses some inline text, returning its AST.

### markup.is\_node

```
boolean markup.is_node(any value)
```

Returns `true` if the value is a node

### markup.is\_block

```
boolean markup.is_block(node value)
```

Returns `true` if the value is a block node

### markup.is\_inline

```
boolean markup.is_inline(node value)
```

Returns `true` if the value is an inline node

### markup.tostring

```
string markup.tostring(node value)
string markup.tostring(node[] values)
```

Returns the string representation of either a node, or a list of nodes. The value of this function closely mirrors what would have been parsed to generate that value.

### AST Node constructors

The following constructors create a node of the respective type.
For each constructor there is a library constant for that node's type, which has a name equal to the uppercase of the constructor, e.g. `markup.text(...)` will create a node with $`type` equal to `markup.TEXT` The one exception to this is that the node type for `markup.rule()` is actually `markup.HORIZONTAL_RULE`, not `markup.RULE`

The constructors don't check parameters. However, For all parameters of type `inline_node[]` or `block_node[]`, a string may be given, and this will be automatically parsed.

* Jump to [Block nodes](#block-nodes)
* Jump to [Inline nodes](#inline_nodes)

#### Block nodes

```
markup.paragraph(inline_node[] content)
```

---

```
markup.header(inline_node[] content, int size)
```

> $`size` is an integer between 1 and 6, corresponding to `h1`, `h3`, `h6` etc in the html.

---

```
markup.list(table items)
```

> $`items` is a list containing objects structured as follows:
> ```
> {
> 	int level,
> 	inline_node[] content
> }
> ```

---

```
markup.code_block(string content, string? language)
```

---

```
markup.block_quote(block_node[] content)
```

---

```
markup.resource(string resource_type, string data)
```

> See [Resources](#resources)

---

```
markup.rule()
```

#### Inline nodes

```
markup.text(string content)
```

---

```
markup.variable(string content)
```

> See [Variables](#variables)

---

```
markup.code(string content)
```

---

```
markup.math(string content)
```

> See [Maths](#maths)

---

```
markup.underline(inline_node[] content)
```

---

```
markup.bold(inline_node[] content)
```

---

```
markup.italic(inline_node[] content)
```

---

```
markup.strikethrough(inline_node[] content)
```

---

```
markup.image(string alt_text, string source)
```

---

```
markup.link(inline_node[] content, string url)
```

---

```
markup.reference(inline_node[] content, string? reference)
```

> If $`reference` isn't given (is falsey), it will be derived from $`content`
> See [References](#references)
