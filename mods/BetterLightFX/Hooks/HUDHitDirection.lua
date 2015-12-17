Hooks:PostHook( HUDHitDirection, "on_hit_direction", "HUDHitDirection:on_hit_direction_BetterLightFX", function(self)
    if BetterLightFX then
        BetterLightFX:StartEvent("TakenDamage")
        if self._unit_type_hit == HUDHitDirection.UNIT_TYPE_HIT_VEHICLE then
            BetterLightFX:UpdateEvent("TakenDamage", {["_color"] = Color(1, 1, 0)})
        else
            BetterLightFX:UpdateEvent("TakenDamage", {["_color"] = Color(1, 0, 0)})
        end 
    end
end )