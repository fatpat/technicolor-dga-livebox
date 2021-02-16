#!/usr/bin/lua
local fti = arg[1]
if fti == nil or fti == '' then
	print("Missing argument, usage: " .. arg[0] .. " <fti identifier>")
	os.exit(1)
end

if not fti:find("^fti/[%d%a]+$") then
	print("Wrong fti identifier, it must start with `fti/`, got " .. fti)
	os.exit(1)
end
local out = ""
fti:gsub(".", function(c) out = out .. string.format("%x", c:byte()) end)
print(out)
