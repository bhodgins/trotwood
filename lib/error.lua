-- error.lua - Error handling library

local _E = {}

--[[ errstr :: Returns an error string for the specified error number
type:       External
params:     subject:table
returns:    errors:table ]]
function _E.errify(subject, errors)
  local evalue = 0
  subject.err = {}

  for k, v in pairs(errors) do
    evalue = evalue + 10
    subject[k] = evalue
    subject.err[evalue] = v
  end

  return subject
end

return _E
