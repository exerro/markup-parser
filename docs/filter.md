
# Filter submodule

## Library

The submodule introduces a new type, the `filter`.
Filters may be called with a node (`filter(node)`), multiplied `filter1 * filter2`, and divided `filter1 / filter2`.

Multiplication of two filters will give a new filter representing the intersection of both, i.e. `(filter1 * filter2)(node) == (filter1(node) and filter2(node))`.

Division of two filters will give a new filter representing the union of both, i.e. `(filter1 / filter2)(node) == (filter1(node) or filter2(node))`.

Note that multiplication and division of filters may also have functions as rvalues, i.e. the following is valid:

```
local myFilter = filter1
               * function(node)
                     return f(node)
                 end
               * function(node)
                     return g(node)
                 end
```

### markup.filter.new

```
filter markup.filter.new((node -> bool) predicate)
```

Creates a new filter from a predicate.

### markup.filter.type

```
filter markup.filter.type(node_type)
```

Returns a filter matching only nodes with type $`node_type`.

### markup.filter.inline

```
filter markup.filter.inline
```

Is a filter matching only nodes that are inline

### markup.filter.block

```
filter markup.filter.block
```

Is a filter matching only nodes that are blocks

### markup.filter.has\_text

```
filter markup.filter.has_text
```

Is a filter matching only nodes of type `markup.TEXT`, `markup.CODE` or `markup.VARIABLE`. The text contents of these nodes is accessible through `node.content`.
