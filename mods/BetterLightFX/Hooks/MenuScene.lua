Hooks:PostHook( MenuSceneManager, "_open_safe_sequence", "MenuSceneManager:_open_safe_sequence_BetterLightFX", function(self)
    if BetterLightFX then
        BetterLightFX:UpdateEvent("SafeDrilled", {["_color"] = tweak_data.economy.rarities[self._safe_result_content_data.item_data.rarity].color})
        BetterLightFX:StartEvent("SafeDrilled")
    end
end )

Hooks:PostHook( MenuSceneManager, "_destroy_economy_safe", "MenuSceneManager:_destroy_economy_safe_BetterLightFX", function(self)
    if BetterLightFX then
        BetterLightFX:EndEvent("SafeDrilled")
    end
end )