
# Util submodule

The `util` submodule contains a set of miscellaneous utilities.

## Library

### markup.util.pattern\_escape

```
string markup.util.pattern_escape(string text)
```

Escapes Lua pattern special characters.

### markup.util.html\_escape

```
string markup.util.html_escape(string text)
```

Escapes HTML special characters.

### markup.util.url\_escape

```
string markup.util.url_escape(string text)
```

Escapes URL special characters.

### markup.util.map

```
table markup.util.map(func, table list)
```

Maps $`func` to $`list` and returns the result.

### markup.util.flat\_map

```
table markup.util.flat_map(func, table list)
```

Maps $`func` to $`list` and returns the concatenation of the results.

### markup.util.get

```
(table -> any) markup.util.get(string key)
```

Returns a function, getting $`key` of the object given to it.

### markup.util.index\_of

```
int markup.util.index_of(any item, table list)
```

Returns the index of the item in the table.

### markup.util.last

```
any markup.util.last(table)
```

Returns the last item in the list.

### markup.util.indent

```
string markup.util.indent(string text, int count = 1)
```

Indents the string with $`count` tabs, taking into account newlines.
