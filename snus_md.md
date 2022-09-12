
# snus_md
### This module is used for extraction MD inlines from Lua scripts.
#### Usage:
`lua snus_md.lua -i myscript.lua [-i anotherscript.lua, ...] -o README.md`

This will extract all md blocks
```
--[[!MD 
# markdown text
## some headers
### function definition
some text
]]
```

From all input files to -o file.
