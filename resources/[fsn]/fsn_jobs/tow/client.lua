local towtruck = false
local inService = false
local canAfford = true
local currentlytowing = false
local towedvehicle = false
DecorRegister('jTow:marked', 3)
local stations = {
  ["Innocence Blvd / Rancho"] = {
    centerPoint = {x=402.369,y=-1632.14,z=29.2919},
    spawn = {x=410.79608154297,y=-1646.8983154297,z=30.369325637817},
    intake = {x=410.6350402832,y=-1640.0428466797,z=29.291925430298},
    name = "Tow Rental",
    blip = 68,
    gettext = "Press ~INPUT_CONTEXT~ to ~b~rent ~w~a ~o~Tow Truck",
    returntext = "Press ~INPUT_CONTEXT~ to ~r~return ~w~your ~o~Tow Truck",
    cost = 1000,
    ret = 800,
    enabled = true
  }
}

function DisplayHelpText(text)
  SetTextComponentFormat("STRING")
  AddTextComponentString(text)
  DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

function attachVehicle(veh)
  AttachEntityToEntity(veh, towtruck, 20, -0.5, -5.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
  currentlytowing = true
  towedvehicle = veh
  TriggerEvent("pNotify:SendNotification", {text = "Vehicle attached!",
    layout = "centerRight",
    timeout = 1600,
    progressBar = false,
    type = "success",
  })
end

function detachVehicle()
  AttachEntityToEntity(towedvehicle, towtruck, 20, -0.5, -12.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
  DetachEntity(towedvehicle, true, true)
  currentlytowing = false
  TriggerEvent("pNotify:SendNotification", {text = "Vehicle detached",
    layout = "centerRight",
    timeout = 1600,
    progressBar = false,
    type = "success",
  })
end

RegisterNetEvent('jTow:mark')
AddEventHandler('jTow:mark', function()
  local vehicle = aimingAt()
  DecorSetInt(vehicle, 'jTow:marked', 1)
  local cords = GetEntityCoords(vehicle)
  TriggerServerEvent('jCAD:tow', cords.x, cords.y, cords.z)
  --print("MARKED VEHICLE FOR IMPOUND LUL ("..GetVehicleNumberPlateText(vehicle)..") ("..DecorGetInt(vehicle, 'jTow:marked')..")")
  TriggerEvent("pNotify:SendNotification", {text = "You called a towtruck regarding <span style='color:orange;font-weight:bold'>"..GetVehicleNumberPlateText(vehicle).."</span>",
    layout = "centerRight",
    timeout = 1600,
    progressBar = false,
    type = "error",
  })
end)

RegisterNetEvent('tow:CAD:tow')
AddEventHandler('tow:CAD:tow', function(xpos, ypos, zpos)
		addBlip("CAD :: Tow Required", 68, xpos, ypos, zpos, 17, 110)
end)
local blips = {}
function addBlip(text, inumber, x, y, z, color, ttl)
  local blip = AddBlipForCoord(x, y, 0.01)
  	SetBlipSprite(blip, inumber)
  	BeginTextCommandSetBlipName("STRING")
  	AddTextComponentString(text)
  	EndTextCommandSetBlipName(blip)
  	SetBlipAsShortRange(blip,true)
  	SetBlipAsMissionCreatorBlip(blip,true)
  	PulseBlip(blip)
  	SetBlipFlashes(blip, true)
  	SetBlipFlashInterval(blip, 650)
  	SetBlipColour(blip, color)
  	local removeTime = GetNetworkTime() + (ttl * 1000)
  	blips[#blips+1] = {blipObject = blip, timeToDelete = removeTime, active = true}
end
Citizen.CreateThread(function()
	while true do
		Wait(5000)
		for i,v in ipairs(blips) do
			if blips[i].timeToDelete < GetNetworkTime() and blips[i].active then
				RemoveBlip(blips[i].blipObject)
				blips[i].active = false
			end
		end
	end
end)

RegisterNetEvent('jTow:afford')
AddEventHandler('jTow:afford', function(bool)
	if bool then
    canAfford = true
  else
    canAfford = false
  end
end)
DecorRegister("carOwner")
function SpawnTowTruck(x, y, z)
  --TriggerServerEvent('jTow:spawn')
  if canAfford then
    local car = GetHashKey("flatbed")
  	local playerPed = GetPlayerPed(-1)
  	RequestModel(car)
  	while not HasModelLoaded(car) do
  			Citizen.Wait(0)
  	end
  	local playerCoords = GetEntityCoords(playerPed)
  	local playerHeading = GetEntityHeading(playerPed)
  	towtruck = CreateVehicle(car, x, y, z, 90.0, true, false)
  	SetEntityHeading(towtruck, 0)
  	--SetVehicleOnGroundProperly(taxi)
  	SetVehicleHasBeenOwnedByPlayer(towtruck,true)
  	--local netid = NetworkGetNetworkIdFromEntity(taxi)
  	--SetNetworkIdCanMigrate(netid, true)
  	--NetworkRegisterEntityAsNetworked(VehToNet(taxi))
  	TaskWarpPedIntoVehicle(playerPed, towtruck, -1)
  	--SetEntityInvincible(taxi, false)
  	SetEntityAsMissionEntity(towtruck, true, true)
    DecorSetInt(towtruck, 'carOwner', GetPlayerServerId(PlayerId()))
    inService = true
  end
end

function getVehicleInDirection(coordFrom, coordTo)
	local rayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, GetPlayerPed(-1), 0)
	local a, b, c, d, vehicle = GetRaycastResult(rayHandle)
	return vehicle
end

function ImpoundVehicle()
  --local vehicle = aimingAt()
  if towedvehicle then
    if IsEntityAttachedToAnyObject(towedvehicle) then
      detachVehicle()
    end
    --Citizen.InvokeNative(0xEA386986E786A54F, Citizen.PointerValueIntInitialized(towedvehicle))
    SetEntityCoords(towedvehicle, 9000.0,  9000.0,  -10.0,  0.0,  0.0,  0.0)
    --TriggerServerEvent('jTow:success')
    if DecorGetInt(towedvehicle, 'jTow:marked') == 1 then
      TriggerEvent('fsn_bank:change:walletAdd', math.random(1000, 1300))
    else
      TriggerEvent('fsn_bank:change:walletAdd', math.random(100, 500))
    end
    TriggerEvent("pNotify:SendNotification", {text = "You impounded the vehicle",
      layout = "centerRight",
      timeout = 1600,
      progressBar = false,
      type = "success",
    })
    towedvehicle = false
  else
    TriggerEvent("pNotify:SendNotification", {text = "This isn't the right vehicle",
      layout = "centerRight",
      timeout = 1600,
      progressBar = false,
      type = "error",
    })
  end
end

function aimingAt()
	local targetVehicle = false

	local coordA = GetEntityCoords(GetPlayerPed(-1), 1)
	local coordB = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.0, 20.0, -1.0)
	targetVehicle = getVehicleInDirection(coordA, coordB)

	return targetVehicle
end

function ReturnTruck()
  Citizen.InvokeNative(0xEA386986E786A54F, Citizen.PointerValueIntInitialized(towtruck))
  TriggerServerEvent('jTow:return', GetPlayerServerId(PlayerId()))
  towtruck = false
  inService = true
end

Citizen.CreateThread(function()
	-- Blip creation
	for k,v in pairs(stations) do
		local blip = AddBlipForCoord(v.centerPoint.x, v.centerPoint.y, v.centerPoint.z)
		SetBlipSprite(blip, v.blip)
		BeginTextCommandSetBlipName("STRING")
			AddTextComponentString(v.name)
		EndTextCommandSetBlipName(blip)
		SetBlipAsShortRange(blip, true)
	end
  while true do
    Citizen.Wait(0)
    for k, v in pairs(stations) do
      if GetDistanceBetweenCoords(v.centerPoint.x,v.centerPoint.y,v.centerPoint.z,GetEntityCoords(GetPlayerPed(-1))) < 40 then
        DrawMarker(1,v.centerPoint.x,v.centerPoint.y,v.centerPoint.z-1,0,0,0,0,0,0,5.001,5.0001,0.4001,0,155,255,175,0,0,0,0)
        if IsPedInAnyVehicle(GetPlayerPed(-1), true) == false and GetDistanceBetweenCoords(v.centerPoint.x,v.centerPoint.y,v.centerPoint.x,GetEntityCoords(GetPlayerPed(-1))) < 4 then
          if towtruck then
            DisplayHelpText(v.returntext)
            if IsControlJustPressed(1,51) then
              ReturnTruck()
            end
          else
            DisplayHelpText(v.gettext)
            if IsControlJustPressed(1,51) then
              TriggerEvent('fsn_bank:change:walletMinus', 1500)
              SpawnTowTruck(v.spawn.x,v.spawn.y,v.spawn.z)
            end
          end
        end
      end
      if towedvehicle then
        if GetDistanceBetweenCoords(v.intake.x,v.intake.y,v.intake.z,GetEntityCoords(GetPlayerPed(-1))) < 40 then
          DrawMarker(1,v.intake.x,v.intake.y,v.intake.z-1,0,0,0,0,0,0,10.001,10.0001,0.4001,0,255,0,175,0,0,0,0)
          if IsPedInAnyVehicle(GetPlayerPed(-1), true) == false and GetDistanceBetweenCoords(v.intake.x,v.intake.y,v.intake.x,GetEntityCoords(GetPlayerPed(-1))) < 9 then
            if towedvehicle then
              if currentlytowing then
                DisplayHelpText("~r~Remove the vehicle first")
              else
                DisplayHelpText("Press ~INPUT_CONTEXT~ to impound")
                if IsControlJustPressed(1,51) then
                  ImpoundVehicle()
                end
              end
            end
          end
        end
      end
    end

    if towtruck ~= false and IsControlPressed(1, 19) then
      local vehicle = aimingAt()
      if vehicle ~= towtruck then
        if true then
          if GetDistanceBetweenCoords(GetEntityCoords(vehicle), GetEntityCoords(GetPlayerPed(-1))) < 5 then
            if GetDistanceBetweenCoords(GetEntityCoords(vehicle), GetEntityCoords(towtruck)) < 15 then
              DisplayHelpText("Press ~INPUT_CONTEXT~ to tow!")
              if IsControlJustPressed(1,51) then
                attachVehicle(vehicle)
              end
            else
              DisplayHelpText("~r~Your truck needs to be closer")
            end
          end
        else
          DisplayHelpText("~r~This vehicle hasn't been marked for tow")
        end
      else
        if currentlytowing then
          DisplayHelpText("Press ~INPUT_CONTEXT~ to release the vehicle")
          if IsControlJustPressed(1,51) then
            detachVehicle()
          end
        else
          DisplayHelpText("~r~There's nothing on your truck")
        end
      end
    end
  end
end)
