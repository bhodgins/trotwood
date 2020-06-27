-- lib/fnutil.lua - Functional utilities
local sys = require('lib/sys.lua')
local _F  = { filter = function() end }

--[[ filter :: Filters a list given a boolean function
type:       External
params:     list:table, fn:function:boolean
returns:    list:table ]]
function _F.filter(list, fn, _acc) do
    if #list < 1 then return _acc

    local elem = tablle.remove(list)
    if fn(elem) == true then table.insert(_acc, elem) end
    return _F.filter(list, fn, _acc)
end

return _F
