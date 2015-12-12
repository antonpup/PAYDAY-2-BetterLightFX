if not _G.BetterLightFX then
    _G.BetterLightFX = {}
    
    BetterLightFX.name = "BetterLightFX"
    
    BetterLightFX.debug_enabled = true
    BetterLightFX.debug_systemprint = false
    
    BetterLightFX._initialized = false
    
    
    BetterLightFX.current_color = Color.White
    BetterLightFX._current_event = nil
    BetterLightFX._current_event_routine = nil
    BetterLightFX.is_setting_color = false
    BetterLightFX._last_light_set_at = 0
    BetterLightFX.min_wait_time = 0.01
    
    BetterLightFX.events = {}
    
    BetterLightFX.Options = {}
    
    --//
    BetterLightFX.LuaPath = ModPath .. "lua/"
	BetterLightFX.HookPath = ModPath .. "Hooks/"
    BetterLightFX.SavePath = SavePath
    
    BetterLightFX.menuOptions = "blfxoptions"
    BetterLightFX.menuEventOptions = "blfxeventoptions"
    
    BetterLightFX.HookFiles = {
        ["lib/network/matchmaking/networkaccountsteam"] = "NetworkAccountSteam.lua",
        ["lib/managers/menu/menuscenemanager"] = "MenuScene.lua",
        ["lib/managers/group_ai_states/groupaistatebase"] = "GroupAIStateBase.lua",
        ["lib/managers/hud/hudsuspicion"] = "HudSuspicion.lua",
        ["lib/units/beings/player/playerdamage"] = "PlayerDamage.lua",
        ["lib/states/missionendstate"] = "MissionEndState.lua",
        ["lib/managers/hud/hudassaultcorner"] = "HUDAssaultCorner.lua",
        ["lib/managers/hud/hudobjectives"] = "HUDObjectives.lua",
    }
    
    BetterLightFX.LUA = {
        "DefaultOptions.lua",
        "Options.lua"
    }
    
    BetterLightFX.ColorSchemeOptions = {
        {name = "RGB", option_name = "blfx_option_RGB"},
        {name = "RED", option_name = "blfx_option_RED"},
        {name = "GREEN", option_name = "blfx_option_GREEN"},
        {name = "BLUE", option_name = "blfx_option_BLUE"},
    }
    
    BetterLightFX.EventModOptions = {}
end

function BetterLightFX:Initialize()
    if self._initialized then
        return
    end
    
    --Override LightFX
    getmetatable(LightFX).set_lamps_betterfx = getmetatable(LightFX).set_lamps
    getmetatable(LightFX).set_lamps = function(red, green, blue, alpha)
        if BetterLightFX.Options.Enabled then
            BetterLightFX:PrintDebug("Original LightFX:set_lamps() was overridden.")
        else
            LightFX:set_lamps_betterfx(red, green, blue, alpha)
        end
    end
    
    self._initialized = true
    BetterLightFX:Processor()
end

function BetterLightFX:Processor()
    if not self._initialized then
        return
    end
    
    BetterLightFX:CreateCoroutine()
    
    Hooks:Add("MenuUpdate", "MenuUpdate_BetterLightFX", function( t, dt )
        if BetterLightFX.routine and coroutine.status(BetterLightFX.routine) ~= "dead" then
            coroutine.resume(BetterLightFX.routine, dt)
        elseif not BetterLightFX.routine or coroutine.status(BetterLightFX.routine) == "dead" then
            BetterLightFX:CreateCoroutine()
            coroutine.resume(BetterLightFX.routine, dt)
        end
        --BetterLightFX:PrintDebug("Status of self.routine " .. coroutine.status(BetterLightFX.routine))
    end)

    Hooks:Add("GameSetupUpdate", "GameSetupUpdate_BetterLightFX", function( t, dt )
        if BetterLightFX.routine and coroutine.status(BetterLightFX.routine) ~= "dead" then
            coroutine.resume(BetterLightFX.routine, dt)
        elseif not BetterLightFX.routine or coroutine.status(BetterLightFX.routine) == "dead" then
            BetterLightFX:CreateCoroutine()
            coroutine.resume(BetterLightFX.routine, dt)
        end
        --BetterLightFX:PrintDebug("Status of self.routine " .. coroutine.status(BetterLightFX.routine))
    end)
