Framework = {}

PoliceJobs = {}
RealtorJobs = {}

-- Convert config table to usable keys
for i = 1, #Config.PoliceJobNames do
    PoliceJobs[Config.PoliceJobNames[i]] = true
end

for i = 1, #Config.RealtorJobNames do
    RealtorJobs[Config.RealtorJobNames[i]] = true
end

if IsDuplicityVersion() then
    Framework.ox = {}
    Framework.qb = {}

    function Framework.ox.Notify(src, message, type)
        type = type == "inform" and "info" or type
        TriggerClientEvent("ox_lib:notify", src, {title="Property", description=message, type=type})
    end

    function Framework.qb.Notify(src, message, type)
        type = type == "info" and "primary" or type
        exports.qbx_core:Notify(src, message, type)
    end

    function Framework.ox.RegisterInventory(stash, label, stashConfig)
        exports.ox_inventory:RegisterStash(stash, label, stashConfig.slots, stashConfig.maxweight, nil)
    end

    function Framework.qb.RegisterInventory(stash, label, stashConfig)
        -- Used for ox_inventory compat
    end

    function Framework.qb.SendLog(message)
        if Config.EnableLogs then
            TriggerEvent('qb-log:server:CreateLog', 'pshousing', 'Housing System', 'blue', message)
        end
    end
    
    function Framework.ox.SendLog(message)
            -- noop
    end

    return
end

local function hasApartment(apts)
    for propertyId, _  in pairs(apts) do
        local property = PropertiesTable[propertyId]
        if property.owner then
            return true
        end
    end

    return false
end

