local _S = {}

if cprint == nil then cprint = function() end end	-- OC compat
function _S.get_event() return table.pack(computer.pullSignal(0)) or {} end

return _S
