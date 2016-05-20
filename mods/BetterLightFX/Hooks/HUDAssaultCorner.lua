Hooks:PostHook( HUDAssaultCorner, "_end_assault", "HUDAssaultCorner:_end_assault_BetterLightFX", function()
    if BetterLightFX then
        BetterLightFX:EndEvent("AssaultIndicator")
    end
end )
--[[
Hooks:PostHook( HUDAssaultCorner, "_hide_icon_assaultbox", "HUDAssaultCorner:_hide_icon_assaultbox_BetterLightFX", function()
    if BetterLightFX then
        BetterLightFX:EndEvent("AssaultIndicator")
    end
end )
]]
Hooks:PostHook( HUDAssaultCorner, "_start_assault", "HUDAssaultCorner:_start_assault_BetterLightFX", function(self)
    if BetterLightFX then
        BetterLightFX:StartEvent("AssaultIndicator")
        BetterLightFX:SetColor(self._current_assault_color.red, self._current_assault_color.green, self._current_assault_color.blue, self._current_assault_color.alpha, "AssaultIndicator" )
        BetterLightFX:UpdateEvent("AssaultIndicator", {["_color"] = self._current_assault_color})
    end
end )

Hooks:PostHook( HUDAssaultCorner, "sync_set_assault_mode", "HUDAssaultCorner:sync_set_assault_mode_BetterLightFX", function(self)
    if BetterLightFX then
        BetterLightFX:UpdateEvent("AssaultIndicator", {["_color"] = self._current_assault_color})
    end
end )

Hooks:PostHook( HUDAssaultCorner, "show_point_of_no_return_timer", "HUDAssaultCorner:show_point_of_no_return_timer_BetterLightFX", function()
    if BetterLightFX then
        BetterLightFX:StartEvent("PointOfNoReturn")
    end
end )

Hooks:PostHook( HUDAssaultCorner, "hide_point_of_no_return_timer", "HUDAssaultCorner:hide_point_of_no_return_timer_BetterLightFX", function()
    if BetterLightFX then
        BetterLightFX:EndEvent("PointOfNoReturn")
    end
end )


function HUDAssaultCorner:flash_point_of_no_return_timer(beep)
    local function flash_timer(o)
        local t = 0
        while t < 0.5 do
            t = t + coroutine.yield()
            local n = 1 - math.sin(t * 180)
            local r = math.lerp(1 or self._point_of_no_return_color.r, 1, n)
            local g = math.lerp(0 or self._point_of_no_return_color.g, 0.8, n)
            local b = math.lerp(0 or self._point_of_no_return_color.b, 0.2, n)
            o:set_color(Color(r, g, b))
            if BetterLightFX then
                BetterLightFX:SetColor(r, g, b, 1, "PointOfNoReturn")
            end
            
            o:set_font_size(math.lerp(tweak_data.hud_corner.noreturn_size, tweak_data.hud_corner.noreturn_size * 1.25, n))
        end
    end
    local point_of_no_return_timer = self._noreturn_bg_box:child("point_of_no_return_timer")
    point_of_no_return_timer:animate(flash_timer)
end
