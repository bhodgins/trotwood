-- Graphical Terminal library for Open Computers --

local _T = {}

-- INTERNAL FUNCTIONS --

--[[ ctrl_bel :: Plays a beep if enabled
type:       Internal
params:     Nil
returns:    Nil ]]
local function ctrl_bel(terminal) if terminal.beep == true then computer.beep(terminal.beep_freq, terminal.beep_length) end end

--[[ handle_ctrl :: Handles control characters
type:       Internal
params:     terminal:table, code:number, postchunk:string
returns:    Nil ]]
local function handle_ctrl(terminal, code, postchunk)
  local ctrl_codes = { -- Dispatch table
    [7] = ctrl_bel,
  }

  local dispatch_index = ctrl_codes[code]
  if dispatch_index ~= nil then return ctrl_codes[code](terminal, postchunk) end
end

--[[ split_fit :: Returns the ammount of a string that will fit on the screen
type:       Internal
params:     terminal:table, buf:string
returns:    Nil ]]
local function split_fit(terminal, buf)
  local avail_len = terminal.max_x - terminal.pos_x + 1 -- +1 for current pos
  local buf_len = buf:len()

  if buf_len <= avail_len then return buf, ""
  else return buf:sub(1, avail_len), buf:sub(avail_len + 1) end
end

--[[ next_line :: next line, scroll if necessary, add to buffer*(NYI)
type:       Internal
params:     terminal:table
returns:    terminal:table ]]
local function next_line(terminal)
  if terminal.pos_y >= terminal.max_y then
    -- TODO: Handle scrolling here.
  else terminal.pos_y = terminal.pos_y + 1 end
  terminal.pos_x = 1

  return terminal
end

--[[ print :: Prints a string onto the screen
type:       Internal
params:     terminal:table, buf:string
returns:    Nil ]]
local function gtty_print(terminal, buf)
  if buf == "" then return end -- Nothing left to print
  local gpu = terminal.gpu

  if terminal.pos_x > terminal.max_x then terminal = next_line(terminal) end
  local printable_now, printable_next = split_fit(terminal, buf)
  gpu.set(terminal.pos_x, terminal.pos_y, printable_now)
  terminal.pos_x = terminal.pos_x + printable_now:len() + 1 -- +1 next pos

  return gtty_print(terminal, printable_next)
end

--[[ process :: Processes terminal input
type:       Internal
params:     terminal:table, chunks:table
returns:    terminal:table ]]
local function process(terminal, chunks)
  local chunk = table.remove(chunks, 1) -- TODO: Optimize by direct index?
  if chunk == nil then return end

  local pfix  = string.byte(chunk:sub(1, 1))
  if pfix < 32 then handle_ctrl(terminal, pfix, chunks[1]) -- Next chunk passed for \e
  else gtty_print(terminal, chunk) end

  return process(terminal, chunks)
end

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

-- EXTERNAL FUNCTIONS --

--[[ resize:: Resizes terminal to fit the gpu output
type:       External
params:     terminal:table
returns:    terminal:table ]]
function _T.resize(terminal)
  local gpu = terminal.gpu
  gpu_x, gpu_y = gpu.getResolution()
  terminal.max_x = gpu_x
  terminal.max_y = gpu_y
  return terminal
end

--[[ build :: Returns a new terminal datastructure
type:       External
params:     gpu:uuid
returns:    terminal:table ]]
function _T.build(gpu, buffer_size)
  beep = beep or true

  local terminal = {
  pos_x  = 1,     max_x = 1,
  pos_y  = 1,     max_y = 1,
  gpu    = gpu,   beep  = true, -- Set to false to disable ASCII code 7
  beep_freq = 1000, beep_length = 0.25,
  buffer = { size = buffer_size, sp = 1 }
  } terminal = _T.resize(terminal) -- Fit to GPU

  return terminal
end

  --[[ put :: Sends data to the terminal for processing
  type:       External
  params:     data:string
  returns:    terminal:table ]]
function _T.put(terminal, data) return process(terminal, tokenize(data, {})) end

return _T