end

function BetterLightFX:CreateCoroutine()
    BetterLightFX.routine = coroutine.create(function(dt)
        while true do
            if self._current_event then
                if self.events[self._current_event] then
                    BetterLightFX:PrintDebug("Attempting to run " .. self._current_event)
                    
                     if self.events[self._current_event].loop then
                     
                        if not BetterLightFX._current_event_routine or coroutine.status(BetterLightFX._current_event_routine) == "dead" then
                            BetterLightFX._current_event_routine = coroutine.wrap(self.events[self._current_event]:run())
                        end
                        coroutine.resume(BetterLightFX._current_event_routine, dt)
                        
                     else
                     
                        if not self.events[self._current_event]._ran_once then
                            if not BetterLightFX._current_event_routine or coroutine.status(BetterLightFX._current_event_routine) == "dead" then
                                BetterLightFX._current_event_routine = coroutine.wrap(self.events[self._current_event]:run())
                            end
                            coroutine.resume(BetterLightFX._current_event_routine, dt)
                        end
                        
                    end
                    
                end
                BetterLightFX:PrintDebug("Ran " .. self._current_event)
            end
            coroutine.yield()
        end
    end)
end

function BetterLightFX:wait(seconds, fixed_dt)
	local t = 0
	while seconds > t do
		local dt = coroutine.yield()
		t = t + (fixed_dt and 0.033333335 or dt)
	end
end

function BetterLightFX:RegisterEvent(name, parameters, override)
    if self.events[name] and not override then
        BetterLightFX:PrintDebug("[BetterLightFX] Cannot replace existing event, " .. name)
        return
    end
    
    self.events[name] = parameters
    self.events[name].name = name
    self.events[name].enabled = true
    
    if parameters.options then
        table.insert(BetterLightFX.EventModOptions, {
            event_name = name,
            options = parameters.options
        })
    end
    
    BetterLightFX:PrintDebug("[BetterLightFX] Registered event " .. name)
end

function BetterLightFX:GetEventParamaterValue(name, param)
    if not self:DoesEventExist(name) then
        return
    end

    return self.events[name][param]
end


function BetterLightFX:DoesEventExist(name)
    if not self.events[name] then
        BetterLightFX:PrintDebug("[BetterLightFX] Event does not exist, " .. tostring(name))
        return false
    else
        return true
    end
end

function BetterLightFX:StartEvent(name)
    BetterLightFX:PrintDebug("[BetterLightFX] Starting event, " .. name)
    if not self:DoesEventExist(name) then
        return
    end
    
    if self._current_event and self._current_event == name then
        return
    end
     
    if self._current_event and self.events[self._current_event].priority < self.events[name].priority then
        self._current_event = name
        BetterLightFX._current_event_routine = nil
        self.events[name]._ran_once = false
    elseif not self._current_event then
        self._current_event = name
        BetterLightFX._current_event_routine = nil
        self.events[name]._ran_once = false
    end
    --BetterLightFX:PrintDebug("[BetterLightFX] Event started, " .. name)
end

function BetterLightFX:EndEvent(name)
    --BetterLightFX:PrintDebug("[BetterLightFX] Ending event, " .. name)
    
    if not self:DoesEventExist(name) then
        return
    end
    
    if self._current_event and self._current_event == name then
        self._current_event = nil
        if BetterLightFX.Options.DarkIdle then
            BetterLightFX:SetColor(0, 0, 0, 0, nil)
        end
    end
    
    --BetterLightFX:PrintDebug("[BetterLightFX] Event ended, " .. name)
end

function BetterLightFX:UpdateEvent(name, parameters)
     BetterLightFX:PrintDebug("[BetterLightFX] Updating event, " .. name)
    if not self:DoesEventExist(name) then
        return
    end
    
    for parameter, value in pairs(parameters) do
        self.events[name][parameter] = value
    end
    
     BetterLightFX:PrintDebug("[BetterLightFX] Event updated, " .. name)
