
local parse = require "src.parse"
local debug = require "src.debug"
local html = require "src.html"

local result = parse.parse([=[

# Header
## hello

This is nothing

> @ref $var [[`hello`]] `code` ~~strikethrough~~ _italic_ *bold* __underlined__
> ![alt](src)
> [link text](hello)

* list item 1
  * list item 2
*   list item 3

----

:interactive code

```lua
this is

some code
```

### ~~  hello world~~

more
stuff
more
stuff
more
stuff
more
stuff
more
stuff
more
stuff
more
stuff
more
stuff
more
stuff
more
stuff
more
stuff
more
stuff
more
stuff
more
stuff
more
stuff
more
stuff
more
stuff
more
stuff
more
stuff
more
stuff
more
stuff
more
stuff
more
stuff
more
stuff
more
stuff
more
stuff

# last

]=])

local h = io.open("out.html", "w")
h:write("<style> @import url('src/style.css'); @import url('global-style.css'); </style>")
h:write(html.blocksToHTML(result))
h:close()
