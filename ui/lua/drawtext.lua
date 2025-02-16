--- @section Local functions

--- Shows drawtext on the UI with specified parameters.
--- @param options table: Options for displaying drawtext including header, message, icon, keypress, duration, bar_colour, and style.
function show_drawtext(options)
    local drawtext = {
        action = 'show_drawtext',
        header = options.header or '',
        message = options.message or '',
        icon = options.icon or nil,
        keypress = options.keypress or nil,
        duration = options.duration or nil,
        bar_colour = options.bar_colour or '#FFFFFF',
        style = options.style or {}
    }
    if options.keypress then
        drawtext.icon = nil
    end
    SendNUIMessage(drawtext)
end

exports('show_drawtext', show_drawtext)
utils.show_drawtext = show_drawtext

--- Hides the currently displayed drawtext.
local function hide_drawtext()
    SendNUIMessage({
        action = 'hide_drawtext'
    })
end

exports('hide_drawtext', hide_drawtext)
utils.hide_drawtext = hide_drawtext

--- @section Events

--- Event to show drawtext, added due to drawtext bridge exports
RegisterNetEvent('fivem_utils:cl:show_drawtext', function()
    show_drawtext(options)
end)

--- Event to hide drawtext, added due to drawtext bridge exports
RegisterNetEvent('fivem_utils:cl:hide_drawtext', function()
    hide_drawtext()
end)

--- @section NUI Callbacks

RegisterNUICallback('hide_drawtext', function()
    hide_drawtext()
end)

--- Register commands for testing

RegisterCommand('ui:show_drawtext', function()
    show_drawtext({
        header = 'Enter Building',
        message = 'Press the indicated key to enter',
        keypress = 'e',
        icon = 'fa-solid fa-gear',
        bar_colour = '#4dcbc2'
    })
end, false)

RegisterCommand('ui:hide_drawtext', function()
    hide_drawtext()
end, false)
