local QBCore = exports['qb-core']:GetCoreObject()
isLoggedIn = true

local menuOpen = false
local wasOpen = false

Citizen.CreateThread(function() 
    while true do
        Citizen.Wait(10)
        if QBCore == nil then
            TriggerEvent("QBCore:GetObject", function(obj) QBCore = obj end)    
            Citizen.Wait(200)
        end
    end
end)

local spawnedWeeds = 0
local weedPlants = {}
local isPickingUp, isProcessing = false, false

local f = true
local b = 0

function DrawText2D(x, y, text)  
			SetTextFont(0)
			SetTextProportional(1)
			SetTextScale(0.0, 0.3)
			SetTextColour(128, 128, 128, 255)
			SetTextDropshadow(0, 0, 0, 0, 255)
			SetTextEdge(1, 0, 0, 0, 255)
			SetTextDropShadow()
			SetTextOutline()
			SetTextEntry("STRING")
			DrawText(x, y)

end

Citizen.CreateThread(
    function()
        local g = false
        while true do
            Citizen.Wait(5000)
            if f then
				local h = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), Config.CircleZones3.WeedField.coords, true)
                if h < 100 and not g then
                    SpawnWeedPlants()
                    g = true
                elseif h > 250 and g then
                    Citizen.Wait(900000)
                    g = false
                end
            else
                Citizen.Wait(10000)
            end
        end
    end
)

RegisterNetEvent("QBCore:Client:OnPlayerLoaded")
AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
end)


Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)

		if GetDistanceBetweenCoords(coords, Config.CircleZones3.WeedProcessing.coords, true) < 1 then
			DrawMarker(27, Config.CircleZones3.WeedProcessing.coords.x, Config.CircleZones3.WeedProcessing.coords.y, Config.CircleZones3.WeedProcessing.coords.z - 0.66 , 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 255, 0, 0, 200, 0, 0, 0, 0)

			if not isProcessing then
				DrawText2D(Config.CircleZones3.WeedProcessing.coords.x, Config.CircleZones3.WeedProcessing.coords.y, Config.CircleZones3.WeedProcessing.coords.z, 'Press ~b~[ E ]~w~ to start packing your ~g~Weed')
			end

			if IsControlJustReleased(0, 38) and not isProcessing then
				QBCore.Functions.TriggerCallback('qb-underwaterweed:ingredient', function(HasItem, type)
					if HasItem then
						ProcessWeed()
					else
						QBCore.Functions.Notify('You dont have enough Materials', 'error')
					end
				end)
			end
		else
			Citizen.Wait(500)
		end
	end
end)


function ProcessWeed()
	isProcessing = true
	local playerPed = PlayerPedId()

	
	TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_PARKING_METER", 0, true)

	QBCore.Functions.Progressbar("search_register", "Processing..", 15000, false, true, {
		disableMovement = true,
		disableCarMovement = true,
		disableMouse = false,
		disableCombat = true,
	}, {}, {}, {}, function() -- Done
		QBCore.Functions.TriggerCallback('qb-underwaterweed:ingredient', function(HasItem, type)
			if HasItem then	
				TriggerServerEvent('qb-underwaterweed:processWeed')
			else
				print("badhe teej bannre the na xD")
				QBCore.Functions.Notify("You dont have enough Materials", "error")
				FreezeEntityPosition(PlayerPedId(),false)
			end
		end)
		
		local timeLeft = Config.Delays.WeedProcessing / 1000

		while timeLeft > 0 do
			Citizen.Wait(1000)
			timeLeft = timeLeft - 1

			if GetDistanceBetweenCoords(GetEntityCoords(playerPed), Config.CircleZones3.WeedProcessing.coords, false) > 4 then
				TriggerServerEvent('qb-underwaterweed:cancelProcessing')
				break
			end
		end
		ClearPedTasks(PlayerPedId())
	end, function()
		ClearPedTasks(PlayerPedId())
	end) -- Cancel
		
	
	isProcessing = false
