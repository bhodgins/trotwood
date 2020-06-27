-- This file has been obtained from https://git.shadowkat.net/izaya/OC-PsychOS2/src/branch/master/lib/libmtar.lua and is subject to copyright disclosed there.
-- Please refer to the MPLv2 license for licensing at the time of its implementation for this file here: https://www.mozilla.org/en-US/MPL/2.0/

local mtar = {}

local function toint(s)
 local n = 0
 local i = 1
 for p in s:gmatch(".") do
  n = n << 8
  n = n | string.byte(p)
  i=i+1
 end
 return n
end

local function cint(n,l)
 local t={}
 for i = 0, 7 do
  t[i+1] = (n >> (i * 8)) & 0xFF
 end
 return string.reverse(string.char(table.unpack(t)):sub(1,l))
end

local function cleanPath(path)
 local pt = {}
 for segment in path:gmatch("[^/]+") do
  if segment == ".." then
   pt[#pt] = nil
  elseif segment ~= "." then
   pt[#pt+1] = segment
  end
 end
 return table.concat(pt,"/")
end

function mtar.genHeader(fname,len) -- string number -- string -- generate a header for file *fname* when provided with file length *len*
 return string.format("%s%s%s",cint(fname:len(),2),fname,cint(len,2))
end

function mtar.iter(stream) -- table -- function -- Given buffer *stream*, returns an iterator suitable for use with *for* that returns, for each iteration, the file name, a function to read from the file, and the length of the file.
 local remain = 0
 local function read(n)
  local rb = stream:read(math.min(n,remain))
  remain = remain - rb:len()
  return rb
 end
 return function()
  stream:read(remain)
  local nlen = toint(stream:read(2) or "\0\0")
  if nlen == 0 then
   return
  end
  local name = cleanPath(stream:read(nlen))
  local fsize = toint(stream:read(2))
  remain = fsize
  return name, read, fsize
 end
end

return mtar