end



function BetterLightFX:PrintDebug(message)
    if BetterLightFX.debug_enabled then
        
        if BetterLightFX.debug_systemprint and managers and managers.chat then
            managers.chat:_receive_message(ChatManager.GAME, "BetterLightFX", message, tweak_data.system_chat_color)
        else
            log(message)
        end
    end
end

function BetterLightFX:PrintDebugElapsed(elapsedtime, message)
    if elapsedtime > 0.05 then
        BetterLightFX:PrintDebug(message .. " took " .. string.format("%.2f", elapsedtime) .. " seconds.")
    end
end

function BetterLightFX:PushColor(color, event)
    local debug_clockstart = os.clock() --DEBUG
    
    if not BetterLightFX.Options.Enabled then
        return
    end
    
    if os.clock() - BetterLightFX._last_light_set_at < BetterLightFX.min_wait_time then
        return
    end
    
    --Color is already being set
    if BetterLightFX.is_setting_color then
        return
    end
    
    --Standardize the color
    if color then
        if color.red > 1 then
            color.red = color.red / 255.0
        end
        if color.green > 1 then
            color.green = color.green / 255.0
        end
        if color.blue > 1 then
            color.blue = color.blue / 255.0
        end
        if color.alpha > 1 then
            color.alpha = color.alpha / 255.0
        end
    end
    
    --Same color, no need to update.
    if BetterLightFX.current_color == color then
        return
    end
    
    if SystemInfo:platform() == Idstring("WIN32") and managers.network.account:has_alienware() and not BetterLightFX.is_setting_color and event == BetterLightFX._current_event then
        BetterLightFX.is_setting_color = true
        --RGB to Mono
        if BetterLightFX.ColorSchemeOptions[BetterLightFX.Options.ColorScheme].name  == "RED" and color.red + color.green + color.blue > 0 then
            BetterLightFX.current_color = Color(color.alpha, (color.red + color.green + color.blue) / 3.0 + 0.3, 0, 0) 
        elseif BetterLightFX.ColorSchemeOptions[BetterLightFX.Options.ColorScheme].name == "GREEN" then
            BetterLightFX.current_color = Color(color.alpha, 0, (color.red + color.green + color.blue) / 3.0 + 0.3, 0) 
        elseif BetterLightFX.ColorSchemeOptions[BetterLightFX.Options.ColorScheme].name == "BLUE" then
            BetterLightFX.current_color = Color(color.alpha, 0, 0, (color.red + color.green + color.blue) / 3.0 + 0.3)
        else
            BetterLightFX.current_color = color
        end
        
        LightFX:set_lamps_betterfx(math.floor(BetterLightFX.current_color.red * 255.0), math.floor(BetterLightFX.current_color.green * 255.0), math.floor(BetterLightFX.current_color.blue * 255.0), math.floor(BetterLightFX.current_color.alpha * 255.0))
        BetterLightFX._last_light_set_at = os.clock()
        BetterLightFX.is_setting_color = false
    end
    
    BetterLightFX:PrintDebugElapsed(os.clock() - debug_clockstart, "BetterLightFX:PushColor") --DEBUG
end

function BetterLightFX:SetColor(red, green, blue, alpha, event)
    if state then
        --BetterLightFX:PrintDebug("State setting color: ".. state)
    else
        --BetterLightFX:PrintDebug("State setting color: nil")
    end
    --BetterLightFX:PrintDebug("Set new color: r="..color.red.." g="..color.green.." b="..color.blue.." a="..color.alpha)
    BetterLightFX:PushColor(Color(alpha, red, green, blue), event)
end

function BetterLightFX:GetSubVariableFromArray(tbl, index, prefix)
    local new_tbl = {}
    
    for i, sub_table in pairs(tbl) do
        new_tbl[i] = (prefix or "") .. (sub_table[index])
    end
    
    return new_tbl
