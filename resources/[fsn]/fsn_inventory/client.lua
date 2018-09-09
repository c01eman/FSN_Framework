--[[The MIT License (MIT)
Copyright (c) 2017 IllidanS4
Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:
The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
]]

function table.contains(table, element)
  for _, value in pairs(table) do
    if value[1] == element then
      return true
    end
  end
  return false
end

local entityEnumerator = {
  __gc = function(enum)
    if enum.destructor and enum.handle then
      enum.destructor(enum.handle)
    end
    enum.destructor = nil
    enum.handle = nil
  end
}

local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
  return coroutine.wrap(function()
    local iter, id = initFunc()
    if not id or id == 0 then
      disposeFunc(iter)
      return
    end

    local enum = {handle = iter, destructor = disposeFunc}
    setmetatable(enum, entityEnumerator)

    local next = true
    repeat
      coroutine.yield(id)
      next, id = moveFunc(iter)
    until not next

    enum.destructor, enum.handle = nil, nil
    disposeFunc(iter)
  end)
end

function EnumerateObjects()
  return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end

function EnumeratePeds()
  return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
end

function EnumerateVehicles()
  return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

function EnumeratePickups()
  return EnumerateEntities(FindFirstPickup, FindNextPickup, EndFindPickup)
end
function fsn_drawText3D(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    if onScreen then
        SetTextScale(0.3, 0.3)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 55)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
    end
end

local dev_debug = false
RegisterNetEvent('fsn_dev:debug')
AddEventHandler('fsn_dev:debug', function()
  dev_debug = not dev_debug
end)
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    if dev_debug then
      for obj in EnumerateObjects() do
        if GetDistanceBetweenCoords(GetEntityCoords(obj), GetEntityCoords(GetPlayerPed(-1))) < 10 then
          fsn_drawText3D(GetEntityCoords(obj).x, GetEntityCoords(obj).y, GetEntityCoords(obj).z, 'Model: ~g~'..GetEntityModel(obj)..'\n~w~X: ~b~'..GetEntityCoords(obj).x..'\n ~w~Y: ~b~'..GetEntityCoords(obj).y..'\n ~w~Z: ~b~'..GetEntityCoords(obj).z)
        end
      end
      for obj in EnumerateVehicles() do
        if GetDistanceBetweenCoords(GetEntityCoords(obj), GetEntityCoords(GetPlayerPed(-1))) < 30 then
          fsn_drawText3D(GetEntityCoords(obj).x, GetEntityCoords(obj).y, GetEntityCoords(obj).z, 'Model: ~g~'..GetEntityModel(obj)..'\n~w~X: ~b~'..GetEntityCoords(obj).x..'\n ~w~Y: ~b~'..GetEntityCoords(obj).y..'\n ~w~Z: ~b~'..GetEntityCoords(obj).z)
        end
      end
      for obj in EnumeratePeds() do
        if GetDistanceBetweenCoords(GetEntityCoords(obj), GetEntityCoords(GetPlayerPed(-1))) < 30 then
          fsn_drawText3D(GetEntityCoords(obj).x, GetEntityCoords(obj).y, GetEntityCoords(obj).z, 'Model: ~g~'..GetEntityModel(obj)..'\n~w~X: ~b~'..GetEntityCoords(obj).x..'\n ~w~Y: ~b~'..GetEntityCoords(obj).y..'\n ~w~Z: ~b~'..GetEntityCoords(obj).z)
        end
      end
    end
  end
end)
--------------------------------------------------------------------------- developer stuffs ^ don't ask why it's here?
function GetNearbyPeds(X, Y, Z, Radius)
	local NearbyPeds = {}
	if tonumber(X) and tonumber(Y) and tonumber(Z) then
		if tonumber(Radius) then
			for Ped in EnumeratePeds() do
				if DoesEntityExist(Ped) then
					local PedPosition = GetEntityCoords(Ped, false)
					if Vdist(X, Y, Z, PedPosition.x, PedPosition.y, PedPosition.z) <= Radius then

            table.insert(NearbyPeds, Ped)
					end
				end
			end
		else
			print("GetNearbyPeds was given an invalid radius!")
		end
	else
		print("GetNearbyPeds was given invalid coordinates!")
	end
	return NearbyPeds
end
--------------------------------------------------------------------------------------------
local inventory = {}
local maxspace = 30
local spacewithbag = 60
local init = true

function fsn_computeMaxSpace()
  if inventory["backpack"] then
    return spacewithbag
  else
    return maxspace
  end
end

function fsn_computeCurrentSpace()
  local num = 0
  for k, v in pairs(inventory) do
    local weight = items_table[k].weight * v.amount
    num = num + weight
  end
  return num
end

RegisterNetEvent('fsn_police:search:start:inventory')
AddEventHandler('fsn_police:search:start:inventory', function(officerid)
  local my_inv = {}
  for k, v in pairs(inventory) do
    local item = items_table[k].display_name
    table.insert(my_inv,#my_inv+1,{amount = v.amount,display_name = item})
  end
  print(officerid)
  TriggerServerEvent('fsn_police:search:end:inventory', my_inv, officerid)
end)

RegisterNetEvent('fsn_inventory:empty')
AddEventHandler('fsn_inventory:empty', function()
  inventory = {}
  TriggerServerEvent('fsn_inventory:database:update', inventory)
end)

local dropped_entities = {}
local my_entities = {}
--------------------------------------------------------------------------------------------------------
RegisterNetEvent('fsn_inventory:itemhasdropped')
AddEventHandler('fsn_inventory:itemhasdropped', function(item, hash, xyz, amount, pickupid)
  --TriggerEvent('fsn_notify:displayNotification', item..' was dropped @ '..xyz[1], 'centerLeft', 3000, 'error')
  table.insert(dropped_entities,#dropped_entities+1, {
    item = item,
    hash = hash,
    xyz = xyz,
    amount = amount,
    pickupid = pickupid
  })
end)
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    for k, obj in pairs(dropped_entities) do
      if GetDistanceBetweenCoords(obj.xyz[1], obj.xyz[2], obj.xyz[3], GetEntityCoords(GetPlayerPed(-1)), true) < 2 then
        SetTextComponentFormat("STRING")
        AddTextComponentString("Press ~INPUT_PICKUP~ to pick up ~y~["..obj.amount.."X] "..items_table[obj.item].display_name)
        DisplayHelpTextFromStringLabel(0, 0, 1, -1)
        if IsControlJustPressed(0, 38) then
          TriggerEvent('fsn_inventory:item:add', obj.item, obj.amount)

          local object = GetClosestObjectOfType(obj.xyz[1], obj.xyz[2], obj.xyz[3], 5.0, obj.hash, false, false, false)
          local netId = NetworkGetNetworkIdFromEntity(object)
          if netId ~= 0 then
            if not NetworkHasControlOfNetworkId(netId) then
              NetworkRequestControlOfNetworkId(netId)
        			while not NetworkHasControlOfNetworkId(netId) do
        				Citizen.Wait(1)
        			end
            end
          end
          while not HasAnimDictLoaded('pickup_object') do
            RequestAnimDict('pickup_object')
            Citizen.Wait(5)
          end
          TaskPlayAnim(GetPlayerPed(-1), 'pickup_object', 'pickup_low', 8.0, 1.0, -1, 49, 1.0, 0, 0, 0)
          SetEntityAsMissionEntity(object, true, true)
		      DeleteObject(object)
          if DoesObjectOfTypeExistAtCoords(obj.xyz[1], obj.xyz[2], obj.xyz[3], 5.0, obj.hash, true) then
            object = GetClosestObjectOfType(obj.xyz[1], obj.xyz[2], obj.xyz[3], 5.0, obj.hash, false, false, false)
            SetEntityAsMissionEntity(object, true, true)
            DeleteObject(object)
          end
          TriggerServerEvent('fsn_inventory:itempickup', obj.pickupid)
          TriggerEvent('fsn_commands:me', 'picked up '..obj.amount..' '..items_table[obj.item].display_name)
          Citizen.Wait(1000)
          ClearPedTasks(GetPlayerPed(-1))
        end
      end
    end
  end
end)

RegisterNetEvent('fsn_inventory:removedropped')
AddEventHandler('fsn_inventory:removedropped', function(id)
  for k, v in pairs(dropped_entities) do
    if v.pickupid == id then
      table.remove(dropped_entities,k)
    end
  end
end)

