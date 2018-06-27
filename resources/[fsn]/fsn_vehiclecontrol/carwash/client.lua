--fsn_GetWallet
local carwashes = {
  {x = -699.83117675781, y = -933.89617919922, z = 18.582984924316},
  {x = 25.57279586792, y = -1391.9577636719, z = 28.480260848999},
  {x = 433.40536499023, y = 3576.1430664063, z = 32.385959625244},
  {x = -238.81951904297, y = 6231.4731445313, z = 30.648466110229}
}
Citizen.CreateThread(function()
  for _, cwash in pairs(carwashes) do
    local blip = AddBlipForCoord(cwash.x, cwash.y, cwash.z)
    SetBlipSprite(blip, 100)
    SetBlipColour(blip, 4)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Car Wash")
    EndTextCommandSetBlipName(blip)
  end
  while true do
    Citizen.Wait(0)
    for _, cwash in pairs(carwashes) do
      if GetDistanceBetweenCoords(cwash.x, cwash.y, cwash.z, GetEntityCoords(GetPlayerPed(-1))) < 5 and IsPedInAnyVehicle(GetPlayerPed(-1)) then
        SetTextComponentFormat("STRING")
        AddTextComponentString("Press ~INPUT_PICKUP~ to wash your car!")
        DisplayHelpTextFromStringLabel(0, 0, 1, -1)
        if IsControlJustPressed(0,38) then
          if exports.fsn_main:fsn_GetWallet() >= 250 then
            SetVehicleDirtLevel(GetVehiclePedIsIn(GetPlayerPed(-1), 0.0))
            TriggerEvent('fsn_bank:change:walletMinus', 250)
          else
            TriggerEvent('fsn_notify:displayNotification', 'You cannot afford this', 'centerLeft', 5000, 'error')
          end
        end
      end
    end
  end
end)
