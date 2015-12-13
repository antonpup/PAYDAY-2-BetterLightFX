Hooks:PostHook( HUDStageEndScreen, "level_up", "HUDStageEndScreen:level_up_BetterLightFX", function(self)
    if BetterLightFX then
            BetterLightFX:StartEvent("LevelUp")
    end
end )