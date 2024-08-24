PlayerData = {}

local function createProperty(property)
	PropertiesTable[property.property_id] = Property:new(property)
end
RegisterNetEvent('ps-housing:client:addProperty', createProperty)

RegisterNetEvent('ps-housing:client:removeProperty', function (property_id)
	local property = Property.Get(property_id)

	if property then
		property:RemoveProperty()
	end

	PropertiesTable[property_id] = nil
end)

function InitialiseProperties(properties)
    Debug("Initialising properties")
    PlayerData = QBX.PlayerData

    for k, v in pairs(Config.Apartments) do
        ApartmentsTable[k] = Apartment:new(v)
    end

	if not properties then
    	properties = lib.callback.await('ps-housing:server:requestProperties')
	end
	
    for k, v in pairs(properties) do
        createProperty(v.propertyData)
    end

    TriggerEvent("ps-housing:client:initialisedProperties")

    Debug("Initialised properties")
end

-- nothing: handle in qbx_spawn
-- AddEventHandler("QBCore:Client:OnPlayerLoaded", InitialiseProperties)

RegisterNetEvent('ps-housing:client:initialiseProperties', InitialiseProperties)

-- nothing: handle in qbx_spawn
-- AddEventHandler("onResourceStart", function(resourceName) -- Used for when the resource is restarted while in game
-- 	if (GetCurrentResourceName() == resourceName) then
--         InitialiseProperties()
-- 	end
-- end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerData.job = job
end)

RegisterNetEvent('ps-housing:client:setupSpawnUI', function(cData)
    DoScreenFadeOut(1000)
    local result = lib.callback.await('ps-housing:cb:GetOwnedApartment', source, cData.citizenid)
    if result then
        TriggerEvent('qb-spawn:client:setupSpawns', cData, false, nil)
        TriggerEvent('qb-spawn:client:openUI', true)
        -- TriggerEvent("apartments:client:SetHomeBlip", result.type)
    else
        if Config.StartingApartment then
            TriggerEvent('qb-spawn:client:setupSpawns', cData, true, Config.Apartments)
            TriggerEvent('qb-spawn:client:openUI', true)
        else
            TriggerEvent('qb-spawn:client:setupSpawns', cData, false, nil)
            TriggerEvent('qb-spawn:client:openUI', true)
        end
    end
end)

AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    if Modeler.IsMenuActive then
        Modeler:CloseMenu()
    end

    for k, v in pairs(PropertiesTable) do
        v:RemoveProperty()
    end

    for k, v in pairs(ApartmentsTable) do
        v:RemoveApartment()
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
	if (GetCurrentResourceName() == resourceName) then
		if Modeler.IsMenuActive then
			Modeler:CloseMenu()
		end

		for k, v in pairs(PropertiesTable) do
			v:RemoveProperty()
		end

        for k, v in pairs(ApartmentsTable) do
            v:RemoveApartment()
        end
	end
end)

exports('GetProperties', function()
    return PropertiesTable
end)

exports('GetProperty', function(property_id)
    return Property.Get(property_id)
end)

exports('GetApartments', function()
    return ApartmentsTable
end)

exports('GetApartment', function(apartment)
    return Apartment.Get(apartment)
end)

exports('GetShells', function()
    return Config.Shells
end)


lib.callback.register('ps-housing:cb:confirmPurchase', function(amount, street, id)
    return lib.alertDialog({
        header = 'Konfirmasi Pembelina',
        content = 'Apakah kamu yakin mau membeli properti '..street..' ' .. id .. ' seharga Rp' .. amount .. '?',
        centered = true,
        cancel = true,
        labels = {
            confirm = "Beli",
            cancel = "Batalkan"
        }
    })
end)

lib.callback.register('ps-housing:cb:confirmRaid', function(street, id)
    return lib.alertDialog({
        header = 'Bobol',
        content = 'Apakah kamu mau membobol properti '..street..' ' .. id .. '?',
        centered = true,
        cancel = true,
        labels = {
            confirm = "Bobol",
            cancel = "Batalkan"
        }
    })
end)

lib.callback.register('ps-housing:cb:ringDoorbell', function()
    return lib.alertDialog({
        header = 'Bel Pintu',
        content = 'Apakah kamu ingin memanggil penghuni properti?',
        centered = true,
        cancel = true,
        labels = {
            confirm = "Tekan Bel",
            cancel = "Batalkan"
        }
    })
end)

lib.callback.register('ps-housing:cb:showcase', function()
    return lib.alertDialog({
        header = 'Perlihatkan Properti',
        content = 'Apakah kamu ingin memperlihatkan properti kepada orang lain?',
        centered = true,
        cancel = true,
        labels = {
            confirm = "Perlihatkan",
            cancel = "Batalkan"
        }
    })
end)
