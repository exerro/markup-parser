
# Scan submodule

The `scan` submodule provides functions for scanning through documents and finding particular nodes. It relies heavily on the [filter](docs/filter.md) submodule.
All parameters or fields named `filter` have type `filter`, from the `filter` submodule. In addition, all parameters named `scan_type` must equal either `markup.scan.document` or `markup.scan.text`.

## Library

> Note that for all functions below, `document` has type `block_node[]` (i.e. the result of `markup.parse()`), but for text variants, this parameter also accepts `inline_node[]` (i.e. the result of `markup.parse_text()`).

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
block_node? markup.scan.find_first(scan_type, document, filter, boolean deep_scan)
```

Returns the first node matching the filter.

### markup.scan.find\_all

```
block_node[] markup.scan.find_all(scan_type, document, filter, boolean deep_scan)
```

Returns all nodes matching the filter.