end



Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)
		local nearbyObject, nearbyID

		for i=1, #weedPlants, 1 do
			if GetDistanceBetweenCoords(coords, GetEntityCoords(weedPlants[i]), false) < 1 then
				nearbyObject, nearbyID = weedPlants[i], i
			end
		end

		if nearbyObject and IsPedOnFoot(playerPed) then

			if not isPickingUp then
				DrawText2D(0.4, 0.8, '~w~Press ~g~[E]~w~ to pickup')
			end

			if IsControlJustReleased(0, 38) and not isPickingUp then
				isPickingUp = true
				TaskStartScenarioInPlace(playerPed, 'world_human_gardener_plant', 0, false)

				QBCore.Functions.Notify("Please have patience", "error", 10000)
				QBCore.Functions.Progressbar("search_register", "Picking up..", 5000, false, true, {
					disableMovement = true,
					disableCarMovement = true,
					disableMouse = false,
					disableCombat = true,
				}, {}, {}, {}, function() -- Done
					ClearPedTasks(PlayerPedId())
					DeleteObject(nearbyObject)

					table.remove(weedPlants, nearbyID)
					spawnedWeeds = spawnedWeeds - 1
	
					TriggerServerEvent('qb-underwaterweed:pickedUpWeed')
					TriggerServerEvent('qb-underwaterweed:weed')
					ClearPedTasks(PlayerPedId())

				end, function()
					ClearPedTasks(PlayerPedId())
				end) -- Cancel

				isPickingUp = false
			end
		else
			Citizen.Wait(1000)
		end
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		for k, v in pairs(weedPlants) do
			DeleteObject(v)
		end
	end
end)

function SpawnWeedPlants()
	
	math.randomseed(GetGameTimer())
    local random = math.random(20, 30)
    RequestModel(2739214831)
    while not HasModelLoaded(2739214831) do
        Citizen.Wait(1)
    end
    while b < random do
		Citizen.Wait(1)
		local D = GenerateWeedCoords()
		print(D)
		print(random)

        local E = CreateObject(2739214831, D.x, D.y, D.z, false, false, true)
        PlaceObjectOnGroundProperly(E)
        FreezeEntityPosition(E, true)
        table.insert(weedPlants, E)
        b = b + 1
    end
end

function ValidateWeedCoord(plantCoord)
	if spawnedWeeds > 0 then
		local validate = true

		for k, v in pairs(weedPlants) do
			if GetDistanceBetweenCoords(plantCoord, GetEntityCoords(v), true) < 5 then
				validate = false
			end
		end

		if GetDistanceBetweenCoords(plantCoord, Config.CircleZones3.WeedField.coords, false) > 50 then
			validate = false
		end

		return validate
	else
		return true
	end
end

function GenerateWeedCoords()
	while true do
		Citizen.Wait(1)

		local weedCoordX, weedCoordY

		math.randomseed(GetGameTimer())
		local modX = math.random(-90, 90)

		Citizen.Wait(100)

		math.randomseed(GetGameTimer())
		local modY = math.random(-90, 90)

		weedCoordX = Config.CircleZones3.WeedField.coords.x + modX
		weedCoordY = Config.CircleZones3.WeedField.coords.y + modY

		local coordZ = GetCoordZ(weedCoordX, weedCoordY)
		local coord = vector3(weedCoordX, weedCoordY, coordZ)

		if ValidateWeedCoord(coord) then
			return coord
		end
	end
end


function GetCoordZ(x, y)
	local groundCheckHeights = { -13.0, -14.0, -15.0, -16.0, -17.0, -18.0, -19.0, -22.0, -26.0, -30.0} 

	for i, height in ipairs(groundCheckHeights) do
        local foundGround, z = GetGroundZFor_3dCoord(x, y, height)

        if foundGround then
            return z
        end
    end

    return -28.0
end
