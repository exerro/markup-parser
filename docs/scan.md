
# Scan submodule

The `scan` submodule provides functions for scanning through documents and finding particular nodes. It relies heavily on the [filter](docs/filter.md) submodule.
All parameters or fields named `filter` have type `filter`, from the `filter` submodule.

## Library

Note that for all functions below, `document` has type `block_node[]` (i.e. the result of `markup.parse()`, or for `_text` variants, also accepts `inline_node[]`.

### markup.scan.document

```
markup.scan.document(document, (block_node -> void) f, table options)
```

where `options` is a table with optional fields

```
(block_node -> boolean) filter
boolean no_filter_stop
boolean deep_scan
```

Scans a document, calling `f` for all block nodes scanned. A node will only be scanned if the filter matches the node. If the filter fails for a node, and $`no_filter_stop` is `true`, all scanning will stop. If $`deep_scan` is `true`, children of nodes will also be scanned (after the parent).

> $`deep_scan` defaults to `true`

### markup.scan.text

```
markup.scan.text(document, (inline_node -> void) f, options)
```

where `options` is a table with optional fields

```
(block_node -> boolean) block_filter
(inline_node -> boolean) filter
boolean no_filter_stop
boolean deep_scan
```

Works similarly to [`markup.scan.document`](#markup-scan-document), but for inlines. $`block_filter` may be used to filter the block nodes for which inlines will be sourced from.

### markup.scan.find\_first

```
block_node? markup.scan.find_first(document, filter, boolean deep_scan)
```

Returns the first block node matching the filter.

### markup.scan.find\_first\_text

```
inline_node? markup.scan.find_first_text(document, filter, boolean deep_scan)
```

Returns the first inline node matching the filter.

### markup.scan.find\_all

```
block_node[] markup.scan.find_all(document, filter, boolean deep_scan)
```

Returns all block nodes matching the filter.

### markup.scan.find\_all\_text

```
inline_node[] markup.scan.find_all_text(document, filter, boolean deep_scan)
```

Returns all inline nodes matching the filter.
