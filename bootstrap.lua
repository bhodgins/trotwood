

_G.fiostub = {}
_G.fiostub.require = function(resource)
    local _d = resource:find('://')
    local namespace = resource:sub(1, _d - 1)
    local path      = resource:sub(_d + 3)

    return require(namespace .. '/' .. path)
end

require('system/core')
