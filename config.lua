Config = {}
Config.Debug = false -- WILL PRINT DEBUGS in the server/client Console to help with errors

Config.DeleteTombstoneTime = 600 -- IN SECONDS
Config.DeathGrave  = {
    prop = 'm23_1_prop_m31_gravestones_02a',
    targetIcon = '',
    targetLabel = 'Grave Loot',
    deathEvent = 'respawn' -- onSide(will spawn tombstone upon player going on their side) | onBack(spawn tombstone upon player going on their back) | respawn(spawn tombstone upon player respawning at hospital/bed)

}
Config.BlacklistTombstoneItems = { -- These items wont be removed upon death
    {'water_bottle'}, -- Will keep all of this item
    {'phone', 1}, -- Player will keep 1 of this item, any more than the specified number of this item will be placed in the tombstone
    {'firstaid', 3} -- Player will keep 3 of this item, any more than the specified number of this item will be placed in the tombstone
}