end

function BetterLightFX:CreateEventOptionButton(node, params)
    --Params: event, typ, param, value
    if params.typ == "color" then
        BetterLightFX:CreateColorOption(node, params)
    elseif params.typ == "number" then
        BetterLightFX:CreateNumberOption(node, params)
    elseif params.typ == "bool" then
        BetterLightFX:CreateBoolOption(node, params)
    end
end


function BetterLightFX:CreateColorOption(node, params)
    local colors = {"red", "green", "blue"}
    
    for i, color in pairs(colors) do
        log("create color")    
        local data = {
            type = "CoreMenuItemSlider.ItemSlider",
            min = 0,
            max = 255,
            step = 0.5,
            show_value = true
        }

        local itemparams = {
            name = params.event .. "|" .. params.param .. "|" .. color,
            text_id = params.localization .. "(" .. color .. ")",
            callback = params.callback or "blfx_EventColorCallback",
            disabled_color = Color( 0.25, 1, 1, 1 ),
            localize = false,
            eventParams = params,
            colorType = color
        }
        local item = node:create_item(data, itemparams)
        item:set_value( params.value[color] * 255 )
        node:add_item(item)
        
    end
end

function BetterLightFX:CreateNumberOption(node, params)

end

function BetterLightFX:CreateBoolOption(node, params)

end

function BetterLightFX:InitEvents()
    
    BetterLightFX:RegisterEvent("Suspicion", {priority = 1, loop = false, _color = Color.white,
        run = function(self, ...)
            self._ran_once = true
        end})
    BetterLightFX:RegisterEvent("AssaultIndicator", {priority = 2, loop = true, _color = Color.white,
        run = function(self, ...)
            local t = 3
            while true do
                local dt = coroutine.yield()
                t = t - dt
                local cv = math.abs((math.sin(t * 180 * 1)))
                local color2set = Color(1, self._color.red * cv, self._color.green * cv, self._color.blue * cv)
                
                BetterLightFX:SetColor(color2set.red, color2set.green, color2set.blue, color2set.alpha, "AssaultIndicator")
                 self._ran_once = true
            end
           
        end})
    BetterLightFX:RegisterEvent("PointOfNoReturn", {priority = 3, loop = false, _color = Color.white, options = {_color = {typ = "color", localization = "Color"}}, run = function(self, ...) self._ran_once = true end})
    BetterLightFX:RegisterEvent("Bleedout", {priority = 4, loop = true, _progress = 0,
        run = function(self, ...)
            log("Bleedout - Started")
            BetterLightFX:SetColor(1, 1, 1, self._progress, "Bleedout")
            coroutine.yield()
            self._ran_once = true
        end})
    BetterLightFX:RegisterEvent("EndLoss", {priority = 5, loop = true, 
        run = function(self, ...)
            log("EndLoss - Started")
            while true do
                log("EndLoss - Blue turn")
                BetterLightFX:SetColor(0, 0, 1, 1, "EndLoss")
                BetterLightFX:wait(0.125)
                BetterLightFX:SetColor(0, 0, 1, 0, "EndLoss")
                BetterLightFX:wait(0.125)
                BetterLightFX:SetColor(0, 0, 1, 1, "EndLoss")
                BetterLightFX:wait(0.125)
                BetterLightFX:SetColor(0, 0, 1, 0, "EndLoss")
                BetterLightFX:wait(0.25)
                
                log("EndLoss - Red turn")
                BetterLightFX:SetColor(1, 0, 0, 1, "EndLoss")
                BetterLightFX:wait(0.125)
                BetterLightFX:SetColor(1, 0, 0, 0, "EndLoss")
                BetterLightFX:wait(0.125)
                BetterLightFX:SetColor(1, 0, 0, 1, "EndLoss")
                BetterLightFX:wait(0.125)
                BetterLightFX:SetColor(1, 0, 0, 0, "EndLoss")
                BetterLightFX:wait(0.25)
                
                self._ran_once = true
            end
        end})
        
    BetterLightFX:RegisterEvent("SafeDrilled", {priority = 6, loop = false, _color = Color.white,
        run = function(self, ...)
            
            --Fade in
            for glow_count = 0, 1, 0.05 do
                BetterLightFX:SetColor(self._color.red, self._color.green, self._color.blue, glow_count, "SafeDrilled")
                coroutine.yield()
            end
            
            BetterLightFX:wait(5)
            
            --Fade out
            for glow_count = 1, 0, -0.05 do
                BetterLightFX:SetColor(self._color.red, self._color.green, self._color.blue, glow_count, "SafeDrilled")
                coroutine.yield()
            end
            
            self._ran_once = true
        end})
