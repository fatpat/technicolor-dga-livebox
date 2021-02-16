#!/usr/bin/lua
--
-- Credits to @LukePicci from https://forums.whirlpool.net.au/archive/9vxxl849-9#r68653633
-- for the discovery to replace 90 by something else
--
-- the file to patch
local p = "/usr/sbin/odhcpc"

-- ensure the file has not already been patched
-- if it returns 0, it's already been patched
if os.execute(p .. " -x 90:aa >/dev/null 2>&1") == 0 then
	print(p .. " seems to be already patched, it already accepts option 90, skipping !")
	return
end

print("Patching ... " .. p)

-- the source, is present in the readonly rom (in /rom)
local i = io.open("/rom" .. p, "r")

-- remove the destination file to prevent ETXTBSY errors
os.remove(p)

-- open the file as writeonly
local o = io.open(p, "w")

-- read, replace \0\0\0\90\0\0\0\0\0\0\0 by \0\0\0\89\0\0\0\0\0\0\0 and write
o:write(string.gsub(i:read("*all"), "%z%z%z\90%z%z%z%z%z%z%z", "\0\0\0\89\0\0\0\0\0\0\0"))

-- close files
i:close()
o:close()

-- restore rights
os.execute("chmod 0755 " .. p)

print(p .. " successfully patched, you can restart network now")
