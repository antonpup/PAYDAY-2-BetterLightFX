Hooks:PostHook( HUDManager, "set_teammate_condition", "HUDManager:set_teammate_condition_BetterLightFX", function(self, i, icon_data, text)
    
    if i == HUDManager.PLAYER_PANEL and icon_data == "mugshot_swansong" then
        if BetterLightFX then
            BetterLightFX:StartEvent("SwanSong")
        end
    else
        if BetterLightFX then
            BetterLightFX:EndEvent("SwanSong")
        end
    end
end )