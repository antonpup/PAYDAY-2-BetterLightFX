function NetworkAccountSTEAM:set_lightfx()
	if managers.user:get_setting("use_lightfx") then
		print("[NetworkAccountSTEAM:init] Initializing LightFX...")
		self._has_alienware = LightFX:initialize() and LightFX:has_lamps()
		if self._has_alienware then
            if BetterLightFX then
                BetterLightFX:Initialize()
            end
            
			self._masks.alienware = true
			LightFX:set_lamps(0, 0, 0, 0)
		end
		print("[NetworkAccountSTEAM:init] Initializing LightFX done")
	else
		self._has_alienware = nil
		self._masks.alienware = nil
	end
end