Framework.qb = {

    Notify = function(message, type)
        type = type == "info" and "primary" or type
        exports.qbx_core:Notify(message, type)
    end,

    AddEntrance = function(coords, size, heading, propertyId, enter, raid, showcase, showData, targetName)
        local property_id = propertyId
        exports.interact:AddInteraction({
            coords = vector3(coords.x, coords.y, coords.z),
            distance = 3.0,
            interactDst = 2.0,
            id = targetName,
            name = targetName,
            options = {
                {
                    label = "Masuk",
                    action = enter,
                    canInteract = function()
                        local property = Property.Get(property_id)
                        return property.has_access or property.owner
                    end,
                },
                {
                    label = "Perlihatkan",
                    action = showcase,
                    canInteract = function()
                        local job = PlayerData.job
                        local jobName = job.name
                        local onDuty = job.onduty
                        return RealtorJobs[jobName] and onDuty
                    end,
                },
                {
                    label = "Informasi",
                    action = showData,
                    canInteract = function()
                        local job = PlayerData.job
                        local jobName = job.name
                        local onDuty = job.onduty
                        return RealtorJobs[jobName] and onDuty
                    end,
                },
                {
                    label = "Bel Pintu",
                    action = enter,
                    canInteract = function()
                        local property = Property.Get(property_id)
                        return not property.has_access and not property.owner
                    end,
                },
                {
                    label = "Bobol",
                    action = raid,
                    canInteract = function()
                        local job = PlayerData.job
                        local jobName = job.name
                        local gradeAllowed = tonumber(job.grade.level) >= Config.MinGradeToRaid
                        local onDuty = job.onduty

                        return PoliceJobs[jobName] and gradeAllowed and onDuty
                    end,
                },
            }
        })

        return targetName
    end,

    AddApartmentEntrance = function(coords, size, heading, apartment, enter, seeAll, seeAllToRaid, targetName)
        exports.interact:AddInteraction({
            coords = vector3(coords.x, coords.y, coords.z),
            distance = 3.0,
            interactDst = 2.0,
            id = targetName,
            name = targetName,
            options = {
                {
                    label = "Masuk",
                    action = enter,
                    canInteract = function()
                        local apartments = ApartmentsTable[apartment].apartments
                        return hasApartment(apartments)
                    end,
                },
                {
                    label = "Lihat Penghuni",
                    action = seeAll,
                },
                {
                    label = "Bobol",
                    action = seeAllToRaid,
                    canInteract = function()
                        local job = PlayerData.job
                        local jobName = job.name
                        local gradeAllowed = tonumber(job.grade.level) >= Config.MinGradeToRaid
                        local onDuty = job.onduty

                        return PoliceJobs[jobName] and gradeAllowed and onDuty
                    end,
                },
            }
        })
    end,

    AddDoorZoneInside = function(coords, size, heading, leave, checkDoor)
        exports.interact:AddInteraction({
            coords = vector3(coords.x, coords.y, coords.z),
            distance = 3.0,
            interactDst = 2.0,
            id = "shellExit",
            name = "shellExit",
            options = {
                    {
                        label = "Keluar",
                        action = leave,
                        icon = "fas fa-right-from-bracket",
                    },
                    {
                        label = "Cek Pintu",
                        action = checkDoor,
                        icon = "fas fa-bell",
                    },
                },
            }
        )

        return "shellExit"
    end,

    AddDoorZoneInsideTempShell = function(coords, size, heading, leave)
        exports.interact:AddInteraction({
            coords = vector3(coords.x, coords.y, coords.z),
            distance = 3.0,
            interactDst = 2.0,
            id = "shellExit",
            name = "shellExit",
            options = {
                    {
                        label = "Keluar",
                        action = leave,
                        icon = "fas fa-right-from-bracket",
                    },
                },
            }
        )

        return "shellExit"
    end,

    RemoveTargetZone = function(targetName)
        exports.interact:RemoveInteraction(targetName)
    end,

    AddRadialOption = function(id, label, icon, _, event, options)
        exports['qb-radialmenu']:AddOption({
            id = id,
            title = label,
            icon = icon,
            type = 'client',
            event = event,
            shouldClose = true,
            options = options
        }, id)
    end,

    RemoveRadialOption = function(id)
        exports['qb-radialmenu']:RemoveOption(id)
    end,

    AddTargetEntity = function (entity, label, icon, action)
        exports.interact:AddLocalEntityInteraction({
            entity = entity,
            name = 'ps_housing_entity',
            id = 'ps_housing_entity',
            distance = 3.0,
            interactDst = 2.0,
            options = {
                {
                    label = label,
                    icon = icon,
                    action = action,
                },
            },
        })
    end,

    RemoveTargetEntity = function (entity)
        exports.interact:RemoveLocalEntityInteraction(entity, 'ps_housing_entity')
    end,

    OpenInventory = function (stash, stashConfig)
        TriggerServerEvent("inventory:server:OpenInventory", "stash", stash, stashConfig)
        TriggerEvent("inventory:client:SetCurrentStash", stash)
    end,
}