RegisterNetEvent('fsn_inventory:item:drop')
AddEventHandler('fsn_inventory:item:drop', function(item)
  if inventory[item] then
    Citizen.CreateThread(function()
  		local editOpen = true
  		DisplayOnscreenKeyboard(false, "FMMC_KEY_TIP8S", "", "", "", "", "", 64)
  		while UpdateOnscreenKeyboard() == 0 or editOpen do
  			if UpdateOnscreenKeyboard() == 1 then
  				editOpen = false
  				qty = GetOnscreenKeyboardResult()
          if qty == 'all' then
            qty = fsn_GetItemAmount(item)
          else
            if tonumber(qty) then
              qty = math.floor(tonumber(qty))
            else
              TriggerEvent('fsn_notify:displayNotification', 'Enter an amount or "all"', 'centerLeft', 3000, 'error')
            end
          end
          if fsn_GetItemAmount(item) < qty then
            TriggerEvent('fsn_notify:displayNotification', 'You do not have '..qty..' '..items_table[item].display_name..'s', 'centerLeft', 3000, 'error')
            return
          end
          while not HasAnimDictLoaded('pickup_object') do
            RequestAnimDict('pickup_object')
            Citizen.Wait(5)
          end
          local coords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0, 0.5, 0)
          if items_table[item].modelhash then
            RequestModel(items_table[item].modelhash)
        	  while not HasModelLoaded(items_table[item].modelhash) do
        	    Wait(1)
        	  end
            local obj = CreateObject(items_table[item].modelhash, coords, true, true, true)
            PlaceObjectOnGroundProperly(obj)
          end
          TaskPlayAnim(GetPlayerPed(-1), 'pickup_object', 'pickup_low', 8.0, 1.0, -1, 49, 1.0, 0, 0, 0)

          table.insert(my_entities, #my_entities+1, {
            hash = items_table[item].modelhash,
            xyz = coords
          })

          TriggerEvent('fsn_inventory:item:take', item, qty)
          TriggerEvent('fsn_commands:me', 'dropped '..qty..' '..items_table[item].display_name)
          TriggerServerEvent('fsn_inventory:item:dropped', item, items_table[item].modelhash, {coords.x, coords.y, coords.z}, qty)
          Citizen.Wait(1000)
          ClearPedTasks(GetPlayerPed(-1))
          break
  			end
  			Wait(1)
  		end
  	end)
  end
end)

RegisterNetEvent('fsn_inventory:item:give')
AddEventHandler('fsn_inventory:item:give', function(item)
  if inventory[item] then

  end
end)

RegisterNetEvent('fsn_inventory:item:use')
AddEventHandler('fsn_inventory:item:use', function(item)
  if inventory[item] then
    items_table[item].use()
  else
    TriggerEvent('fsn_notify:displayNotification', 'You don\'t have any '..items_table[item].display_name, 'centerLeft', 3000, 'success')
  end
end)

RegisterNetEvent('fsn_inventory:item:add')
AddEventHandler('fsn_inventory:item:add', function(item, amount)
  local space = fsn_computeMaxSpace()
  local weight = items_table[item].weight * amount
  local new_weight = fsn_computeCurrentSpace() + weight
  if new_weight > space then
    TriggerEvent('fsn_notify:displayNotification', 'You don\'t have room!', 'centerLeft', 3000, 'error')
  else
    if inventory[item] then
      inventory[item].amount = inventory[item].amount + amount
      TriggerEvent('fsn_notify:displayNotification', 'You got '..amount..'x '..items_table[item].display_name, 'centerLeft', 3000, 'success')
    else
      inventory[item] = {}
      inventory[item].display_name = items_table[item].display_name
      inventory[item].amount = amount
      TriggerEvent('fsn_notify:displayNotification', 'You got '..amount..'x '..items_table[item].display_name, 'centerLeft', 3000, 'success')
    end
  end
  TriggerServerEvent('fsn_inventory:database:update', inventory)
end)

RegisterNetEvent('fsn_inventory:item:take')
AddEventHandler('fsn_inventory:item:take', function(item, amount)
  if inventory[item] then
    if inventory[item].amount > amount then
      inventory[item].amount = inventory[item].amount - amount
    else
      inventory[item] = nil
    end
    TriggerServerEvent('fsn_inventory:database:update', inventory)
  else
    TriggerEvent('chatMessage', 'FSN', {255,0,0}, 'How\'d you use an item you do not have?????')
  end
end)

RegisterNetEvent('fsn_inventory:initChar')
RegisterNetEvent('fsn_inventory:init')
AddEventHandler('fsn_inventory:initChar', function(invtbl)
  inventory = json.decode(invtbl)
  init = true
  TriggerEvent('fsn_inventory:init', sendtojs)
end)

RegisterNetEvent('fsn_menu:requestInventory')
RegisterNetEvent('fsn_inventory:update')
AddEventHandler('fsn_menu:requestInventory', function()
  TriggerEvent('fsn_inventory:update', inventory)
end)

function fsn_HasPhone()
  if inventory["phone"] then
    return true
  else
    return false
  end
end

function fsn_HasItem(item)
  if inventory[item] then
    return true
  else
    return false
  end
end

function fsn_GetItemDetails(item)
  return items_table[item]
end

function fsn_GetItemAmount(item)
  if inventory[item] then
    return inventory[item].amount
  else
    return 0
  end
end
----------------------------------------------------- Store stuffs
RegisterNetEvent('fsn_inventory:prebuy')
RegisterNetEvent('fsn_inventory:buyItem')
AddEventHandler('fsn_inventory:prebuy', function(item)
  local space = fsn_computeMaxSpace()
  local weight = items_table[item].weight * 1
  local new_weight = fsn_computeCurrentSpace() + weight
  if new_weight > space then
    TriggerEvent('fsn_notify:displayNotification', 'You cannot carry this!', 'centerLeft', 3000, 'error')
  else
    TriggerEvent('fsn_inventory:buyItem', item, items_table[item].price, 1)
  end
end)
----------------------------------------------------- Drug stuffs
local drugs = {
  ["packaged_cocaine"] = {
    street_price = 800
  },
  ["meth_rocks"] = {
    street_price = 450
  },
  ["joint"] = {
    street_price = 300
  }
}

function fsn_isPedPlayer(ped)
  for id = 0, 31 do
    if NetworkIsPlayerActive(id) then
      if GetPlayerPed(id) == ped then
        return true
      end
    end
  end
  return false
end

function fsn_getPlayerDrugs()
  for k, v in pairs(drugs) do
    if inventory[k] then
      return k
    end
  end
  return false
end

local selling = false
local selling_item = ''
local selling_start = 0
local selling_ped = nil
local sold_peds = {}
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    if init then
      local drugas = fsn_getPlayerDrugs()
      if not IsPedInAnyVehicle(GetPlayerPed(-1)) then
        if drugas ~= false and not selling then
          for obj in EnumeratePeds() do
            if obj ~= GetPlayerPed(-1) and not IsEntityDead(obj) and not IsPedInAnyVehicle(obj) and GetDistanceBetweenCoords(GetEntityCoords(obj), GetEntityCoords(GetPlayerPed(-1))) < 2 and not IsEntityDead(obj) then
              --fsn_drawText3D(GetEntityCoords(obj).x, GetEntityCoords(obj).y, GetEntityCoords(obj).z, '')
              if table.contains(sold_peds, obj) then
                fsn_drawText3D(GetEntityCoords(obj).x, GetEntityCoords(obj).y, GetEntityCoords(obj).z, '~R~Already bought')
              else
                local netId = NetworkGetNetworkIdFromEntity(obj)
                if not NetworkHasControlOfNetworkId(netId) then
                  NetworkRequestControlOfNetworkId(netId)
            			while not NetworkHasControlOfNetworkId(netId) do
            				Citizen.Wait(1)
            			end
                end
                fsn_drawText3D(GetEntityCoords(obj).x, GetEntityCoords(obj).y, GetEntityCoords(obj).z, 'Press ~g~E~w~ to sell '..drugas)
                --SetTextComponentFormat("STRING")
                --AddTextComponentString("Press ~INPUT_PICKUP~ to sell ~g~"..items_table[drugas].display_name)
                --DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                if IsControlJustPressed(0, 38) then
                  table.insert(sold_peds, #sold_peds+1, {obj, true})
                  TriggerEvent('fsn_notify:displayNotification', 'You ask if they would like to buy...', 'centerLeft', 3000, 'info')
                  Citizen.Wait(1000)
                  local try = math.random(0, 100)
                  --[[
                  if not NetworkIsPlayerTalking(PlayerId()) then
                    TriggerEvent('fsn_notify:displayNotification', 'How do you expect to sell drugs without talking?', 'centerLeft', 3000, 'error')
                      try = 57
                  end
                  ]]
                  if try > 58 then
                    selling = true
                    selling_ped = obj
                    selling_item = drugas
                    ClearPedTasksImmediately(obj)
                    TaskStandStill(obj, 9000)
                    selling_start = GetNetworkTime()
                  else
                    try = math.random(0, 100)
                    if try > 20 then
                      while not HasAnimDictLoaded('cellphone@') do
                        RequestAnimDict('cellphone@')
                        Citizen.Wait(5)
                      end
                      SetEntityAsMissionEntity(obj, true, true)
					            --ResurrectPed(obj)
                      ClearPedTasksImmediately(obj)
                      SetEntityAsNoLongerNeeded(obj)
                      TaskPlayAnim(obj, 'cellphone@', 'cellphone_call_listen_base', 8.0, 1.0, -1, 49, 1.0, 0, 0, 0)
                      fsn_drawText3D(GetEntityCoords(obj).x, GetEntityCoords(obj).y, GetEntityCoords(obj).z, '~R~Calling the police!')
                      if not IsEntityDead(obj) then
                        local pos = GetEntityCoords(obj)
                        local coords = {
                          x = pos.x,
                          y = pos.y,
                          z = pos.z
                        }
                        TriggerServerEvent('fsn_police:dispatch', coords, 3)
                      end
                    end
                    TriggerEvent('fsn_notify:displayNotification', 'They are not interested', 'centerLeft', 3000, 'error')
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end)
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    if selling then
      local rem = selling_start+8000
      if rem > GetNetworkTime() then
        if GetEntitySpeed(selling_ped) < 1 and not IsEntityDead(selling_ped) and GetDistanceBetweenCoords(GetEntityCoords(selling_ped), GetEntityCoords(GetPlayerPed(-1))) < 3 then
          fsn_drawText3D(GetEntityCoords(selling_ped).x, GetEntityCoords(selling_ped).y, GetEntityCoords(selling_ped).z, 'Selling: ~b~'..string.sub(tostring(math.ceil(rem-GetNetworkTime())), 1, 1)..'s~w~ remaining')
        else
          if selling then
            TriggerEvent('fsn_notify:displayNotification', 'The transaction was <span style="color:red">cancelled', 'centerLeft', 3000, 'info')
            selling = false
            selling_start = 0
            selling_ped = false
          end
        end
      else
        if fsn_GetItemAmount(selling_item) < 7 then
          sold_amount = fsn_GetItemAmount(selling_item)
        else
          sold_amount = math.random(1, 7)
        end
        local price = math.random(drugs[selling_item].street_price - 100, drugs[selling_item].street_price + 100)
        price = price * sold_amount
        if exports.fsn_police:fsn_getCopAmt() < 1 then
          TriggerEvent('chatMessage', '', {255,255,255}, '^8^*:FSN:^0^r This is a police related action, there are no police online so your earnings have been halved.')
          price = price / 2
        end
        TriggerEvent('fsn_notify:displayNotification', 'They bought '..sold_amount..' '..items_table[selling_item].display_name..' for '..price..'DM', 'centerLeft', 3000, 'info')
        TriggerEvent('fsn_inventory:item:add', 'dirty_money', price)
        TriggerEvent('fsn_inventory:item:take', selling_item, sold_amount)
        if selling then
          selling = false
          selling_start = 0
          selling_ped = false
        end
      end
    end
  end
