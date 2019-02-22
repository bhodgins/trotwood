-- lib/gtty/gtty/lua :: Graphical Terminal Library for Trotwood

local _T = {}

local driver = {}
if     _SYSTEM == 'OpenComputers' then driver = require('lib/gtty/oc.lua')
elseif _SYSTEM == 'ComputerCraft' then driver = require('lib/gtty/cc.lua') end


--[[ tokenize :: Tokenizes a string by control character
type:       Internal
params:     buf:string, [acc:table]
returns:    tokens:table ]]
local function tokenize(buf, acc)
  local ctrl_pos = buf:find('%c')

  if ctrl_pos == nil then
    if buf ~= "" then table.insert(acc, buf) end
    return acc
  elseif ctrl_pos == 1 then table.insert(acc, buf:sub(1, 1))
  else -- >1
    table.insert(acc, buf:sub(1, ctrl_pos - 1))
    table.insert(acc, buf:sub(ctrl_pos, ctrl_pos))
  end

  return tokenize( buf:sub(ctrl_pos + 1, buf:len()), acc )
end

--[[ put :: Sends data to the terminal for processing
type:       External
params:     data:string
returns:    terminal:table ]]
function _T.put(terminal, data) return driver.process(terminal, tokenize(data, {})) end

--[[ resize:: Resizes terminal to fit the gpu output
type:       Delegate
params:     terminal:table
returns:    terminal:table ]]
function _T.resize(terminal) return driver.resize(terminal) end

return _T
