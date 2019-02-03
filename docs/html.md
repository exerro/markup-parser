
# HTML submodule

## Library

### markup.html.render

```
string markup.html.render(block_node[] document, table? options)
```

Renders a document to HTML. $`options` is a table with the following optional properties:

```
(string -> string) options.highlighters[string language]
```

Returns HTML code for the given resource. Takes code body as parameter.

---

```
(string -> string) loaders[string resource_type]
```

Returns HTML code for the given resource. Takes `data` parameter.

---

```
table reference_link
function reference_link
```

If `reference_link` is a table, any reference will be looked up in the table. Otherwise, the function will be called with the reference.

### markup.html.CLASS\_PREFIX

```
string markup.html.CLASS_PREFIX = "mu"
```

### markup.html.headerID

```
string markup.html.headerID(header_node)
```

Returns the ID of the header, given its content. For example, `# Hello world!` will have headerID `hello-world`

### markup.html.class

```
string markup.html.class(string... classes)
```

Returns a formatted string of classes. For example `class("~a", "~b", "c")` equals `"mu-a mu-b c"`
