if config.framework ~= 'keystone' or GetResourceState('keystone') ~= 'started' then return end

local CALLBACKS = utils.get_module('callbacks')
local TABLES = utils.get_module('tables')

local fw = {}

--- @section Local Functions

--- Retrieves all players
--- @return players table
local function get_players()
    local players = exports.keystone:get_players()
    return players
end

exports('get_players', get_players)
fw.get_players = get_players

--- Retrieves player data from the server based on the framework.
--- @param source number: Player source identifier.
--- @return Player data object.
local function get_player(source)
    local player = exports.keystone:get_player(source)
    return player
end

exports('get_player', get_player)
fw.get_player = get_player

--- Retrieves player character unique id.
--- @param source number: Player source identifier.
--- @return Players main identifier.
local function get_player_id(source)
    local player = get_player(source)
    if not player then print('No player found for source: '..source) return false end

    local player_id = player.identifier
    return player_id
end

exports('get_player_id', get_player_id)
fw.get_player_id = get_player_id

--- Prepares query parameters for database operations.
--- @param source number: Player source identifier.
--- @return Query part and parameters.
local function get_id_params(source)
    local player = get_player(source)
    local query, params = 'identifier = ?', { player.identifier }
    return query, params
end

exports('get_id_params', get_id_params)
fw.get_id_params = get_id_params

--- Prepares data for SQL INSERT operations.
--- @param source number: Player source identifier.
--- @param data_type string: The type of data being inserted.
--- @param data_name string: The name of the data field.
--- @param data table: The data to insert.
--- @return Columns, values, and parameters.
local function get_insert_params(source, data_type, data_name, data)
    local player = get_player(source)
    local columns, values, params = {'identifier', data_type}, '?, ?', { player.identifier, json.encode(data) }
    return columns, values, params
end

exports('get_insert_params', get_insert_params)
fw.get_insert_params = get_insert_params

--- Retrieves a player's identity information.
--- @param source number: Player source identifier.
--- @return Table of players identity information.
local function get_identity(source)
    local player = get_player(source)
    if not player then return false end

    local player_data = {
        first_name = player._data.identity.first_name,
        middle_name = player._data.identity.middle_name or nil,
        last_name = player._data.identity.last_name,
        dob = player._data.identity.date_of_birth,
        sex = player._data.identity.sex,
        nationality = player._data.identity.nationality
    }
    return player_data
end

exports('get_identity', get_identity)
fw.get_identity = get_identity

--- Checks if a player has a specific item in their inventory.
--- @param source number: Player source identifier.
--- @param item_name string: Name of the item to check.
--- @param item_amount number: (Optional) Amount of the item to check for.
--- @return True if the player has the item (and amount), False otherwise.
local function has_item(source, item_name, item_amount)
    local player = get_player(source)
    if not player then 
        print('Player not found:', source)
        return false 
    end

    local required_amount = item_amount or 1
    return exports.keystone:has_item(source, item_name, required_amount)
end

exports('has_item', has_item)
fw.has_item = has_item

--- Retrieves an item from the players inventory.
--- @param source number: Player source identifier.
--- @param item_name string: Name of the item to retrieve.
--- @return Item object if found, nil otherwise.
local function get_item(source, item_name)
    local player = get_player(source)
    if not player then return nil end

    return exports.keystone:get_item(source, item_name)
end

exports('get_item', get_item)
fw.get_item = get_item

--- Gets a player's inventory data
--- @param source Player source identifier.
--- @return The players inventory.
local function get_inventory(source)
    local player = get_player(source)
    if not player then return false end

    return exports.keystone:get_inventory(source)
end

exports('get_inventory', get_inventory)
fw.get_inventory = get_inventory

--- Adjusts a player's inventory based on given options.
--- @param source number: Player source identifier.
--- @param options table: Options for inventory adjustment.
local function adjust_inventory(source, options)
    local player = get_player(source)
    if not player then return false end

    local function proceed()
        for _, item in ipairs(options.items) do
            if item.action == 'add' then
                exports.keystone:add_item(source, item.item_id, item.amount, item.data)
            elseif item.action == 'remove' then
                exports.keystone:remove_item(source, item.item_id, item.amount)
            end
        end
    end

    if options.validation_data then
        CALLBACKS.validate_distance(source, { location = options.validation_data.location, distance = options.validation_data.distance }, function(is_valid)
            if not is_valid then
                if options.validation_data.drop_player then
                    DropPlayer(source, 'Suspected range exploits.')
                end
                return
            end
            proceed()
        end)
    else
        proceed()
    end
end

exports('adjust_inventory', adjust_inventory)
fw.adjust_inventory = adjust_inventory

--- Updates the item data for a player.
--- @param source number: The players source identifier.
--- @param item_id string: The ID of the item to update.
--- @param updates table: Table containing updates like ammo count, attachments etc.
local function update_item_data(source, item_id, updates)
    local player = get_player(source)
    if not player then print('Player not found') return end
    local item = get_item(source, item_id)
    if not item then  print('Item not found:', item_id) return  end

    exports.keystone:update_item_data(source, item_id, updates)
end

exports('update_item_data', update_item_data)
fw.update_item_data = update_item_data

--- Retrieves the balances of a player.
--- @param source number: Player source identifier.
--- @return A table of balances by type.
local function get_balances(source)
    local player = get_player(source)
    if not player then return false end

    return exports.keystone:get_accounts(source)
end

exports('get_balances', get_balances)
fw.get_balances = get_balances