Framework.ox = {
    Notify = function(message, type)
        type = type == "inform" and "info" or type
        
        lib.notify({
            title = 'Property',
            description = message,
            type = type
        })
    end,

    AddEntrance = function (coords, size, heading, propertyId, enter, raid, showcase, showData, _)
        local property_id = propertyId

        local handler = exports.ox_target:addBoxZone({
            coords = vector3(coords.x, coords.y, coords.z),
            size = vector3(size.y, size.x, size.z),
            rotation = heading,
            debug = Config.DebugMode,
            options = {
                {
                    label = "Masuk",
                    icon = "fas fa-door-open",
                    onSelect = enter,
                    canInteract = function()
                        local property = Property.Get(property_id)
                        return property.has_access or property.owner
                    end,
                },
                {
                    label = "Perlihatkan",
                    icon = "fas fa-eye",
                    onSelect = showcase,
                    canInteract = function()
                        -- local property = Property.Get(property_id)
                        -- if property.propertyData.owner ~= nil then return false end -- if its owned, it cannot be showcased
                        
                        local job = PlayerData.job
                        local jobName = job.name

                        return RealtorJobs[jobName]
                    end,
                },
                {
                    label = "Informasi",
                    icon = "fas fa-circle-info",
                    onSelect = showData,
                    canInteract = function()
                        local job = PlayerData.job
                        local jobName = job.name
                        local onDuty = job.onduty
                        return RealtorJobs[jobName] and onDuty
                    end,
                },
                {
                    label = "Bel Pintu",
                    icon = "fas fa-bell",
                    onSelect = enter,
                    canInteract = function()
                        local property = Property.Get(property_id)
                        return not property.has_access and not property.owner
                    end,
                },
                {
                    label = "Bobol",
                    icon = "fas fa-building-shield",
                    onSelect = raid,
                    canInteract = function()
                        local job = PlayerData.job
                        local jobName = job.name
                        local gradeAllowed = tonumber(job.grade.level) >= Config.MinGradeToRaid
                        local onDuty = job.onduty

                        return PoliceJobs[jobName] and onDuty and gradeAllowed
                    end,
                },
            },
        })

        return handler
    end,

    AddApartmentEntrance = function (coords, size, heading, apartment, enter, seeAll, seeAllToRaid, _)        
        local handler = exports.ox_target:addBoxZone({
            coords = vector3(coords.x, coords.y, coords.z),
            size = vector3(size.y, size.x, size.z),
            rotation = heading,
            debug = Config.DebugMode,
            options = {
                {
                    label = "Masuk",
                    onSelect = enter,
                    icon = "fas fa-door-open",
                    canInteract = function()
                        local apartments = ApartmentsTable[apartment].apartments
                        return hasApartment(apartments)
                    end,
                },
                {
                    label = "Lihat Penghuni",
                    onSelect = seeAll,
                    icon = "fas fa-circle-info",
                },
                {
                    label = "Bobol",
                    onSelect = seeAllToRaid,
                    icon = "fas fa-building-shield",
                    canInteract = function()
                        local job = PlayerData.job
                        local jobName = job.name
                        local gradeAllowed = tonumber(job.grade.level) >= Config.MinGradeToRaid
                        local onDuty = job.onduty

                        return PoliceJobs[jobName] and onDuty and gradeAllowed
                    end,
                },
            },
        })

        return handler
    end,

    AddDoorZoneInside = function (coords, size, heading, leave, checkDoor)
        local handler = exports.ox_target:addBoxZone({
            coords = vector3(coords.x, coords.y, coords.z), --z = 3.0
            size = vector3(size.y, size.x, size.z),
            rotation = heading,
            debug = Config.DebugMode,
            options = {
                {
                    name = "leave",
                    label = "Keluar",
                    onSelect = leave,
                    icon = "fas fa-right-from-bracket",
                },
                {
                    name = "doorbell",
                    label = "Cek Pintu",
                    onSelect = checkDoor,
                    icon = "fas fa-bell",
                },
            },
        })

        return handler
    end,

    AddDoorZoneInsideTempShell = function (coords, size, heading, leave)
        local handler = exports.ox_target:addBoxZone({
            coords = vector3(coords.x, coords.y, coords.z), --z = 3.0
            size = vector3(size.y, size.x, size.z),
            rotation = heading,
            debug = Config.DebugMode,
            options = {
                {
                    name = "leave",
                    label = "Keluar",
                    onSelect = leave,
                    icon = "fas fa-right-from-bracket",
                },
            },
        })
        print("made")
        return handler
    end,

    RemoveTargetZone = function (handler)
        exports.ox_target:removeZone(handler)
    end,

    AddRadialOption = function(id, label, icon, fn)
        lib.addRadialItem({
            id = id,
            icon = icon,
            label = label,
            onSelect = fn,
        })
    end,

    RemoveRadialOption = function(id)
        lib.removeRadialItem(id)
    end,

    AddTargetEntity = function (entity, label, icon, action)
        exports.ox_target:addLocalEntity(entity, {
            {
                name = label,
                label = label,
                icon = icon,
                onSelect = action,
            },
        })
    end,

    RemoveTargetEntity = function (entity)
        exports.ox_target:removeLocalEntity(entity)
    end,

    OpenInventory = function (stash, stashConfig)
        exports.ox_inventory:openInventory('stash', stash)
    end,
}
