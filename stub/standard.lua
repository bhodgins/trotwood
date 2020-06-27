local _S = {}

if print  ~= nil then cprint = print end

function _S.get_event() end -- Do nothing

function _S.require(resource)
    local _d = resource:find('://')
    local namespace = resource:sub(1, _d - 1)
    local path      = resource:sub(_d + 3)

    return require(namespace .. '/' .. path)
end

return _S