end)
----------------------------------------------------------------------------- LAUNDERING
local laundering = false
local salepos = {x = 85.76220703125, y = -1959.5466308594, z = 21.121669769287}
local garagepos = {x = 88.83975982666, y = -1966.9367675781, z = 20.456882476807}
local laundervan = false
local laundering_complete = false
local current_delivery = 0
local done_deliveries = 0
local needed_delivery = 0
local delivery_blip = false
local dm_amount = 0
local quote = {
  [1] = math.random(10, 35),
  [2] = math.random(10, 20)
}
local quoted = false
local abletolaunder = true
local launder_deliveries = {
  {x = 109.69165802002, y = -1566.5838623047, z = 29.311115264893},
  {x = 332.28826904297, y = -1024.4379882813, z = 28.996091842651},
  { x = -11.7389554977417, y = -303.995056152344, z = 45.5747222900391},
  { x = 146.843276977539, y = -300.878265380859, z = 45.3772392272949},
  { x = 90.9032745361328, y = -287.846313476563, z = 46.2548522949219},
  { x = -25.0742530822754, y = -232.339614868164, z = 45.9333648681641},
  { x = -120.107566833496, y = -364.745635986328, z = 36.387809753418},
  { x = -25.1990394592285, y = -195.758193969727, z = 52.1177139282227},
  { x = -5.50260925292969, y = -146.08544921875, z = 56.2241859436035},
  { x = 27.7411308288574, y = -210.56852722168, z = 52.6132545471191},
  { x = 157.997344970703, y = -260.784973144531, z = 51.1468048095703},
  { x = 114.574058532715, y = -245.457168579102, z = 51.1555404663086},
  { x = 315.732696533203, y = -205.817001342773, z = 53.8409042358398},
  { x = 335.27978515625, y = -213.279769897461, z = 53.8431167602539},
  { x = 546.979309082031, y = -207.427703857422, z = 53.7732124328613},
  { x = 303.611633300781, y = -174.296340942383, z = 57.4277954101563},
  { x = 388.248901367188, y = -82.1120986938477, z = 67.4467544555664},
  { x = 353.871612548828, y = -126.939880371094, z = 65.9824523925781},
  { x = 267.145294189453, y = -150.983749389648, z = 63.5137596130371},
  { x = 245.70703125, y = -145.144439697266, z = 63.2356109619141},
  { x = 212.403762817383, y = -24.7241287231445, z = 69.4420166015625},
  { x = 176.177703857422, y = -67.8491516113281, z = 68.2495803833008},
  { x = 165.744750976563, y = -113.256736755371, z = 62.0614356994629},
  { x = 196.085632324219, y = -157.104339599609, z = 56.4725303649902},
  { x = 171.977188110352, y = -34.9312553405762, z = 67.7583847045898},
  { x = 114.977584838867, y = -99.8651580810547, z = 60.4771919250488},
  { x = 86.7692108154297, y = -100.260398864746, z = 59.1181831359863},
  { x = 26.0904140472412, y = -73.1540985107422, z = 61.3461799621582},
  { x = -11.983060836792, y = -78.6496200561523, z = 56.8573036193848},
  { x = 11.9316091537476, y = -3.83730173110962, z = 69.9814147949219},
  { x = 0.237976536154747, y = 27.7774333953857, z = 70.7471694946289},
  { x = -45.3299217224121, y = -20.6062450408936, z = 68.2370071411133},
  { x = -98.6652984619141, y = -63.4526863098145, z = 56.1215362548828},
  { x = -108.958450317383, y = 36.9439506530762, z = 71.1790466308594},
  { x = -185.084457397461, y = 97.5139465332031, z = 69.8506698608398},
  { x = -166.521682739258, y = 114.104721069336, z = 70.0628509521484},
  { x = -191.907958984375, y = 134.994033813477, z = 69.5727081298828},
  { x = -264.137969970703, y = 198.03092956543, z = 85.0904312133789},
  { x = -177.637008666992, y = 213.771255493164, z = 88.5552062988281},
  { x = -182.930419921875, y = 316.721832275391, z = 97.5557632446289},
  { x = -127.102439880371, y = 177.254760742188, z = 85.503044128418},
  { x = -74.2093200683594, y = 145.735504150391, z = 81.1078872680664},
  { x = 88.2836380004883, y = 184.7744140625, z = 104.354156494141},
  { x = 78.4332656860352, y = 168.985961914063, z = 104.335487365723},
  { x = 154.720397949219, y = 170.130432128906, z = 104.809013366699},
  { x = 326.063537597656, y = 96.4807891845703, z = 99.490119934082},
  { x = 382.353393554688, y = 63.7339401245117, z = 97.7345428466797},
  { x = 338.004821777344, y = 41.2871208190918, z = 90.1132507324219},
  { x = 274.633117675781, y = 4.60633182525635, z = 78.9510192871094},
  { x = 281.837341308594, y = -45.6216087341309, z = 70.6862335205078},
  { x = 381.503295898438, y = 115.495231628418, z = 102.33438873291},
  { x = 649.293395996094, y = -10.4862375259399, z = 82.5059432983398},
  { x = 683.592163085938, y = 72.1659393310547, z = 83.2104721069336},
  { x = 549.217712402344, y = 154.938140869141, z = 98.9910430908203},
  { x = 520.515747070313, y = 168.794052124023, z = 99.1263580322266},
  { x = 437.372039794922, y = 222.17073059082, z = 102.921821594238},
  { x = 368.649993896484, y = 339.2578125, z = 103.005744934082},
  { x = 220.53923034668, y = 272.936248779297, z = 105.255218505859},
  { x = 385.352111816406, y = -904.107788085938, z = 29.0522365570068},
  { x = 365.969848632813, y = -824.960754394531, z = 28.8995971679688},
  { x = 332.714202880859, y = -949.290710449219, z = 29.140661239624},
  { x = 299.720153808594, y = -902.88330078125, z = 28.8994235992432},
  { x = 323.334716796875, y = -683.579345703125, z = 28.9122982025146},
  { x = 87.2545700073242, y = -819.47998046875, z = 30.7565860748291},
  { x = 37.7948722839355, y = -1002.40435791016, z = 29.0543842315674},
  { x = 101.742057800293, y = -1120.96765136719, z = 28.9251003265381},
  { x = 307.379272460938, y = -1085.22058105469, z = 28.9452438354492},
  { x = -47.2743873596191, y = -762.72216796875, z = 32.4531669616699},
  { x = -274.226348876953, y = -564.568237304688, z = 29.7809448242188},
  { x = -307.191253662109, y = -712.606811523438, z = 28.064624786377},
  { x = -267.318206787109, y = -831.868835449219, z = 31.3706645965576},
  { x = -292.107818603516, y = -988.930786132813, z = 23.7439479827881},
  { x = -47.6948432922363, y = -785.235900878906, z = 43.8152542114258},
  { x = 66.4006576538086, y = -734.228820800781, z = 43.8344421386719},
  { x = 105.720031738281, y = -624.741760253906, z = 43.8211212158203},
  { x = 495.365661621094, y = -778.442321777344, z = 24.4849834442139},
  { x = 851.067077636719, y = -950.545227050781, z = 25.8883152008057},
  { x = 849.662719726563, y = -1053.74816894531, z = 27.6498584747314},
  { x = 902.838317871094, y = -142.258270263672, z = 76.3618240356445},
  { x = 970.883605957031, y = -117.029663085938, z = 74.1100769042969},
  { x = 945.690185546875, y = -255.781066894531, z = 67.2504653930664},
  { x = 868.21728515625, y = -208.389022827148, z = 70.3895111083984},
  { x = 768.811462402344, y = -156.665115356445, z = 74.2722396850586},
  { x = 1203.64440917969, y = -454.903961181641, z = 66.4116821289063},
  { x = 1151.87744140625, y = -461.1796875, z = 66.5673065185547},
  { x = 1194.6396484375, y = -629.046875, z = 62.6697311401367},
  { x = 1214.32604980469, y = -705.528747558594, z = 59.7364654541016},
  { x = 1223.96301269531, y = -729.414794921875, z = 60.0188598632813},
  { x = 1280.37512207031, y = -672.556762695313, z = 65.9052810668945},
  { x = 1261.6884765625, y = -620.793701171875, z = 68.8272933959961},
  { x = 1307.43054199219, y = -537.859313964844, z = 70.9507827758789},
  { x = 1351.63500976563, y = -595.812377929688, z = 74.0946197509766},
  { x = 1273.45751953125, y = -458.269714355469, z = 69.0017929077148},
  { x = 1061.04089355469, y = -390.966857910156, z = 67.0905303955078},
  { x = 993.396606445313, y = -436.334686279297, z = 63.6045150756836},
  { x = 960.27783203125, y = -498.431579589844, z = 60.9737091064453},
  { x = 946.991333007813, y = -510.247619628906, z = 59.9701652526855},
  { x = 882.477783203125, y = -511.141693115234, z = 57.0853042602539},
  { x = 878.437438964844, y = -556.980346679688, z = 57.0162239074707},
  { x = 854.214904785156, y = -565.665466308594, z = 57.4186058044434},
  { x = 917.097778320313, y = -621.714904785156, z = 57.5890579223633},
  { x = 983.444641113281, y = -708.400329589844, z = 57.3073081970215},
  { x = 1090.53833007813, y = -791.255737304688, z = 58.0193672180176},
  { x = 1009.076171875, y = -590.626403808594, z = 58.690788269043},
  { x = 1053.470703125, y = -489.113891601563, z = 63.5801620483398},
  { x = 1071.23400878906, y = -447.562896728516, z = 65.3984756469727},
  { x = 972.033752441406, y = -554.108215332031, z = 58.8319549560547},
  { x = -206.080169677734, y = -1318.03527832031, z = 30.5125579833984},
  { x = -151.778945922852, y = -1349.14709472656, z = 29.463903427124},
  { x = -214.70263671875, y = -1359.99255371094, z = 30.8813018798828},
  { x = -106.83226776123, y = -1457.93762207031, z = 33.0243949890137},
  { x = -53.0842018127441, y = -1505.03540039063, z = 30.9284286499023},
  { x = -191.262603759766, y = -1608.03076171875, z = 33.6884918212891},
  { x = -107.097640991211, y = -1598.89270019531, z = 31.2714824676514},
  { x = -13.6944303512573, y = -1453.07653808594, z = 29.963399887085},
  { x = 11.373348236084, y = -1455.75622558594, z = 29.9189186096191},
  { x = 148.119903564453, y = -1517.82336425781, z = 28.5764427185059},
  { x = 224.491546630859, y = -1520.30322265625, z = 28.5792541503906},
  { x = 403.846832275391, y = -1502.89172363281, z = 28.7238178253174},
  { x = 467.354461669922, y = -1579.06457519531, z = 28.5578155517578},
  { x = 393.531311035156, y = -1436.67004394531, z = 28.8963184356689},
  { x = 333.338714599609, y = -1261.2724609375, z = 31.1195201873779},
  { x = 497.880340576172, y = -1335.07336425781, z = 28.7632160186768},
  { x = 498.269134521484, y = -1400.85144042969, z = 28.8060188293457},
  { x = 479.41357421875, y = -1517.90832519531, z = 28.7261981964111},
  { x = -63.1068229675293, y = -1789.77734375, z = 27.3188400268555},
  { x = 18.1376876831055, y = -1879.91833496094, z = 22.6591415405273},
  { x = 93.9403533935547, y = -1960.46398925781, z = 20.3599662780762},
  { x = 115.805252075195, y = -1931.6064453125, z = 20.3829689025879},
  { x = 157.643142700195, y = -1895.97875976563, z = 22.6697120666504},
  { x = 199.111679077148, y = -1897.39379882813, z = 23.8366222381592},
  { x = 176.815093994141, y = -1837.81481933594, z = 27.7052974700928},
  { x = 243.076507568359, y = -1854.3154296875, z = 26.2651119232178},
  { x = 227.982315063477, y = -1714.19995117188, z = 28.7936859130859},
  { x = 335.734924316406, y = -1755.53869628906, z = 28.7484760284424},
  { x = 298.528900146484, y = -1802.91943359375, z = 27.0873889923096},
  { x = 128.719940185547, y = -1715.08996582031, z = 28.7247829437256},
  { x = 431.897003173828, y = -1852.5224609375, z = 27.159065246582},
  { x = 249.754867553711, y = -1955.12683105469, z = 22.7369632720947},
  { x = 158.364028930664, y = -1969.00952148438, z = 18.1727161407471},
  { x = 320.95068359375, y = -1983.98608398438, z = 22.5428123474121},
  { x = 361.352874755859, y = -2062.46362304688, z = 21.1120758056641},
  { x = 449.619964599609, y = -1961.78186035156, z = 22.5744915008545},
  { x = 495.053131103516, y = -1969.17468261719, z = 24.5272254943848},
  { x = 478.685485839844, y = -1888.86437988281, z = 25.7081508636475},
  { x = 527.154907226563, y = -1830.65100097656, z = 27.7945537567139},
  { x = 499.024108886719, y = -1720.14123535156, z = 28.9230213165283},
  { x = 480.19287109375, y = -1776.34997558594, z = 28.17746925354},
  { x = 516.267639160156, y = -1987.08154296875, z = 24.4292316436768},
  { x = 83.5366134643555, y = -2560.27319335938, z = 5.61167287826538},
  { x = -345.338989257813, y = 112.053901672363, z = 66.2454071044922},
  { x = -397.341064453125, y = 136.209030151367, z = 65.0139541625977},
  { x = -357.603210449219, y = 29.5045299530029, z = 47.3471260070801},
  { x = -509.991149902344, y = 117.059188842773, z = 62.9262809753418},
  { x = -426.307189941406, y = -24.4472904205322, z = 45.793270111084},
  { x = -646.845886230469, y = 32.2951354980469, z = 38.9617385864258},
  { x = -695.284729003906, y = 40.4299240112305, z = 42.7703437805176},
  { x = -642.420593261719, y = 105.648887634277, z = 56.4914627075195},
  { x = -477.898010253906, y = 224.572387695313, z = 82.6851654052734},
  { x = -421.778564453125, y = 293.303253173828, z = 82.7933502197266},
  { x = -349.973480224609, y = 217.803176879883, z = 86.0165405273438},
  { x = -311.754608154297, y = 227.975570678711, z = 87.411506652832},
  { x = -559.525512695313, y = 300.540161132813, z = 82.6860198974609},
  { x = -773.259338378906, y = 297.901824951172, z = 85.1530609130859},
  { x = -739.878601074219, y = 241.291397094727, z = 75.8833618164063},
  { x = -639.6669921875, y = 168.995559692383, z = 60.6939163208008},
  { x = -825.281616210938, y = 177.80989074707, z = 70.6563720703125},
  { x = -839.051818847656, y = 113.525749206543, z = 54.7545013427734},
  { x = -1046.44592285156, y = 219.620895385742, z = 63.1960334777832},
  { x = -987.833129882813, y = 144.561172485352, z = 60.0635757446289},
  { x = -956.985534667969, y = 115.316078186035, z = 56.3222732543945},
  { x = -920.415832519531, y = 107.748840332031, z = 54.7536239624023},
  { x = -953.544494628906, y = 187.443695068359, z = 66.0121154785156},
  { x = -925.919921875, y = 12.5866889953613, z = 47.1334228515625},
  { x = -833.679748535156, y = -35.751953125, z = 38.1416053771973},
  { x = -891.493591308594, y = -2.13482284545898, z = 42.8728981018066},
  { x = -707.653625488281, y = -185.055709838867, z = 36.286506652832},
  { x = -736.120910644531, y = -135.057693481445, z = 36.6698455810547},
  { x = -693.238952636719, y = -267.792358398438, z = 35.6989402770996},
  { x = -725.841552734375, y = -424.554534912109, z = 34.6384391784668},
  { x = -483.000213623047, y = -452.832427978516, z = 33.6180801391602},
  { x = -930.965209960938, y = -461.445678710938, z = 36.5572166442871},
  { x = -1022.22869873047, y = -492.600341796875, z = 36.393669128418},
  { x = -1083.98754882813, y = -375.209869384766, z = 36.2828674316406},
  { x = -1041.00256347656, y = -387.940582275391, z = 37.1276512145996},
  { x = -489.890258789063, y = -57.8195838928223, z = 39.4080772399902},
  { x = -459.117950439453, y = -137.876342773438, z = 37.7294998168945},
  { x = -1158.54418945313, y = -226.049575805664, z = 37.3476867675781},
  { x = -1096.38989257813, y = -317.182922363281, z = 37.0811614990234},
  { x = -1167.88439941406, y = -335.995910644531, z = 37.0393447875977},
  { x = -1159.66394042969, y = -399.218536376953, z = 35.2171363830566},
  { x = -1285.06042480469, y = -428.360656738281, z = 34.1927833557129},
  { x = -1345.60363769531, y = -293.904479980469, z = 39.556827545166},
  { x = -1355.54406738281, y = -216.085372924805, z = 43.1127738952637},
  { x = -1460.88781738281, y = -30.0602798461914, z = 54.0585327148438},
  { x = -1549.58898925781, y = -82.2022399902344, z = 53.5496940612793},
  { x = -1558.42346191406, y = -36.5513725280762, z = 56.2246398925781},
  { x = -1465.9638671875, y = 40.2094383239746, z = 53.3123359680176},
  { x = -1567.9599609375, y = 31.9729785919189, z = 58.474910736084},
  { x = -1544.01892089844, y = 125.423881530762, z = 56.1950454711914},
  { x = -1243.25708007813, y = 385.332092285156, z = 74.8804092407227},
  { x = -1396.58581542969, y = -294.828826904297, z = 42.9301376342773},
  { x = -1275.1884765625, y = -558.754516601563, z = 29.4832954406738},
  { x = -1198.26147460938, y = -732.103393554688, z = 20.338794708252},
  { x = -1221.9326171875, y = -705.452880859375, z = 21.9235076904297},
  { x = -754.695373535156, y = -912.980224609375, z = 18.7608795166016},
  { x = -822.445251464844, y = -990.14111328125, z = 13.0752420425415},
  { x = -770.191345214844, y = -1302.67626953125, z = 4.40547657012939},
  { x = -855.579284667969, y = -1270.13977050781, z = 4.41537761688232},
  { x = -683.339782714844, y = -885.247619628906, z = 23.9142284393311},
  { x = -948.41650390625, y = -1082.64819335938, z = 1.5385490655899},
  { x = -1072.21813964844, y = -1158.8486328125, z = 1.52664005756378},
  { x = -988.570922851563, y = -985.8173828125, z = 1.36811316013336},
  { x = -1120.69995117188, y = -1063.10327148438, z = 1.39628577232361},
  { x = -1093.37817382813, y = -919.305236816406, z = 2.29149770736694},
  { x = -1276.34350585938, y = -1152.94787597656, z = 5.5441370010376},
  { x = -1253.9658203125, y = -1197.61608886719, z = 6.34510087966919},
  { x = -1339.50646972656, y = -1210.49499511719, z = 3.96823167800903},
  { x = -1279.34484863281, y = -1251.06213378906, z = 3.29812169075012},
  { x = -1153.234375, y = -1520.67614746094, z = 3.64794492721558},
  { x = -1185.71105957031, y = -1562.92419433594, z = 3.65394926071167},
  { x = -1132.697265625, y = -1582.4326171875, z = 3.55767679214478},
  { x = -1083.09106445313, y = -1535.39392089844, z = 3.84467601776123},
  { x = -1067.95288085938, y = -1538.41821289063, z = 4.11108350753784},
  { x = -1021.89056396484, y = -1519.9560546875, z = 4.89227819442749},
  { x = -1054.50463867188, y = -1571.13122558594, z = 4.0337233543396},
  { x = -1105.31286621094, y = -1681.4150390625, z = 3.62900733947754},
  { x = -941.772766113281, y = -1524.78881835938, z = 4.33578824996948},
  { x = -990.477905273438, y = -1437.67309570313, z = 4.34794092178345},
  { x = -1210.47351074219, y = -1148.54956054688, z = 6.94658946990967},
  { x = -1379.82702636719, y = -973.952514648438, z = 8.07372856140137},
  { x = -1468.36853027344, y = -925.037353515625, z = 9.58611583709717},
  { x = -1297.83459472656, y = -787.924682617188, z = 17.0836410522461},
  { x = -1268.61389160156, y = -818.876708984375, z = 16.6243114471436},
  { x = -1407.99182128906, y = -735.800415039063, z = 23.0887184143066},
  { x = -1377.88793945313, y = -652.622497558594, z = 28.2150058746338},
  { x = -1642.96533203125, y = -993.046203613281, z = 12.5428237915039},
  { x = -1691.28979492188, y = -1068.29382324219, z = 12.5562171936035},
  { x = -1818.53234863281, y = -1210.51550292969, z = 12.5427179336548},
  { x = -1540.11462402344, y = -582.15087890625, z = 33.2285423278809},
  { x = -1526.26147460938, y = -281.718872070313, z = 48.6887893676758},
  { x = -1570.37072753906, y = -288.545227050781, z = 47.6945915222168},
  { x = -1567.60192871094, y = -236.082565307617, z = 48.8926277160645},
  { x = -1610.322265625, y = -382.220367431641, z = 42.5706596374512},
  { x = -1608.48828125, y = -413.600250244141, z = 40.8177070617676},
  { x = -1668.81750488281, y = -452.784637451172, z = 38.6393394470215},
  { x = -1714.82043457031, y = -502.125366210938, z = 37.5113868713379},
  { x = -1711.01318359375, y = -416.278228759766, z = 44.0267486572266},
  { x = -1656.42749023438, y = -357.58056640625, z = 48.8499755859375},
  { x = -1775.29406738281, y = -364.032867431641, z = 44.7817306518555},
  { x = -1863.40234375, y = -352.799896240234, z = 48.6571655273438},
  { x = -2183.59985351563, y = -408.342437744141, z = 12.469780921936},
  { x = -1929.66540527344, y = -530.206298828125, z = 11.2496871948242},
  { x = -1897.53198242188, y = -556.751281738281, z = 11.154369354248},
  { x = -1862.7236328125, y = -585.575744628906, z = 10.9879150390625},
  { x = -1802.40234375, y = -637.487426757813, z = 10.4068717956543},
  { x = -1758.70397949219, y = -682.206176757813, z = 9.49457454681396},
  { x = -1082.61889648438, y = 456.733764648438, z = 76.3031158447266},
  { x = -1039.49841308594, y = 496.919799804688, z = 82.054817199707},
  { x = -858.334350585938, y = 515.422668457031, z = 89.1987915039063},
  { x = -918.225280761719, y = 579.730895996094, z = 99.0909881591797},
  { x = -1022.71704101563, y = 593.901428222656, z = 102.37043762207},
  { x = -1383.03857421875, y = 450.747894287109, z = 104.104797363281},
  { x = -1449.8525390625, y = 531.747314453125, z = 118.468521118164},
  { x = -1539.69030761719, y = 427.578247070313, z = 108.835731506348},
  { x = -1353.65515136719, y = 567.254638671875, z = 129.946884155273},
  { x = -1284.90588378906, y = 644.803039550781, z = 138.594711303711},
  { x = -1117.29162597656, y = 774.75341796875, z = 161.646728515625},
  { x = -1048.46252441406, y = 767.957885742188, z = 166.836151123047},
  { x = -910.521057128906, y = 697.753173828125, z = 150.719833374023},
  { x = -695.307739257813, y = 666.498901367188, z = 153.162490844727},
  { x = -696.717468261719, y = 706.821899414063, z = 156.824630737305},
  { x = -580.781188964844, y = 739.828308105469, z = 183.007995605469},
  { x = -746.078308105469, y = 816.215942382813, z = 212.794815063477},
  { x = -968.549499511719, y = 764.239562988281, z = 174.750885009766},
  { x = -472.506805419922, y = 652.219665527344, z = 143.608108520508},
  { x = -347.918975830078, y = 636.378967285156, z = 171.423629760742},
  { x = -225.667541503906, y = 594.723815917969, z = 189.643768310547},
  { x = -483.942352294922, y = 553.29541015625, z = 119.060554504395},
  { x = -411.493103027344, y = 555.736389160156, z = 123.182189941406},
  { x = -362.981781005859, y = 509.676635742188, z = 118.377410888672},
  { x = -231.069961547852, y = 497.976867675781, z = 127.233642578125},
  { x = -3.63188219070435, y = 472.345947265625, z = 145.123123168945},
  { x = 115.164993286133, y = 490.907501220703, z = 146.428985595703},
  { x = 226.296096801758, y = 679.674255371094, z = 188.863845825195},
  { x = 118.493515014648, y = 569.005310058594, z = 182.409606933594},
  { x = 9.64954662322998, y = 545.573791503906, z = 175.11296081543},
  { x = -63.1068229675293, y = -1789.77734375, z = 27.3188400268555},
  { x = 18.1376876831055, y = -1879.91833496094, z = 22.6591415405273},
  { x = 93.9403533935547, y = -1960.46398925781, z = 20.3599662780762},
  { x = 115.805252075195, y = -1931.6064453125, z = 20.3829689025879},
  { x = 157.643142700195, y = -1895.97875976563, z = 22.6697120666504},
  { x = 199.111679077148, y = -1897.39379882813, z = 23.8366222381592},
  { x = 176.815093994141, y = -1837.81481933594, z = 27.7052974700928},
  { x = 243.076507568359, y = -1854.3154296875, z = 26.2651119232178},
  { x = 227.982315063477, y = -1714.19995117188, z = 28.7936859130859},
  { x = 335.734924316406, y = -1755.53869628906, z = 28.7484760284424},
  { x = 298.528900146484, y = -1802.91943359375, z = 27.0873889923096},
  { x = 128.719940185547, y = -1715.08996582031, z = 28.7247829437256},
  { x = 431.897003173828, y = -1852.5224609375, z = 27.159065246582},
  { x = 249.754867553711, y = -1955.12683105469, z = 22.7369632720947},
  { x = 158.364028930664, y = -1969.00952148438, z = 18.1727161407471},
  { x = 320.95068359375, y = -1983.98608398438, z = 22.5428123474121},
  { x = 361.352874755859, y = -2062.46362304688, z = 21.1120758056641},
  { x = 449.619964599609, y = -1961.78186035156, z = 22.5744915008545},
  { x = 495.053131103516, y = -1969.17468261719, z = 24.5272254943848},
  { x = 478.685485839844, y = -1888.86437988281, z = 25.7081508636475},
  { x = 527.154907226563, y = -1830.65100097656, z = 27.7945537567139},
  { x = 499.024108886719, y = -1720.14123535156, z = 28.9230213165283},
  { x = 480.19287109375, y = -1776.34997558594, z = 28.17746925354},
  { x = 516.267639160156, y = -1987.08154296875, z = 24.4292316436768},
  { x = 83.5366134643555, y = -2560.27319335938, z = 5.61167287826538},
  { x = -41.2876281738281, y = -2508.9697265625, z = 5.62094259262085},
  { x = -256.736572265625, y = -2653.59643554688, z = 5.61118936538696},
  { x = -406.068664550781, y = -2799.0322265625, z = 5.60997343063354},
  { x = -68.2952651977539, y = -2651.14672851563, z = 5.60910415649414},
  { x = 144.771682739258, y = -3331.01391601563, z = 5.63123273849487},
  { x = 1235.23852539063, y = -3205.35205078125, z = 5.2932333946228},
  { x = 782.038696289063, y = -2982.02368164063, z = 5.4059853553772},
  { x = 959.550048828125, y = -2372.13989257813, z = 30.1417827606201},
  { x = 1050.63415527344, y = -2366.83447265625, z = 30.1897411346436},
  { x = 1088.68811035156, y = -2289.53930664063, z = 29.7793636322021},
  { x = 1041.94897460938, y = -2178.07690429688, z = 31.0512428283691},
  { x = 934.963134765625, y = -1964.57470703125, z = 30.0044727325439},
  { x = 924.246398925781, y = -2020.62280273438, z = 29.9459743499756},
  { x = 967.231506347656, y = -1816.20007324219, z = 30.6835784912109},
  { x = 946.368469238281, y = -1697.91320800781, z = 29.6896724700928},
  { x = 943.090209960938, y = -1455.56103515625, z = 30.8775959014893},
  { x = 1158.44934082031, y = -1316.01293945313, z = 34.3467903137207},
  { x = 1122.14929199219, y = -1516.86755371094, z = 34.2972297668457},
  { x = 1144.16955566406, y = -1406.31457519531, z = 34.1875534057617},
  { x = 1368.54125976563, y = 1148.37585449219, z = 113.178489685059},
  { x = 1526.16479492188, y = 2232.64599609375, z = 74.9987335205078},
  { x = 1256.78369140625, y = 2732.25512695313, z = 37.903621673584},
  { x = 1167.29711914063, y = 2694.9296875, z = 37.2437400817871},
  { x = 970.141967773438, y = 2713.61279296875, z = 38.9030723571777},
  { x = 992.998291015625, y = 2670.564453125, z = 39.4808349609375},
  { x = 639.194458007813, y = 2775.55639648438, z = 41.4039115905762},
  { x = 469.878387451172, y = 2615.11669921875, z = 42.5683555603027},
  { x = 210.685165405273, y = 2441.17944335938, z = 58.1409759521484},
  { x = 2328.56982421875, y = 2536.35229492188, z = 46.0820045471191},
  { x = 2340.09350585938, y = 2563.72924804688, z = 46.0874938964844},
  { x = 2355.49072265625, y = 2604.63671875, z = 46.0298919677734},
  { x = -2168.57250976563, y = 4280.140625, z = 48.3848724365234},
  { x = -3173.88549804688, y = 1287.88549804688, z = 13.048150062561},
  { x = -3186.60620117188, y = 1205.49169921875, z = 9.00630378723145},
  { x = -3223.00537109375, y = 1089.49377441406, z = 10.0752859115601},
  { x = -3229.71606445313, y = 935.228332519531, z = 13.1745624542236},
  { x = -3071.552734375, y = 660.567443847656, z = 10.4349632263184},
  { x = -3030.2353515625, y = 557.701049804688, z = 6.92861461639404},
  { x = -3087.87377929688, y = 341.875518798828, z = 6.81103372573853},
  { x = -3100.47436523438, y = 251.342041015625, z = 11.3144130706787},
  { x = -3085.12280273438, y = 226.084823608398, z = 13.4391069412231},
  { x = -2954.541015625, y = 56.8714408874512, z = 11.026927947998},
  { x = 911.395751953125, y = 3639.84936523438, z = 31.8263988494873},
  { x = 1386.66101074219, y = 3673.80810546875, z = 32.9897689819336},
  { x = 1449.73059082031, y = 3647.22094726563, z = 33.9458160400391},
  { x = 1552.91223144531, y = 3728.9931640625, z = 33.8886222839355},
  { x = 1736.66455078125, y = 3716.05908203125, z = 33.513500213623},
  { x = 1651.04333496094, y = 3715.67700195313, z = 33.4959411621094},
  { x = 1766.31213378906, y = 3737.62939453125, z = 33.3441429138184},
  { x = 1738.87829589844, y = 3777.90454101563, z = 33.4907302856445},
  { x = 1731.28869628906, y = 3906.158203125, z = 34.2488441467285},
  { x = 1805.48291015625, y = 3933.0302734375, z = 33.1589088439941},
  { x = 1871.23974609375, y = 3918.650390625, z = 32.413932800293},
  { x = 1735.21948242188, y = 3841.04418945313, z = 34.1998405456543},
  { x = 1842.48449707031, y = 3769.06030273438, z = 32.7706260681152},
  { x = 1984.5908203125, y = 3823.43334960938, z = 31.7744560241699},
  { x = 1906.23522949219, y = 3860.53344726563, z = 31.736156463623},
  { x = 2428.35791015625, y = 4017.60717773438, z = 36.18896484375},
  { x = 1674.25109863281, y = 4953.2294921875, z = 41.7437362670898},
  { x = 1660.30810546875, y = 4875.9296875, z = 41.437671661377},
  { x = 1668.93762207031, y = 4769.88134765625, z = 41.2895812988281},
  { x = 1689.79577636719, y = 4681.22314453125, z = 42.4225883483887},
  { x = 1710.91198730469, y = 4635.6796875, z = 42.7580299377441},
  { x = 1693.26672363281, y = 6428.77099609375, z = 32.02294921875},
  { x = 419.673522949219, y = 6520.1103515625, z = 27.1485118865967},
  { x = 144.997207641602, y = 6642.369140625, z = 30.9701557159424},
  { x = 25.9349040985107, y = 6655.5185546875, z = 30.8951015472412},
  { x = -11.4208126068115, y = 6641.86572265625, z = 30.4945182800293},
  { x = -6.34835910797119, y = 6620.44287109375, z = 30.7430229187012},
  { x = -126.502395629883, y = 6548.17236328125, z = 28.8517150878906},
  { x = -142.154541015625, y = 6439.4951171875, z = 30.7863731384277},
  { x = -26.3420734405518, y = 6456.259765625, z = 30.8693256378174},
  { x = 46.8197975158691, y = 6300.17236328125, z = 30.6521873474121},
  { x = -274.786987304688, y = 6248.19873046875, z = 30.8288879394531},
  { x = -356.575744628906, y = 6328.09326171875, z = 29.2854118347168},
  { x = -296.947021484375, y = 6340.74755859375, z = 31.2577152252197},
  { x = -263.952667236328, y = 6370.515625, z = 30.7237071990967},
  { x = -361.863677978516, y = 6275.29541015625, z = 30.0340919494629},
  { x = -394.516265869141, y = 6309.8251953125, z = 28.5605697631836},
  { x = -437.205017089844, y = 6202.87890625, z = 29.0140762329102},
  { x = -347.462097167969, y = 6215.3486328125, z = 30.908576965332},
  { x = -358.095367431641, y = 6066.47216796875, z = 30.9185104370117},
}

