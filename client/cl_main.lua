QBCore = exports['qb-core']:GetCoreObject()

-- Event registered when a Tombstone is created
RegisterNetEvent('bama-tombstoneitemdrop:client:syncEntity', function ()
    Wait(2000) -- Gives enough time for the server to create the prop and the items (May not be needed, but do not change)

    QBCore.Functions.TriggerCallback('bama-tombstoneitemdrop:server:getObjects', function (returnValue)
        for k, v in pairs(returnValue) do

            local obj = NetToEnt(k)
            if Config.Debug then print('NetworkGetNetworkIdFromEntity: '..k..' - CreateObjectNoOffset: '..v.id..' - NetToEnt: '..obj) end

            exports['qb-target']:AddTargetEntity(obj, {
                options = {
                    {
                        icon = Config.DeathGrave.targetIcon,
                        label = Config.DeathGrave.targetLabel,
                        action = function (targetEntity)
                            TriggerServerEvent('inventory:server:OpenInventory', 'stash', v.stashId)
                            TriggerEvent('inventory:client:SetCurrentStash', v.stashId)
                            TriggerServerEvent('bama-tombstoneitemdrop:server:SetCurrentTombstone', ObjToNet(targetEntity))
                        end,
                    }
                },
                distance = 2.5,
            })
        end
    end)
end)