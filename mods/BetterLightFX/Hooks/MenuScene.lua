CloneClass(MenuSceneManager)

function MenuSceneManager._open_safe_sequence(self)
    
    self.orig._open_safe_sequence(self)
    
     if BetterLightFX then
        BetterLightFX:UpdateEvent("SafeDrilled", {["_color"] = tweak_data.economy.rarities[self._safe_result_content_data.item_data.rarity].color})
        BetterLightFX:StartEvent("SafeDrilled")
    end
end

function MenuSceneManager._destroy_economy_safe(self)

    if BetterLightFX then
        BetterLightFX:EndEvent("SafeDrilled")
    end
    
    self.orig._destroy_economy_safe(self)
end



