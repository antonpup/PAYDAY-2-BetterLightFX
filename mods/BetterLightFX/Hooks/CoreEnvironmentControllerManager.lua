Hooks:PostHook( CoreEnvironmentControllerManager, "set_post_composite", "CoreEnvironmentControllerManager:set_post_composite_BetterLightFX_flashbang", function(self, t, dt)
    if 0 < self._current_flashbang then
        if BetterLightFX then
            BetterLightFX:StartEvent("Flashbang")
            BetterLightFX:UpdateEvent("Flashbang", {["_flashamount"] = math.min(self._current_flashbang, 1)})
        end
    else
        if BetterLightFX then
            BetterLightFX:EndEvent("Flashbang")
        end
    end
end )

Hooks:PostHook( CoreEnvironmentControllerManager, "set_post_composite", "CoreEnvironmentControllerManager:set_post_composite_BetterLightFX_TakenDamage", function(self, t, dt)
    if self._health_effect_value_diff > 0 then
        if BetterLightFX then
            BetterLightFX:StartEvent("TakenSevereDamage")
            BetterLightFX:UpdateEvent("TakenSevereDamage", {["_hurtamount"] = self._health_effect_value_diff})
        end
    else
        if BetterLightFX then
            BetterLightFX:EndEvent("TakenSevereDamage")
        end
    end
end )