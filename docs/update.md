
# Update submodule

The `update` submodule provides functions for updating the contents of documents, including removing, inserting, and replacing nodes. It relies heavily on the [filter](docs/filter.md) submodule.
All parameters or fields named `filter` have type `filter`, from the `filter` submodule. In addition, all parameters named `update_type` must equal either `markup.update.document` or `markup.update.text`.

## Library

> Note that for all functions below, `document` has type `block_node[]` (i.e. the result of `markup.parse()`), but for text variants, this parameter also accepts `inline_node[]` (i.e. the result of `markup.parse_text()`).

### markup.update.document

```
markup.update.document(document, (block_node -> block_node[]?) f, table options)
```

where `options` is a table with optional fields

```
(block_node -> boolean) filter
boolean no_filter_stop
boolean include_unfiltered
boolean deep_update
```

Updates the document using function $`f`. $`f` may return a list of 0 or more nodes to replace what it was called with, or `nil` to make no changes. Returning `{node}` and `nil` are identical, if `node` is what was passed to the function.

The function $`f` is only called if the filter matches the node. Otherwise, whether the node will be included in the result is determined by $`include_unfiltered`, where a value of `true` indicates that it will. If the filter fails for a node, and $`no_filter_stop` is `true`, all further updating will stop (ignoring further children even if $`include_unfiltered` is `true`). If $`deep_update` is `true`, children of nodes will also be updated in a recursive manner (after the parent).

Note that if a filter fails for a node, $`include_unfiltered` is `true`, and and $`no_filter_stop` is `true`, that node *will* be included in the result.

> $`deep_update` defaults to `true`

### markup.update.text

```
markup.update.text(document, (inline_node -> inline_node[]?) f, table options)
```

where `options` is a table with optional fields

```
(block_node -> boolean) block_filter
(inline_node -> boolean) filter
boolean no_filter_stop
boolean block_include_unfiltered
boolean include_unfiltered
boolean deep_update
```

Works similarly to [`markup.update.document`](#markup-update-document), but for inlines. $`block_filter` may be used to filter the block nodes for which inlines will be sourced from.

### markup.update.insert_after

```
markup.update.insert_after(update_type, document, filter, node insertion, boolean many, boolean deep_update)
```

Inserts the node $`insertion` after a node matching $`filter`. If `many` is `true`, this will happen for all nodes matching $`filter`.

### markup.update.insert_before

```
markup.update.insert_before(update_type, document, filter, node insertion, boolean many, boolean deep_update)
```

Inserts the node $`insertion` before a node matching $`filter`. If `many` is `true`, this will happen for all nodes matching $`filter`.

### markup.update.remove

```
markup.update.remove(update_type, document, filter, boolean many, boolean deep_update)
```

Removes a node matching $`filter`. If `many` is `true`, this will happen for all nodes matching $`filter`.

### markup.update.remove_after

```
markup.update.remove_after(update_type, document, filter, boolean many, boolean deep_update)
```

Removes all nodes after one matching $`filter`.

### markup.update.remove_before

```
markup.update.remove_before(update_type, document, filter, boolean many, boolean deep_update)
```

Removes all nodes before one matching $`filter`.

### markup.update.replace

```
markup.update.replace(update_type, document, filter, (node -> node[]?) map, boolean many, boolean deep_update)
markup.update.replace(update_type, document, filter, node map, boolean many, boolean deep_update)
```

Replaces a node matching $`filter`. If `many` is `true`, this will happen for all nodes matching $`filter`. $`map` may be either a node used for direct replacement, or a function mapping a node to an optional list of other nodes as with the $`f` parameter to `markup.update.document` and `markup.update.text`.
