Hooks:PostHook( PlayerTased, "_enter", "PlayerTased:_enter_BetterLightFX", function(self)
    if BetterLightFX then
        BetterLightFX:StartEvent("Electrocuted")
    end
end )

Hooks:PreHook( PlayerTased, "exit", "PlayerTased:exit_BetterLightFX", function(self)
    if BetterLightFX then
        BetterLightFX:EndEvent("Electrocuted")
    end
end )

Hooks:PreHook( PlayerTased, "_update_check_actions", "PlayerTased:_update_check_actions_BetterLightFX", function(self, t, dt)
    if BetterLightFX and t > self._next_shock then
        BetterLightFX:UpdateEvent("Electrocuted", {["_random_color"] = Color(1, math.random(), math.random(), math.random()), ["_alpha_fade_mod"] = 0})
    end
end )