local function fsn_hasDirtyMoney()
  if inventory["dirty_money"] then
    return true
  else
    return false
  end
end

local function fsn_StartLaundering()
  --laundervan = CreateVehicle(GetHashKey("speedo2"), garagepos.x, garagepos.y, garagepos.z+2, 319.79782104492, true, true)
  local car = 'speedo2'
  local vehicle = GetHashKey(car)
  RequestModel(vehicle)
  while not HasModelLoaded(vehicle) do
    Wait(1)
  end
  local coords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0, 5.0, 0)
  local spawned_car = CreateVehicle(vehicle, garagepos.x, garagepos.y, garagepos.z+2, 319.79782104492, true, true)
  SetVehicleOnGroundProperly(spawned_car)
  SetModelAsNoLongerNeeded(vehicle)
  Citizen.InvokeNative(0xB736A491E64A32CF,Citizen.PointerValueIntInitialized(spawned_car))
  laundervan = spawned_car
  SetEntityAsMissionEntity(spawned_car, false, true)
  TriggerEvent('fsn_cargarage:makeMine', spawned_car, GetDisplayNameFromVehicleModel(GetEntityModel(spawned_car)), GetVehicleNumberPlateText(spawned_car))
  current_delivery = math.random(1, #launder_deliveries)
  laundering = true

  -- create blip
  delivery_blip = AddBlipForCoord(launder_deliveries[current_delivery].x, launder_deliveries[current_delivery].y, launder_deliveries[current_delivery].z)
  SetBlipSprite(delivery_blip, 1)
  SetBlipColour(delivery_blip, 1)
  SetBlipRoute(delivery_blip, true)
  SetBlipRouteColour(delivery_blip, 1)
  SetBlipAsShortRange(delivery_blip, false)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString("Delivery")
  EndTextCommandSetBlipName(delivery_blip)
end

local function fsn_NextLaundering(trig)
  if GetEntityModel(GetVehiclePedIsIn(GetPlayerPed(-1), true)) ~= GetHashKey("speedo2") then
    TriggerEvent('fsn_notify:displayNotification', 'Deliveries must be completed in the vehicle provided', 'centerRight', 4000, 'error')
    return
  end
  if not trig then
    done_deliveries = done_deliveries+1
    TriggerEvent('fsn_notify:displayNotification', 'You completed this delivery', 'centerLeft', 4000, 'success')
  end
  if done_deliveries >= needed_delivery then
    RemoveBlip(delivery_blip)
    delivery_blip = AddBlipForCoord(garagepos.x, garagepos.y, garagepos.z)
    SetBlipSprite(delivery_blip, 1)
    SetBlipColour(delivery_blip, 5)
    SetBlipRoute(delivery_blip, true)
    SetBlipRouteColour(delivery_blip, 5)
    SetBlipAsShortRange(delivery_blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Delivery")
    EndTextCommandSetBlipName(delivery_blip)
    laundering = false
    laundering_complete = true
    TriggerEvent('fsn_notify:displayNotification', 'Head back to grove street to get your money', 'centerRight', 4000, 'info')
  else
    local new = math.random(1, #launder_deliveries)
    if new ~= current_delivery then
      RemoveBlip(delivery_blip)
      TriggerEvent('fsn_notify:displayNotification', 'New delivery spot added to the GPS', 'centerLeft', 4000, 'info')
      current_delivery = new
      -- create blip
      delivery_blip = AddBlipForCoord(launder_deliveries[current_delivery].x, launder_deliveries[current_delivery].y, launder_deliveries[current_delivery].z)
      SetBlipSprite(delivery_blip, 1)
      SetBlipColour(delivery_blip, 1)
      SetBlipRoute(delivery_blip, true)
      SetBlipRouteColour(delivery_blip, 1)
      SetBlipAsShortRange(delivery_blip, false)
      BeginTextCommandSetBlipName("STRING")
      AddTextComponentString("Delivery")
      EndTextCommandSetBlipName(delivery_blip)
    else
      fsn_NextLaundering(true)
    end
  end
end

local function fsn_FinishLaundering()
  RemoveBlip(delivery_blip)
  if inventory["dirty_money"].amount == dm_amount then
    local amount = inventory["dirty_money"].amount
    local minus = inventory["dirty_money"].amount / quote[1]
    amount = amount - math.floor(minus)
    TriggerEvent('fsn_notify:displayNotification', 'Well done, here\'s your cash ($'..amount..')', 'centerLeft', 6000, 'info')
    TriggerEvent('fsn_bank:change:walletAdd', amount)
    TriggerEvent('fsn_inventory:item:take', 'dirty_money', inventory["dirty_money"].amount)
  else
    TriggerEvent('fsn_notify:displayNotification', 'Do not try to cheat my system, get outta here, you just lost all your DM and 20k.', 'centerLeft', 4000, 'info')
    TriggerEvent('fsn_inventory:item:take', 'dirty_money', inventory["dirty_money"].amount)
    TriggerEvent('fsn_bank:change:walletMinus', 20000)
  end

  SetEntityAsMissionEntity( laundervan, true, true )
  Citizen.InvokeNative( 0xEA386986E786A54F, Citizen.PointerValueIntInitialized( laundervan ) )

  laundering = false
  laundervan = false
  laundering_complete = false
  current_delivery = 0
  done_deliveries = 0
  needed_delivery = 0
  abletolaunder = false
end

Citizen.CreateThread(function()
  local blip = AddBlipForCoord(salepos.x, salepos.y, salepos.z)
  SetBlipSprite(blip, 277)
  SetBlipColour(blip, 1)
  SetBlipAsShortRange(blip, true)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString("Unknown")
  EndTextCommandSetBlipName(blip)
  while true do
    Citizen.Wait(0)
    local pos = GetEntityCoords(GetPlayerPed(-1))
    if laundering then
      if GetDistanceBetweenCoords(launder_deliveries[current_delivery].x, launder_deliveries[current_delivery].y, launder_deliveries[current_delivery].z, GetEntityCoords(GetPlayerPed(-1)).x, GetEntityCoords(GetPlayerPed(-1)).y, GetEntityCoords(GetPlayerPed(-1)).z) < 5 then
        SetTextComponentFormat("STRING")
        AddTextComponentString("Press ~INPUT_PICKUP~ to deliver the ~r~drugs~w~.")
        DisplayHelpTextFromStringLabel(0, 0, 1, -1)
        if IsControlJustPressed(0, 38) then
          fsn_NextLaundering()
        end
      end
    end
    if fsn_hasDirtyMoney() then
      if GetDistanceBetweenCoords(salepos.x, salepos.y, salepos.z, GetEntityCoords(GetPlayerPed(-1)).x, GetEntityCoords(GetPlayerPed(-1)).y, GetEntityCoords(GetPlayerPed(-1)).z) < 10 then
        DrawMarker(1, salepos.x, salepos.y, salepos.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8, 2.0, 255, 255, 0, 75, 0, 0, 2, 0, 0, 0, 0)
        if GetDistanceBetweenCoords(salepos.x, salepos.y, salepos.z, GetEntityCoords(GetPlayerPed(-1)).x, GetEntityCoords(GetPlayerPed(-1)).y, GetEntityCoords(GetPlayerPed(-1)).z) < 1 then
          if not abletolaunder then
            SetTextComponentFormat("STRING")
            AddTextComponentString("~r~Come back later, I\'m not dealing right now.")
            DisplayHelpTextFromStringLabel(0, 0, 1, -1)
          elseif laundering_complete then
            SetTextComponentFormat("STRING")
            AddTextComponentString("Press ~INPUT_PICKUP~ to get ~g~paid.")
            DisplayHelpTextFromStringLabel(0, 0, 1, -1)
            if IsControlJustPressed(0, 38) then
              fsn_FinishLaundering()
            end
          elseif not laundering then
            if not quoted then
              SetTextComponentFormat("STRING")
              AddTextComponentString("Press ~INPUT_PICKUP~ to get a quote for your dirty money.")
              DisplayHelpTextFromStringLabel(0, 0, 1, -1)
              if IsControlJustPressed(0, 38) then
                --TriggerEvent('chatMessage', 'Dealer', {244, 223, 66}, 'Deliver these '..quote[2]..' drug packages for me, and I\'ll do you '..quote[1]..' on those unmarked bills')
                local amount = inventory["dirty_money"].amount
                local minus = inventory["dirty_money"].amount / quote[1]
                amount = amount - math.floor(minus)
                SetNotificationTextEntry("STRING");
                AddTextComponentString('Deliver these ~r~'..quote[2]..'~w~ drug packages for me, and I\'ll do you ~g~$'..amount..'~w~ (~g~'..quote[1]..'%~w~) on those unmarked bills');
                SetNotificationMessage("CHAR_RON", "CHAR_RON", true, 1, "~y~Dealer's offer:~s~", "");
                DrawNotification(false, true);
                quoted = true
                needed_delivery = quote[2]
              end
            else
              SetTextComponentFormat("STRING")
              AddTextComponentString("Press ~INPUT_MP_TEXT_CHAT_TEAM~ to ~g~accept~w~ the offer\nPress ~INPUT_PUSH_TO_TALK~ to ~r~decline~w~ the offer")
              DisplayHelpTextFromStringLabel(0, 0, 1, -1)
              if IsControlJustPressed(0, 246) then
                TriggerEvent('chatMessage', 'Dealer', {244, 223, 66}, 'Go get the van from my garage, it has a fake plate so the fuzz shouldn\'t bother you.')
                fsn_StartLaundering(false)
                dm_amount = inventory["dirty_money"].amount
              end
              if IsControlJustPressed(0, 249) then
                abletolaunder = false
              end
            end
          end
        else
          if quoted then
            quoted = false
          end
        end
      end
    end
  end
end)

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(60000)
    if laundervan and laundering then
      if IsVehicleDriveable(laundervan, true) == false then
        TriggerEvent("pNotify:SendNotification", {text = "Your vehicle was destroyed!<br>The dealer won't trust you for <b>15 minutes",
            layout = "centerRight",
            timeout = 5000,
            progressBar = true,
            type = "error",
        })
        RemoveBlip(delivery_blip)
        laundering = false
        laundervan = false
        laundering_complete = false
        current_delivery = 0
        done_deliveries = 0
        needed_delivery = 0
        abletolaunder = false
      end
    end
  end
end)

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(900000)
    quote[1] = math.random(10,35)
    quote[2] = math.random(10, 20)
    abletolaunder = true
  end
end)
---------------------------------------------------------------------------------------- Selling Burgers
local goods = {
  ["burger"] = {
    street_price = 100
 -- },
  --["meth_rocks"] = {
    --street_price = 450
  --},
  --["joint"] = {
    --street_price = 300
  }
}

function fsn_isPedPlayer(ped)
  for id = 0, 31 do
    if NetworkIsPlayerActive(id) then
      if GetPlayerPed(id) == ped then
        return true
      end
    end
  end
  return false
end

function fsn_getPlayerGoods()
  for k, v in pairs(goods) do
    if inventory[k] then
      return k
    end
  end
  return false
end

local selling = false
local selling_item = ''
local selling_start = 0
local selling_ped = nil
local sold_peds = {}
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    if init then
      local goodsas = fsn_getPlayerGoods()
      if not IsPedInAnyVehicle(GetPlayerPed(-1)) then
        if goodsas ~= false and not selling then
          for obj in EnumeratePeds() do
            if obj ~= GetPlayerPed(-1) and not IsEntityDead(obj) and not IsPedInAnyVehicle(obj) and GetDistanceBetweenCoords(GetEntityCoords(obj), GetEntityCoords(GetPlayerPed(-1))) < 2 and not IsEntityDead(obj) then
              --fsn_drawText3D(GetEntityCoords(obj).x, GetEntityCoords(obj).y, GetEntityCoords(obj).z, '')
              if table.contains(sold_peds, obj) then
                fsn_drawText3D(GetEntityCoords(obj).x, GetEntityCoords(obj).y, GetEntityCoords(obj).z, '~R~Already bought')
              else
                local netId = NetworkGetNetworkIdFromEntity(obj)
                if not NetworkHasControlOfNetworkId(netId) then
                  NetworkRequestControlOfNetworkId(netId)
                  while not NetworkHasControlOfNetworkId(netId) do
                    Citizen.Wait(1)
                  end
                end
                fsn_drawText3D(GetEntityCoords(obj).x, GetEntityCoords(obj).y, GetEntityCoords(obj).z, 'Press ~g~E~w~ to sell '..goodsas)
                --SetTextComponentFormat("STRING")
                --AddTextComponentString("Press ~INPUT_PICKUP~ to sell ~g~"..items_table[drugas].display_name)
                --DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                if IsControlJustPressed(0, 38) then
                  table.insert(sold_peds, #sold_peds+1, {obj, true})
                  TriggerEvent('fsn_notify:displayNotification', 'You ask if they would like to buy...', 'centerLeft', 3000, 'info')
                  Citizen.Wait(1000)
                  local try = math.random(0, 100)
                  --[[
                  if not NetworkIsPlayerTalking(PlayerId()) then
                    TriggerEvent('fsn_notify:displayNotification', 'How do you expect to sell drugs without talking?', 'centerLeft', 3000, 'error')
                      try = 57
                  end
                  ]]
                  if try > 58 then
                    selling = true
                    selling_ped = obj
                    selling_item = goodsas
                    ClearPedTasksImmediately(obj)
                    TaskStandStill(obj, 9000)
                    selling_start = GetNetworkTime()
                  --else
                    --try = math.random(0, 100)
                    --if try > 20 then
                      --while not HasAnimDictLoaded('cellphone@') do
                        --RequestAnimDict('cellphone@')
                        --Citizen.Wait(5)
                      --end
                      --SetEntityAsMissionEntity(obj, true, true)
                      ----ResurrectPed(obj)
                      --ClearPedTasksImmediately(obj)
                      --SetEntityAsNoLongerNeeded(obj)
                      --TaskPlayAnim(obj, 'cellphone@', 'cellphone_call_listen_base', 8.0, 1.0, -1, 49, 1.0, 0, 0, 0)
                      --fsn_drawText3D(GetEntityCoords(obj).x, GetEntityCoords(obj).y, GetEntityCoords(obj).z, '~R~Calling the police!')
                      --if not IsEntityDead(obj) then
                        --local pos = GetEntityCoords(obj)
                        --local coords = {
                          --x = pos.x,
                          --y = pos.y,
                          --z = pos.z
                        --}
                        --TriggerServerEvent('fsn_police:dispatch', coords, 3)
                      --end
                    --end
                    --TriggerEvent('fsn_notify:displayNotification', 'They are not interested', 'centerLeft', 3000, 'error')
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end)
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    if selling then
      local rem = selling_start+8000
      if rem > GetNetworkTime() then
        if GetEntitySpeed(selling_ped) < 1 and not IsEntityDead(selling_ped) and GetDistanceBetweenCoords(GetEntityCoords(selling_ped), GetEntityCoords(GetPlayerPed(-1))) < 3 then
          fsn_drawText3D(GetEntityCoords(selling_ped).x, GetEntityCoords(selling_ped).y, GetEntityCoords(selling_ped).z, 'Selling: ~b~'..string.sub(tostring(math.ceil(rem-GetNetworkTime())), 1, 1)..'s~w~ remaining')
        else
          if selling then
            TriggerEvent('fsn_notify:displayNotification', 'The transaction was <span style="color:red">cancelled', 'centerLeft', 3000, 'info')
            selling = false
            selling_start = 0
            selling_ped = false
          end
        end
      else
        if fsn_GetItemAmount(selling_item) < 2 then
          sold_amount = fsn_GetItemAmount(selling_item)
        else
          sold_amount = math.random(1, 2)
        end
        local price = math.random(goods[selling_item].street_price - 10, goods[selling_item].street_price + 100)
        price = price * sold_amount
        if exports.fsn_police:fsn_getCopAmt() < 1 then
          --TriggerEvent('chatMessage', '', {255,255,255}, '^8^*:FSN:^0^r This is a police related action, there are no police online so your earnings have been halved.')
          --price = price / 2
        end
        TriggerEvent('fsn_notify:displayNotification', 'They bought '..sold_amount..' '..items_table[selling_item].display_name..' for '..price..'.', 'centerLeft', 3000, 'info')
        TriggerEvent('fsn_bank:change:walletAdd', price)
        TriggerEvent('fsn_inventory:item:take', selling_item, sold_amount)
        if selling then
          selling = false
          selling_start = 0
          selling_ped = false
        end
      end
    end
  end
end)
