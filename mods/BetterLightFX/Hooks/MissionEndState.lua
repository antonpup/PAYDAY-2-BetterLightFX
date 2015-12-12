Hooks:PostHook( MissionEndState, "at_enter", "MissionEndState_BetterLightFX_exit", function(self)
    if BetterLightFX and self._type == "gameover" then
        BetterLightFX:StartEvent("EndLoss")
    end
end )

Hooks:PostHook( MissionEndState, "at_exit", "MissionEndState_BetterLightFX_exit", function(self)
    if BetterLightFX then
            BetterLightFX:SetColor(0, 0, 0, 0, "EndLoss")
            BetterLightFX:EndEvent("EndLoss")
        end
end )
