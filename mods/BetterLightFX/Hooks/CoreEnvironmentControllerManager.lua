Hooks:PostHook( CoreEnvironmentControllerManager, "set_post_composite", "CoreEnvironmentControllerManager:set_post_composite_BetterLightFX", function(self, t, dt)

    if 0 < self._current_flashbang then
        if BetterLightFX then
            BetterLightFX:StartEvent("Flashbang")
            BetterLightFX:UpdateEvent("Flashbang", {["_flashamount"] = math.min(self._current_flashbang_flash, 1)})
        end
    else
        if BetterLightFX then
            BetterLightFX:EndEvent("Flashbang")
        end
    end
end )