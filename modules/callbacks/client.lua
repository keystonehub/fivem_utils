local callbacks = {}

--- Stores callbacks.
stored_callbacks = stored_callbacks or {}

--- @section Local Functions

-- @section Local Functions

--- Trigger a server callback.
--- @param name string: The event name of the callback.
--- @param data table: The data to send to the server.
--- @param cb function: The callback function to handle the response.
local function callback(name, data, cb)
    local cb_id = math.random(1, 1000000)
    callbacks[cb_id] = cb
    TriggerServerEvent('fivem_utils:sv:trigger_callback', name, data, cb_id)
end

exports('trigger_callback', callback)
callbacks.trigger = callback

--- @section Events

--- Handle server callbacks.
--- @param client_cb_id number: The client callback ID.
--- @param server_cb_id number: The server callback ID (not directly used but can be logged or used for validation).
--- @param ... multiple: The data returned by the server callback.
RegisterNetEvent('fivem_utils:cl:client_callback')
AddEventHandler('fivem_utils:cl:client_callback', function(client_cb_id, server_cb_id, ...)
    local callback = callbacks[client_cb_id]
    if callback then
        callback(...)
        callbacks[client_cb_id] = nil
    end
end)

--- @section Assignment

return callbacks