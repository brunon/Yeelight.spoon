local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Yeelight Spoon"
obj.version = "1.0"
obj.author = "Bruno Navert"
obj.license = "MIT"
obj.homepage = "https://github.com/brunon/Yeelight.spoon"

obj.hostname = nil
obj.port = nil
obj.socket = nil
obj.command_id = 0
local debug = false

local function responseCallback(data, tag)
  if debug then hs.printf("Got data from Yeelight socket: " .. data) end
  resp = hs.json.decode(data)
  result = resp["result"]
  if result ~= nil then
    status = resp["result"][1]
    if status ~= "ok" then
      hs.printf("Received error response from Yeelight:\n" .. data)
    end
  end
end

function obj:start(hostname, port)
  if hostname ~= nil then obj.hostname = hostname end
  if port ~= nil then obj.port = port end
  obj.socket = hs.socket.new():connect(obj.hostname, obj.port)
  if obj.socket ~= nil then
    hs.printf("Connected to Yeelight @ %s:%d", obj.hostname, obj.port)
    obj.socket:setCallback(responseCallback)
  else
    hs.printf('Error connecting to Yeelight')
  end
end

function obj:stop()
  if obj.socket ~= nil then
    hs.printf("Disconnect from Yeelight")
    obj.socket:setCallback(nil)
    obj.socket:disconnect()
    obj.socket = nil
  end
end

function obj:connected()
  return obj.socket ~= nil and obj.socket:connected()
end

function obj:send_command(method, params)
  if obj.socket == nil or not obj.socket:connected() then
    obj:start()
  end
  if obj.socket ~= nil and obj.socket:connected() then
    obj.command_id = obj.command_id + 1
    msg = hs.json.encode(
      {
        ['id'] = obj.command_id,
        ['method'] = method,
        ['params'] = params
      }
    )
    if debug then hs.printf("Sending to Yeelight:\n%s", msg) end
    obj.socket:write(string.format("%s\r\n", msg))
    obj.socket:read("\r\n")
  end
end

function obj:turn_off()
  local mode = 2 -- RGB
  obj:send_command('set_power', {'off', 'smooth', 0, mode})
end

function obj:turn_on(color, brightness, effect, duration)
  local mode = 2 -- RGB
  obj:send_command('set_power', {'on', effect, duration, mode})
  obj:send_command('set_bright', {brightness})
  obj:send_command('set_rgb', {tonumber(color, 16), effect, duration})
end

return obj