--- Retrieves a specific balance of a player by type.
--- @param source number: Player source identifier.
--- @param balance_type string: The type of balance to retrieve.
--- @return The balance amount for the specified type.
local function get_balance_by_type(source, balance_type)
    local balances = get_balances(source)
    if not balances then print('no balances') return false end

    local balance
    if balance_type == 'cash' then
        local cash_item = get_item(source, 'cash')
        local cash_balance = cash_item and cash_item.amount or 0
        balance = cash_balance
    else
        balance = balances[balance_type] and balances[balance_type].balance or 0
    end
    return balance
end

exports('get_balance_by_type', get_balance_by_type)
fw.get_balance_by_type = get_balance_by_type

--- Function to adjust a player's balance.
--- @param source number: Player source identifier.
--- @param options table: Table containing balance operations, validation data, reason for the adjustment, and whether to save the update.
local function adjust_balance(source, options)
    local function proceed()
        for _, op in ipairs(options.operations) do
            if op.action == 'add' then
                exports.keystone:add_money(source, op.balance_type, op.amount, op.sender or nil, options.note or nil)
            else
                exports.keystone:remove_money(source, op.balance_type, op.amount, op.recipient or nil, options.note or nil)
            end
        end
    end

    if options.validation_data then
        CALLBACKS.validate_distance(source, { location = options.validation_data.location, distance = options.validation_data.distance }, function(is_valid)
            if not is_valid then
                if options.validation_data.drop_player then
                    DropPlayer(source, 'Suspected range exploits.')
                end
                return
            end
            proceed()
        end)
    else
        proceed()
    end
end

exports('adjust_balance', adjust_balance)
fw.adjust_balance = adjust_balance

--- Retrieves the job(s) of a player by their source identifier.
--- @param source number: The players source identifier.
--- @return A table containing the players jobs and their on-duty status.
local function get_player_jobs(source)
    local player_roles = exports.keystone:get_roles(source)
    local player_jobs = {}
    for role, role_data in pairs(player_roles) do
        if role_data.role_type == 'job' then
            player_jobs[#player_jobs + 1] = role
        end
    end
    return player_jobs
end

exports('get_player_jobs', get_player_jobs)
fw.get_player_jobs = get_player_jobs

--- Checks if a player has one of the specified jobs and optionally checks their on-duty status.
--- @param source number: The players source identifier.
--- @param job_names table: A list of job names to check against the players roles.
--- @param check_on_duty boolean: Optional. If true, also checks if the player is on duty for the job.
--- @return boolean: True if the player has any of the specified jobs and meets the on-duty condition.
local function player_has_job(source, job_names, check_on_duty)
    local player_jobs = get_player_jobs(source)
    for role, role_data in pairs(player_jobs) do
        if TABLES.contains(job_names, role) then
            local on_duty = role_data.metadata and role_data.metadata.on_duty
            if not check_on_duty or on_duty then
                return true
            end
        end
    end
    return false
end

exports('player_has_job', player_has_job)
fw.player_has_job = player_has_job

--- Retrieves a player's job grade for a specified job.
--- @param source number: The players source identifier.
--- @param job_id string: The job ID to retrieve the grade for.
--- @return number|nil: The grade of the player for the specified job, or nil if not found.
local function get_player_job_grade(source, job_id)
    local player_jobs = get_player_jobs(source)
    for _, role_data in ipairs(player_jobs) do
        if role_data.role_type == 'job' and role_data.job_id == job_id then
            return role_data.rank
        end
    end
    return nil
end

exports('get_player_job_grade', get_player_job_grade)
fw.get_player_job_grade = get_player_job_grade


--- Counts players with a specific job and optionally filters by on-duty status.
--- @param job_names table: Table of job names to check against the players jobs.
--- @param check_on_duty boolean: Optional boolean to also check if the player is on-duty for the job.
--- @return Two numbers: total players with the job, and total players with the job who are on-duty.
local function count_players_by_job(job_names, check_on_duty)
    local players = get_players()
    local total_with_job = 0
    local total_on_duty = 0
    for _, playersource in ipairs(players) do
        if player_has_job(playersource, job_names, false) then
            total_with_job = total_with_job + 1
            if player_has_job(playersource, job_names, true) then
                total_on_duty = total_on_duty + 1
            end
        end
    end
    return total_with_job, total_on_duty
end

exports('count_players_by_job', count_players_by_job)
fw.count_players_by_job = count_players_by_job

--- Returns the first job name for a player.
--- @param source number: The players source identifier.
--- @return string|nil: The job name if found, otherwise nil.
local function get_player_job_name(source)
    local player_jobs = get_player_jobs(source)
    for role, role_data in pairs(player_jobs) do
        if role_data.type == 'job' then
            return role
        end
    end
    return nil
end

exports('get_player_job_name', get_player_job_name)
fw.get_player_job_name = get_player_job_name


--- Modifies a player's server-side statuses.
-- @param source The player's source identifier.
-- @param statuses The statuses to modify.
local function adjust_statuses(source, statuses)
    local player = get_player(source)
    if not player then print('Player not found') return end

    exports.keystone:set_statuses(source, statuses)
end

exports('adjust_statuses', adjust_statuses)
fw.adjust_statuses = adjust_statuses

--- Register an item as usable for different frameworks.
--- @param item string: The item identifier.
--- @param cb function: The callback function to execute when the item is used.
local function register_item(item, cb)
    if not item then debug_log('warn', 'Function: register_item | Note: Item identifier is missing') return end
    exports.keystone:register_item(item, function(source)
        cb(source)
    end)
end

exports('fw_register_item', register_item)
fw.register_item = register_item

return fw
