local _S = {}

if cprint == nil then cprint = function() end end	-- OC compat
function _S.get_event() return table.pack(computer.pullSignal(0)) or {} end

if _OSVERSION ~= nil then
    if _string.find(_OSVERSION, "OpenOS") ~= nil then
        -- Filesystem is just like on standard stub and we expect to use managed disks:
        function _S.require(resource)
            local _d = resource:find('://')
            local namespace = resource:sub(1, _d - 1)
            local path      = resource:sub(_d + 3)
        
            return require(namespace .. '/' .. path)
        end
    end
end

return _S