end
    
if not BetterLightFX.init then
	for p, d in pairs(BetterLightFX.LUA) do
		dofile(BetterLightFX.LuaPath .. d)
	end
	BetterLightFX:LoadOptions()
    BetterLightFX:InitEvents()
	BetterLightFX.init = true
end

if RequiredScript then
	local requiredScript = RequiredScript:lower()
	if BetterLightFX.HookFiles[requiredScript] then
		dofile( BetterLightFX.HookPath .. BetterLightFX.HookFiles[requiredScript] )
	end
end

if Hooks then
    Hooks:Add("LocalizationManagerPostInit", BetterLightFX.name .. "Localization", function(loc)
		LocalizationManager:add_localized_strings({
			[BetterLightFX.name .. "MainOptionsButton"] = BetterLightFX.name .. " Options",
			[BetterLightFX.name .. "MainOptionsButtonDescription"] = "Modify " .. BetterLightFX.name .. " options",
			[BetterLightFX.name .."toggle_title"] = "Enabled",
			[BetterLightFX.name .."toggle_help"] = "",
            [BetterLightFX.name .. "color_scheme_title"] = "Color Scheme",
			[BetterLightFX.name .. "color_scheme_desc"] = "",
            [BetterLightFX.name .."toggleDarkIdle_title"] = "Dark on Idle",
			[BetterLightFX.name .. "toggleDarkIdle_desc"] = "Toggles the turning off of LED's when the keyboard is Idle",
            [BetterLightFX.name .. "modEvents_title"] = "Modify Events",
			[BetterLightFX.name .. "modEvents_desc"] = "",
            [BetterLightFX.name .. "events_title"] = "Event",
			[BetterLightFX.name .. "events_desc"] = "",
			["BLFXevent_PointOfNoReturn"] = "Point Of No Return",
            
		})
        
        for _, colorScheme in pairs(BetterLightFX.ColorSchemeOptions) do
            LocalizationManager:add_localized_strings({
                [colorScheme.option_name] = colorScheme.name
            })
        end
	end)

    Hooks:Add("MenuManagerSetupCustomMenus", "Base_Setup" .. BetterLightFX.name .. "Menus", function( menu_manager, nodes )
        MenuHelper:NewMenu(BetterLightFX.menuOptions)
        MenuHelper:NewMenu(BetterLightFX.menuEventOptions)
    end)
    
    Hooks:Add("MenuManagerPopulateCustomMenus", "Base_Populate" .. BetterLightFX.name .. "Menus", function( menu_manager, nodes )
        --Add buttons
        
        MenuCallbackHandler.blfx_toggleBool = function(this, item)
            BetterLightFX.Options[item:name()] = item:value() == "on" and true or false
            BetterLightFX:Save()
        end
        
        MenuHelper:AddToggle({
            id = "Enabled",
			title = BetterLightFX.name .."toggle_title",
			desc = BetterLightFX.name .."toggle_help",
			callback = "blfx_toggleBool",
			menu_id = BetterLightFX.menuOptions,
			value = BetterLightFX.Options.Enabled,
            priority = 1000
        })
        
        MenuHelper:AddDivider({
            id = "EnabledDivider",
            size = 16,
            menu_id = BetterLightFX.menuOptions,
            priority = 999,
        })
        
        MenuCallbackHandler.blfx_colorSchemeChange = function(this, item)
            BetterLightFX.Options.ColorScheme = item:value()
            BetterLightFX:Save()
        end
        
        MenuHelper:AddMultipleChoice({
			id = BetterLightFX.name .. "colorScheme",
			title = BetterLightFX.name .. "color_scheme_title",
			desc = BetterLightFX.name .. "color_scheme_desc",
			callback = "blfx_colorSchemeChange",
			menu_id = BetterLightFX.menuOptions,
			value = BetterLightFX.Options.ColorScheme,
			items = BetterLightFX:GetSubVariableFromArray(BetterLightFX.ColorSchemeOptions, "option_name"),
			priority = 998
		})
        
        
        MenuHelper:AddToggle({
            id = "DarkIdle",
			title = BetterLightFX.name .. "toggleDarkIdle_title",
			desc = BetterLightFX.name .. "toggleDarkIdle_desc",
			callback = "blfx_toggleBool",
			menu_id = BetterLightFX.menuOptions,
			value = BetterLightFX.Options.DarkIdle,
            priority = 997
        })
    
        MenuCallbackHandler.blfx_createEventModMenuItems = function(this, item)
            BetterLightFX.currentEvent = item:name() == (BetterLightFX.name .. "events") and item:value() or 1
            
            local node = nodes[BetterLightFX.menuEventOptions]
            
            for i = 2, #node._items do
                node:delete_item(node._items[i])
            end
            
            local eventData = BetterLightFX.EventModOptions[BetterLightFX.currentEvent]
            
            if eventData and eventData.options then
                for param, opt in pairs(eventData.options) do 
                    log(param)
                    BetterLightFX:CreateEventOptionButton(node, {
                        event = eventData.event_name, 
                        typ = opt.typ, 
                        value = BetterLightFX:GetEventParamaterValue(eventData.event_name, param),
                        param = param, 
                        localization = opt.localization
                    })
                end
            end
        end
        
        if #BetterLightFX.EventModOptions > 0 then
            MenuHelper:AddButton({
                id = "ModEvents",
                title = BetterLightFX.name .. "modEvents_title",
                desc = BetterLightFX.name .. "modEvents_desc",
                callback = "blfx_createEventModMenuItems",
                next_node = BetterLightFX.menuEventOptions,
                menu_id = BetterLightFX.menuOptions,
                priority = 996
            })
            
            --Event base items
            
            MenuHelper:AddMultipleChoice({
                id = BetterLightFX.name .. "events",
                title = BetterLightFX.name .. "events_title",
                desc = BetterLightFX.name .. "events_desc",
                callback = "blfx_createEventModMenuItems",
                menu_id = BetterLightFX.menuEventOptions,
                value = 1,
                items = BetterLightFX:GetSubVariableFromArray(BetterLightFX.EventModOptions, "event_name", "BLFXevent_"),
                priority = 1000
            })
            
            MenuHelper:AddDivider({
                id = "EventDivider",
                size = 16,
                menu_id = BetterLightFX.menuEventOptions,
                priority = 999,
            })
            
        end
        
        --Event base callbacks
        
        MenuCallbackHandler.blfx_EventColorCallback = function(this, item)
            local event = item:parameters().eventParams.event
            local param = item:parameters().eventParams.param
            local color = item:parameters().colorType
            
            BetterLightFX.events[event][param][color] = item:value() / 255
        end
        
    end)
    
    Hooks:Add("MenuManagerBuildCustomMenus", "Base_Build" .. BetterLightFX.name .. "Menus", function(menu_manager, nodes)
		nodes[BetterLightFX.menuOptions] = MenuHelper:BuildMenu(BetterLightFX.menuOptions)
		MenuHelper:AddMenuItem(MenuHelper.menus.lua_mod_options_menu, BetterLightFX.menuOptions, BetterLightFX.name .. "MainOptionsButton", BetterLightFX.name .. "MainOptionsButtonDescription", 1)
        nodes[BetterLightFX.menuEventOptions] = MenuHelper:BuildMenu(BetterLightFX.menuEventOptions)
    end)

end


