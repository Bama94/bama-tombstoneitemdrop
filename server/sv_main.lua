QBCore = exports['qb-core']:GetCoreObject()

local entities = {}
local CurrentTombstone = {}
local inventory = {}

-- Saves the items to a stash upon creating the tombstone
local function SaveStash(stashId, items)
    MySQL.Async.insert('INSERT INTO stashitems (stash, items) VALUES (:stash, :items) ON DUPLICATE KEY UPDATE items = :items', {
        ['stash'] = stashId,
        ['items'] = json.encode(items)
    })
    -- Create A log of Stash being created
end

-- Deletes the stash upon deleting the tombstone
local function DeleteStash(stashId, source)
    MySQL.Async.execute('DELETE FROM stashitems WHERE stash = ?', {stashId}, function (rowsEffected)
        if source ~= nil then
            return TriggerClientEvent('QBCore:Notify', source, 'Greedy much? You emptied the Tombstone!', 'inform')
        end
    end)
    -- Create a log of tombstone being deleted due to a player or timer/restart
end

-- Registers when someone has opened the inventory and if the inventory is empty and if it is, then delete the stash and the entity
RegisterNetEvent('inventory:server:SaveInventory', function (type, id)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local result = string.match(id, "(%a+)")

    if not Player then return end
    Wait(100)

    if type == 'stash' and result == 'tombstone' then
        local result = MySQL.scalar.await('SELECT items FROM stashitems WHERE stash = ?', {id})
        local stashItems = json.decode(result)
        if not stashItems or not next(stashItems) then
            DeleteStash(id, src)
            DeleteEntity(entities[CurrentTombstone[Player.PlayerData.citizenid]].id)
            entities[CurrentTombstone[Player.PlayerData.citizenid]] = nil
        end
    end
end)

-- Starts a timer for the tombstone, once the timer is up, delete the stash and entity
local function tombstoneTimer(tombstone)
    local timer = {}
    CreateThread( function ()
        while true do
            Wait(1000)
            if not next(timer) then
                timer[tombstone.id] = Config.DeleteTombstoneTime
            end
            if timer[tombstone.id] > 0 then
                timer[tombstone.id] = timer[tombstone.id] - 1
                print(timer[tombstone.id])
            else
                DeleteStash(tombstone.stashId)
                DeleteEntity(tombstone.id)
                tombstone = nil
                break
            end
        end
    end)
end

-- Spawns the Tombstone upon someone respawning
local function ServerSideObjectSpawn(Player, coords, stashId)
    local entityId = CreateObjectNoOffset(Config.DeathGrave.prop, coords.x, coords.y, coords.z - 0.98, true, true, false)
    local networkId = NetworkGetNetworkIdFromEntity(entityId)
    entities[networkId] = {player = Player, coords, id = entityId, stashId = stashId}
    


    FreezeEntityPosition(entityId, true)
    TriggerClientEvent('bama-tombstoneitemdrop:client:syncEntity', -1)
    tombstoneTimer(entities[networkId])
end

-- Gets the players inventory and cross references that with the blacklisted items in the config
local function DropItems(Player)
    local rawInventory = Player.PlayerData.items
    local coords = QBCore.Functions.GetCoords(GetPlayerPed(Player.PlayerData.source))
    local inventoryData = {}
    local alreadySubtracted = {}


    -- Getting players Items and figuring out whether or not the item is blacklisted and if the player has more than the blacklisted amount
    for k, v in pairs(rawInventory) do
        local blacklisted = false
        for k2, v2 in pairs(Config.BlacklistTombstoneItems) do
            if v2[1] == v.name and not v2[2] then
                blacklisted = true
            end
            if v2[1] == v.name and v2[2] then
                if not alreadySubtracted[v.name] and not v.unique then
                    if (v.amount - v2[2] <= 0) then
                        v.amount = 0
                        alreadySubtracted[v.name] = true
                    else
                        v.amount = v.amount - v2[2]
                        alreadySubtracted[v.name] = true
                    end
                elseif not alreadySubtracted[v.name] and v.unique then
                    if (v.amount - v2[2] <= 0) then
                        v.amount = 0
                        v2[2] = v.amount - v2[2]
                        if v2[2] <= 0 then
                            alreadySubtracted[v.name] = true
                            break
                        end

                    end
                end
                break
            end
        end
        if not blacklisted and v.amount > 0 then
            table.insert(inventoryData, {name = v.name, amount = v.amount, info = v.info, type = v.type, slot = v.slot})
            Player.Functions.RemoveItem(v.name, v.amount)
        end
    end
    alreadySubtracted = {}

    local stashId
    local tombstoneID
    if not inventory[Player.PlayerData.citizenid] then
        tombstoneID = 1
        stashId = 'tombstone_'..Player.PlayerData.citizenid
    else
        tombstoneID = inventory[Player.PlayerData.citizenid] + 1
        stashId = 'tombstone'..tombstoneID..'_'..Player.PlayerData.citizenid

    end
    if Config.Debug then print('DEBUG: StashID: '..stashId..' TombstoneID: '..tombstoneID..' InventoryData: '..inventoryData) end
    if stashId and type(stashId) == 'string' and tombstoneID and type(tombstoneID) == 'number' then inventory[Player.PlayerData.citizenid] = tombstoneID else return end

    ServerSideObjectSpawn(Player, coords, stashId)
    SaveStash(stashId, inventoryData)
end

-- The Event that when triggers starts the Tombstone being created
if Config.DeathGrave.deathEvent == 'onBack' then
    RegisterServerEvent('hospital:server:SetDeathStatus', function (isDead)
        local src = source 
        local Player = QBCore.Functions.GetPlayer(src)
        
        if Player and isDead then DropItems(Player) end
    end)
end

if Config.DeathGrave.deathEvent == 'onSide' then
    RegisterNetEvent('hostpital:server:SetLastStandStatus', function (inLastStand)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)

        if Player and inLastStand then DropItems(Player) end
    end)
end

if Config.DeathGrave.deathEvent == 'respawn' then
    RegisterNetEvent('hospital:server:RespawnAtHospital', function ()
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)

        if Player then DropItems(Player) end
    end)
end

-- Only needed to find out what tombstone a player is targeting so when they empty the tombstone, itll delete it.
RegisterNetEvent('bama-tombstoneitemdrop:server:SetCurrentTombstone', function (removeEntity)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    CurrentTombstone[Player.PlayerData.citizenid] = removeEntity
end)

-- Callback to get the entities created to be targetable client side
QBCore.Functions.CreateCallback('bama-tombstoneitemdrop:server:getObjects', function (source, cb)
    cb(entities)
end)


-- Test Command (Can Delete)
QBCore.Commands.Add('graveDrop','', {}, false, function (source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    DropItems(Player)
end, 'god')

-- Deletes the entities upon restarting the script or restarting the server(even though entities will delete themselves upon restarting server, but future plans to make it so they last after a server restart)
AddEventHandler("onResourceStop", function(resource)
	if resource == GetCurrentResourceName() then
		for k, v in pairs(entities) do
            DeleteStash(entities[k].stashId)
            DeleteEntity(entities[k].id)
            entities[k] = nil
        end
	end
end)