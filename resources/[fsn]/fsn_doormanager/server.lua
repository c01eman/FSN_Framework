local policeDoors = {
  -- Mission Row To locker room & roof
  [1] = { ["objName"] = "v_ilev_ph_gendoor004", ["x"]= 449.69815063477, ["y"]= -986.46911621094,["z"]= 30.689594268799,["locked"]= true,["txtX"]=450.104,["txtY"]=-986.388,["txtZ"]=31.739},
  -- Mission Row Armory
  [2] = { ["objName"] = "v_ilev_arm_secdoor", ["x"]= 452.61877441406, ["y"]= -982.7021484375,["z"]= 30.689598083496,["locked"]= true,["txtX"]=453.079,["txtY"]=-982.600,["txtZ"]=31.739},
  -- Mission Row Captain Office
  [3] = { ["objName"] = "v_ilev_ph_gendoor002", ["x"]= 447.23818969727, ["y"]= -980.63006591797,["z"]= 30.689598083496,["locked"]= true,["txtX"]=447.200,["txtY"]=-980.010,["txtZ"]=31.739},
  -- Mission Row To downstairs right
  [4] = { ["objName"] = "v_ilev_ph_gendoor005", ["x"]= 443.97, ["y"]= -989.033,["z"]= 30.6896,["locked"]= true,["txtX"]=444.020,["txtY"]=-989.445,["txtZ"]=31.739},
  -- Mission Row To downstairs left
  [5] = { ["objName"] = "v_ilev_ph_gendoor005", ["x"]= 445.37, ["y"]= -988.705,["z"]= 30.6896,["locked"]= true,["txtX"]=445.350,["txtY"]=-989.445,["txtZ"]=31.739},
  -- Mission Row Main cells
  [6] = { ["objName"] = 631614199, ["x"]= 464.0, ["y"]= -992.265,["z"]= 24.9149,["locked"]= true,["txtX"]=463.465,["txtY"]=-992.664,["txtZ"]=25.064},
  -- Mission Row Cell 1
  [7] = { ["objName"] = 631614199, ["x"]= 462.381, ["y"]= -993.651,["z"]= 24.9149,["locked"]= true,["txtX"]=461.806,["txtY"]=-993.308,["txtZ"]=25.064},
-- Mission Row Cell 2
  [8] = { ["objName"] = 631614199, ["x"]= 462.331, ["y"]= -998.152,["z"]= 24.9149,["locked"]= true,["txtX"]=461.806,["txtY"]=-998.800,["txtZ"]=25.064},
  -- Mission Row Cell 3
  [9] = { ["objName"] = 631614199, ["x"]= 462.704, ["y"]= -1001.92,["z"]= 24.9149,["locked"]= true,["txtX"]=461.806,["txtY"]=-1002.450,["txtZ"]=25.064},
  -- Mission Row Backdoor in
  [10] = { ["objName"] = -1033001619, ["x"]= 464.126, ["y"]= -1002.78,["z"]= 24.9149,["locked"]= true,["txtX"]=464.100,["txtY"]=-1003.538,["txtZ"]=26.064},
  -- Mission Row Rooftop In
  [12] = { ["objName"] = "v_ilev_gtdoor02", ["x"]= 465.467, ["y"]= -983.446,["z"]= 43.6918,["locked"]= true,["txtX"]=464.361,["txtY"]=-984.050,["txtZ"]=44.834},
  -- rear right door
  [13] = { ["objName"] = -2023754432, ["x"]= 469.9679, ["y"]= -1014.452,["z"]= 26.53623,["locked"]= true,["txtX"]=468.9679,["txtY"]=-1014.452,["txtZ"]=26.53623},
  -- Rear left door
  [14] = { ["objName"] = -2023754432, ["x"]= 467.3716, ["y"]= -1014.452,["z"]= 26.53623,["locked"]= true,["txtX"]=468.3716,["txtY"]=-1014.452,["txtZ"]=26.53623},
  -- sandy shores office
  [15] = { ["objName"] = -1765048490 , ["x"]= 1855.685, ["y"]= 3683.93,["z"]= 34.59282,["locked"]= true,["txtX"]=1854.685,["txtY"]=3683.93,["txtZ"]=34.59282},
  -- paleto office right
  [16] = { ["objName"] = -1501157055 , ["x"]= -444.4985, ["y"]= 6017.06,["z"]= 31.86633,["locked"]= true,["txtX"]=-443.91278076172,["txtY"]=6016.58984375,["txtZ"]=31.716369628906},
  -- paleto office left
  [17] = { ["objName"] = -1501157055 , ["x"]= -443.20260620117, ["y"]= 6015.7021484375,["z"]= 31.716369628906,["locked"]= true,["txtX"]=-443.20260620117,["txtY"]=6015.7021484375,["txtZ"]=31.716369628906},
  -- MRPD Changing room
  [18] = { ["objName"] = -2023754432 , ["x"]= 452.624, ["y"]= -987.362, ["z"]= 30.839,["locked"]= true,["txtX"]= 451.624,["txtY"]=-987.362,["txtZ"]=30.839},
  -- MRPD Back gate
  [19] = { ["objName"] = -1603817716 , ["x"]= 488.894, ["y"]= -1017.210, ["z"]= 27.14,["locked"]= true,["txtX"]= 488.894,["txtY"]=-1017.210,["txtZ"]=28.145},
  -- Prison Front Gate
  [20] = { ["objName"] = 741314661, ["x"]= 1844.998, ["y"]= 2604.810, ["z"]= 44.636,["locked"]= true,["txtX"]= 1845.104,["txtY"]=2605.009,["txtZ"]=45.889},
  -- Prison Second Gate
  [21] = { ["objName"] = 741314661, ["x"]= 1818.539, ["y"]= 2604.791, ["z"]= 44.607,["locked"]= true,["txtX"]= 1818.616,["txtY"]=2605.176,["txtZ"]=45.570},
  -- Prison Left gate
  [22] = { ["objName"] = -1156020871, ["x"]= 1797.760, ["y"]= 2596.564, ["z"]= 46.387,["locked"]= true,["txtX"]= 1797.760,["txtY"]=2596.564,["txtZ"]=46.387},

}
local propertyDoors = {}

RegisterServerEvent('fsn_doormanager:unlockDoor')
AddEventHandler('fsn_doormanager:unlockDoor', function(doorType, doorID)
  if doorType == 'police' then
    local door = policeDoors[doorID]
    door["locked"] = false
    TriggerClientEvent('fsn_doormanager:doorUnlocked', -1, doorType, doorID)
  end
end)

RegisterServerEvent('fsn_doormanager:lockDoor')
AddEventHandler('fsn_doormanager:lockDoor', function(doorType, doorID)
  if doorType == 'police' then
    local door = policeDoors[doorID]
    door["locked"] = true
    TriggerClientEvent('fsn_doormanager:doorLocked', -1, doorType, doorID)
  end
end)

RegisterServerEvent('fsn_doormanager:requestDoors')
AddEventHandler('fsn_doormanager:requestDoors', function()
  TriggerClientEvent('fsn_doormanager:sendDoors', source, policeDoors, propertyDoors)
end)
