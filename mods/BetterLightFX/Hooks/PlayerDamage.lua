function PlayerDamage:update_downed(t, dt)
    if self._downed_timer and self._downed_paused_counter == 0 then
        self._downed_timer = self._downed_timer - dt
        if self._downed_start_time == 0 then
            self._downed_progression = 100
        else
            self._downed_progression = math.clamp(1 - self._downed_timer / self._downed_start_time, 0, 1) * 100
        end
        
        if BetterLightFX then
            BetterLightFX:UpdateEvent("Bleedout", {["_progress"] = (self._downed_progression / 100) * 1})
        end
        
        managers.environment_controller:set_downed_value(self._downed_progression)
        SoundDevice:set_rtpc("downed_state_progression", self._downed_progression)
        
        if self._downed_timer <= 0 then
            if BetterLightFX then
                BetterLightFX:EndEvent("Bleedout")
            end
        end
        
        return self._downed_timer <= 0
    end
    return false
end

Hooks:PostHook( PlayerDamage, "on_downed", "PlayerDamage:on_downed_BetterLightFX", function()
    if BetterLightFX then
        BetterLightFX:StartEvent("Bleedout")
    end
end )

Hooks:PostHook( PlayerDamage, "revive", "PlayerDamage:revive_BetterLightFX", function()
    if BetterLightFX then
        BetterLightFX:EndEvent("Bleedout")
    end
end )