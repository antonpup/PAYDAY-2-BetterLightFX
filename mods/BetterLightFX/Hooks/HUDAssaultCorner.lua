Hooks:Post( HUDAssaultCorner, "_end_assault", "HUDAssaultCorner:_end_assault_BetterLightFX", function()
    if BetterLightFX then
        BetterLightFX:EndEvent("AssaultIndicator")
    end
end )

Hooks:Post( HUDAssaultCorner, "_hide_icon_assaultbox", "HUDAssaultCorner:_hide_icon_assaultbox_BetterLightFX", function()
    if BetterLightFX then
        BetterLightFX:EndEvent("AssaultIndicator")
    end
end )

function HUDAssaultCorner:_animate_text(text_panel, bg_box, color, color_function)
	local text_list = bg_box or self._bg_box:script().text_list
	local text_index = 0
	local texts = {}
	local padding = 10
	local function create_new_text(text_panel, text_list, text_index, texts)
		if texts[text_index] and texts[text_index].text then
			text_panel:remove(texts[text_index].text)
			texts[text_index] = nil
		end
		local text_id = text_list[text_index]
		local text_string = ""
		if type(text_id) == "string" then
			text_string = managers.localization:to_upper_text(text_id)
		elseif text_id == Idstring("risk") then
			for i = 1, managers.job:current_difficulty_stars() do
				text_string = text_string .. managers.localization:get_default_macro("BTN_SKULL")
			end
		end
		local mod_color = color_function and color_function() or color or self._assault_color
		local text = text_panel:text({
			text = text_string,
			layer = 1,
			align = "center",
			vertical = "center",
			blend_mode = "add",
			color = mod_color,
			font_size = tweak_data.hud_corner.assault_size,
			font = tweak_data.hud_corner.assault_font,
			w = 10,
			h = 10
		})
		local _, _, w, h = text:text_rect()
		text:set_size(w, h)
		texts[text_index] = {
			x = text_panel:w() + w * 0.5 + padding * 2,
			text = text
		}
	end
	while true do
		local dt = coroutine.yield()
		local last_text = texts[text_index]
		if last_text and last_text.text then
			if last_text.x + last_text.text:w() * 0.5 + padding < text_panel:w() then
				text_index = text_index % #text_list + 1
				create_new_text(text_panel, text_list, text_index, texts)
			end
		else
			text_index = text_index % #text_list + 1
			create_new_text(text_panel, text_list, text_index, texts)
		end
		local speed = 90
		for i, data in pairs(texts) do
			if data.text then
				data.x = data.x - dt * speed
				data.text:set_center_x(data.x)
				data.text:set_center_y(text_panel:h() * 0.5)
				if 0 > data.x + data.text:w() * 0.5 then
					text_panel:remove(data.text)
					data.text = nil
				elseif color_function then
                    local curr_color = color_function()
					data.text:set_color(curr_color)
                    
                    if BetterLightFX and self._assault then
                        BetterLightFX:StartEvent("AssaultIndicator")
                        BetterLightFX:UpdateEvent("AssaultIndicator", {["_color"] = curr_color})
                    end
                    
				end
			end
		end
	end
end

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
                BetterLightFX:StartEvent("PointOfNoReturn")
                BetterLightFX:SetColor(r, g, b, 1, "PointOfNoReturn")
            end
            
			o:set_font_size(math.lerp(tweak_data.hud_corner.noreturn_size, tweak_data.hud_corner.noreturn_size * 1.25, n))
		end
        if BetterLightFX then
            BetterLightFX:EndEvent("PointOfNoReturn")
        end
	end
	local point_of_no_return_timer = self._noreturn_bg_box:child("point_of_no_return_timer")
	point_of_no_return_timer:animate(flash_timer)
end
