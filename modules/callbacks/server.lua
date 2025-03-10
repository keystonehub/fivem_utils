local utils_maths = utils.get_module('maths')

local callbacks = {}

--- @section Tables

--- Ensure `stored_callbacks` persists globally and is shared across all modules.
stored_callbacks = stored_callbacks or {}

--- @section Local Functions

--- Registers a server-side callback.
--- @param name string: The name of the callback event.
--- @param cb function: The callback function to be executed.
local function register_callback(name, cb)
    if not name or not cb then
        utils.debug_log('error', ('Failed to register callback: Invalid name or function. Name: %s'):format(name or 'nil'))
        return
    end
    if stored_callbacks[name] then
        utils.debug_log('warning', ('Overwriting existing callback: "%s"'):format(name))
    end
    stored_callbacks[name] = cb
    local callback_keys = {}
    for key in pairs(stored_callbacks) do
        table.insert(callback_keys, key)
    end
    utils.debug_log('success', ('Registered callback: "%s". Current callbacks: [%s]'):format(name, table.concat(callback_keys, ', ')))
end

exports('register_callback', register_callback)
callbacks.register = register_callback

--- @section Callbacks

--- Validates a player's distance from the target location to ensure they are within a specific range.
--- @param _src number: The players server ID.
--- @param data table: Data containing location information.
--- @param cb function: Callback function to return the validation result.
local function validate_distance(_src, data, cb)
    local location = data.location
    local max_distance = data.distance or 10.0
    local position = {x = location.x, y = location.y, z = location.z}
    local coords = GetEntityCoords(GetPlayerPed(_src))
    local player_position = {x = coords.x, y = coords.y, z = coords.z}
    local distance = utils_maths.calculate_distance(player_position, position)
    if distance <= max_distance then
        cb(true)
    else
        cb(false)
    end
end
register_callback('fivem_utils:sv:validate_distance', validate_distance)

exports('callback_validate_distance', validate_distance)
callbacks.validate_distance = validate_distance

return callbacks