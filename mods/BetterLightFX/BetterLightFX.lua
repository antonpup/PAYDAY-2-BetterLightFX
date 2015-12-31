if not _G.BetterLightFX then
    _G.BetterLightFX = {}
    
    BetterLightFX.name = "BetterLightFX"
    
    --Debugging and logging
    BetterLightFX.LOG_LEVEL_NONE = 0
    BetterLightFX.LOG_LEVEL_INFO = 1
    BetterLightFX.LOG_LEVEL_WARNING = 2
    BetterLightFX.LOG_LEVEL_DEBUG = 3
    BetterLightFX.debug_enabled = true
    BetterLightFX.debug_systemprint = true
    BetterLightFX.debug_level = BetterLightFX.LOG_LEVEL_WARNING
    
    --Core
    BetterLightFX.routine = nil -- Main routine
    BetterLightFX.current_color = Color.White
    BetterLightFX._current_event = nil
    BetterLightFX.blendroutine = nil -- Blend routine
    BetterLightFX.current_blend_color = Color.White
    BetterLightFX._current_blend_event = nil
    BetterLightFX.is_setting_color = false
    BetterLightFX._last_light_set_at = 0
    BetterLightFX.idle_events = {}
    BetterLightFX.events = {}
    BetterLightFX.running_events = {}
    BetterLightFX.Options = {}
    
    --Init stuff
    BetterLightFX._initialized = false
    BetterLightFX.LuaPath = ModPath .. "lua/"
	BetterLightFX.HookPath = ModPath .. "Hooks/"
    BetterLightFX.SavePath = SavePath
    BetterLightFX.HookFiles = {
        ["lib/network/matchmaking/networkaccountsteam"] = "NetworkAccountSteam.lua",
        ["lib/managers/menu/menuscenemanager"] = "MenuScene.lua",
        ["lib/managers/group_ai_states/groupaistatebase"] = "GroupAIStateBase.lua",
        ["lib/managers/hud/hudsuspicion"] = "HudSuspicion.lua",
        ["lib/units/beings/player/playerdamage"] = "PlayerDamage.lua",
        ["lib/states/missionendstate"] = "MissionEndState.lua",
        ["lib/managers/hud/hudassaultcorner"] = "HUDAssaultCorner.lua",
        ["lib/managers/hudmanagerpd2"] = "HUDManagerPD2.lua",
        ["core/lib/managers/coreenvironmentcontrollermanager"] = "CoreEnvironmentControllerManager.lua",
        ["lib/managers/hud/hudstageendscreen"] = "HUDStageEndScreen.lua",
        ["lib/managers/hud/hudhitdirection"] = "HUDHitDirection.lua",
        ["lib/units/beings/player/states/playertased"] = "PlayerTased.lua"
    }
    BetterLightFX.LUA = {
        "DefaultOptions.lua",
        "Options.lua"
    }
    
    --Menus
    BetterLightFX.menuOptions = "blfxoptions"
    BetterLightFX.menuEventOptions = "blfxeventoptions"
    BetterLightFX.menuIdleEventOptions = "blfxidleeventoptions"
    BetterLightFX.ColorSchemeOptions = {
        {name = "RGB", option_name = "blfx_option_RGB"},
        {name = "RED", option_name = "blfx_option_RED"},
        {name = "GREEN", option_name = "blfx_option_GREEN"},
        {name = "BLUE", option_name = "blfx_option_BLUE"},
        {name = "WHITE", option_name = "blfx_option_WHITE"},
    }
    BetterLightFX.EventModOptions = {}
    BetterLightFX.IdleEventModOptions = {}
end

function BetterLightFX:DebugLevelString(level)
    if level == BetterLightFX.LOG_LEVEL_INFO then
        return "INFO"
    elseif level == BetterLightFX.LOG_LEVEL_WARNING then
        return "WARNING"
    elseif level == BetterLightFX.LOG_LEVEL_DEBUG then
        return "DEBUG"
    else
        return nil
    end
end


function BetterLightFX:PrintDebug(message, level)
    if BetterLightFX.debug_enabled then
        if level <= BetterLightFX.debug_level then
            
            local levelstr = BetterLightFX:DebugLevelString(level)
            if levelstr then
                levelstr = "[" .. levelstr .. "] "
            else
                levelstr = ""
            end
            
            if BetterLightFX.debug_systemprint and managers and managers.chat then
                managers.chat:_receive_message(ChatManager.GAME, "BetterLightFX",  levelstr .. message, tweak_data.system_chat_color)
            else
                log(levelstr .. message)
            end
        end
    end
end

function BetterLightFX:PrintDebugElapsed(elapsedtime, message, level)
    if elapsedtime > 0.05 then
        BetterLightFX:PrintDebug(message .. " took " .. string.format("%.2f", elapsedtime) .. " seconds.", level)
    end
end

function BetterLightFX:Initialize()
    if self._initialized then
        return
    end
    
    --Override LightFX
    getmetatable(LightFX).set_lamps_betterfx = getmetatable(LightFX).set_lamps
    getmetatable(LightFX).set_lamps = function(red, green, blue, alpha)
        if BetterLightFX.Options.Enabled then
            BetterLightFX:PrintDebug("Original LightFX:set_lamps() was overridden.", BetterLightFX.LOG_LEVEL_INFO)
        else
            LightFX:set_lamps_betterfx(red, green, blue, alpha)
        end
    end
    
    self._initialized = true
    BetterLightFX:Processor()
end

function BetterLightFX:InitEvents()
    
    --Idle Events
    BetterLightFX:RegisterIdleEvent("ColorsOut", {
        options = {
        },
        run = function(self, ...)
            BetterLightFX:SetColor(0, 0, 0, 0, nil) --nil because Idle events can only run when there is no active event
            self._ran_once = true
        end})
    
    BetterLightFX:RegisterIdleEvent("SingleColor", {_color = Color(1, 1, 1, 1), _brightness = 1, _pulsing = false, _pulserate = 1, _t = 3,
        options = {
            {parameter = "_brightness", typ = "number", localization = "Brightness", minVal = 0, maxVal = 1},
            {parameter = "_color", typ = "color", localization = "Color"},
            {parameter = "_pulsing", typ = "bool", localization = "Pulse"},
            {parameter = "_pulserate", typ = "number", localization = "Pulse Rate", minVal = 0, maxVal = 3},
        },
        run = function(self, ...)
            local dt = coroutine.yield()
            self._t = self._t - dt
            
            if self._pulsing then
                self._color.alpha = math.abs((math.sin(self._t * 90 * self._pulserate * 1)))
            else
                self._color.alpha = 1
            end
            
            BetterLightFX:SetColor(self._color.red, self._color.green, self._color.blue, self._color.alpha * self._brightness, nil)
            self._ran_once = true
        end})
    
    BetterLightFX:RegisterIdleEvent("TwoColorFade", {_color1 = Color(1, 1, 1, 1), _color2 = Color(1, 1, 1, 1), _brightness = 1, _speed = 1, _current_fade = 0,
        options = {
            {parameter = "_brightness", typ = "number", localization = "Brightness", minVal = 0, maxVal = 1},
            {parameter = "_speed", typ = "number", localization = "Fade Speed", minVal = 0, maxVal = 2},
            {parameter = "_color1", typ = "color", localization = "First Color"},
            {parameter = "_color2", typ = "color", localization = "Second Color"},
        },
        run = function(self, ...)
            
            local sine = math.pow( math.sin( self._current_fade * ( 180 * self._speed ) ), 2 )
            local cosine = math.pow( math.cos( self._current_fade * ( 180 * self._speed ) ), 2 )
            
            BetterLightFX:SetColor(math.min((self._color1.red * sine) + (self._color2.red * cosine), 1), math.min((self._color1.green * sine) + (self._color2.green * cosine), 1), math.min((self._color1.blue * sine) + (self._color2.blue * cosine), 1), self._brightness, nil)
            
            self._current_fade = self._current_fade + coroutine.yield()
            self._ran_once = true
        end})
    
    BetterLightFX:RegisterIdleEvent("Rainbow", {_step = 0 , _speed = 1, _brightness = 1,
        options = {
             {parameter = "_brightness", typ = "number", localization = "Brightness", minVal = 0, maxVal = 1},
             {parameter = "_speed", typ = "number", localization = "Rainbow Speed", minVal = 0.1, maxVal = 2},
        },
        run = function(self, ...)
            
            local current_step = self._step % 6
            local rainbow_step = 0
            
            if current_step == 0 then
                -- Red, +Green
                while rainbow_step < 1 do
                    BetterLightFX:SetColor(1, rainbow_step, 0, self._brightness, nil)
                    coroutine.yield()
                    rainbow_step = rainbow_step + (0.05 * self._speed)
                end
            elseif current_step == 1 then
                -- -Red, Green
                while rainbow_step < 1 do
                    BetterLightFX:SetColor(1 - rainbow_step, 1, 0, self._brightness, nil)
                    coroutine.yield()
                    rainbow_step = rainbow_step + (0.05 * self._speed)
                end
            elseif current_step == 2 then
                -- Green, +Blue
                while rainbow_step < 1 do
                    BetterLightFX:SetColor(0, 1, rainbow_step, self._brightness, nil)
                    coroutine.yield()
                    rainbow_step = rainbow_step + (0.05 * self._speed)
                end
            elseif current_step == 3 then
                -- -Green, Blue
                while rainbow_step < 1 do
                    BetterLightFX:SetColor(0, 1 - rainbow_step, 1, self._brightness, nil)
                    coroutine.yield()
                    rainbow_step = rainbow_step + (0.05 * self._speed)
                end
            elseif current_step == 4 then
                -- Blue, +Red
                while rainbow_step < 1 do
                    BetterLightFX:SetColor(rainbow_step, 0, 1, self._brightness, nil)
                    coroutine.yield()
                    rainbow_step = rainbow_step + (0.05 * self._speed)
                end
            elseif current_step == 5 then
                -- -Blue, Red
                while rainbow_step < 1 do
                    BetterLightFX:SetColor(1, 0, 1 - rainbow_step, self._brightness, nil)
                    coroutine.yield()
                    rainbow_step = rainbow_step + (0.05 * self._speed)
                end
            end
            
            self._step = self._step + 1
            
            self._ran_once = true
        end})
    
    --Regular Events
    BetterLightFX:RegisterEvent("Suspicion", {priority = 1, enabled = true, loop = true, _color = Color(1, 1, 1, 1), 
        options = {
            {parameter = "enabled", typ = "bool", localization = "Enabled"},
        },
        run = function(self, ...)
            self._ran_once = true
        end})
        
    BetterLightFX:RegisterEvent("AssaultIndicator", {priority = 20, enabled = true, loop = true, _color = Color(1, 1, 1, 1), _t = 3, 
        options = {
            {parameter = "enabled", typ = "bool", localization = "Enabled"},
        },
        run = function(self, ...)
            local dt = coroutine.yield()
            self._t = self._t - dt
            local cv = math.abs((math.sin(self._t * 180 * 1)))
            local color2set = Color(1, self._color.red * cv, self._color.green * cv, self._color.blue * cv)
            
            BetterLightFX:SetColor(color2set.red, color2set.green, color2set.blue, color2set.alpha, self.name)
            self._ran_once = true
        end})
        
    BetterLightFX:RegisterEvent("PointOfNoReturn", {priority = 30, enabled = true, loop = true, _color = Color(1, 1, 1, 1), 
        options = {
            {parameter = "enabled", typ = "bool", localization = "Enabled"},
        }, 
        run = function(self, ...) self._ran_once = true end})
        
    BetterLightFX:RegisterEvent("TakenDamage", {priority = 40, enabled = true, blend = true, loop = false, _use_custom_color = false, _custom_color = Color(1, 1, 0.313, 0), _color = Color(1, 1, 0.313, 0), _t = 0.6,
        options = {
            {parameter = "enabled", typ = "bool", localization = "Enabled"},
            {parameter = "_use_custom_color", typ = "bool", localization = "Use Custom Color"},
            {parameter = "_custom_color", typ = "color", localization = "Color"},
        },
        run = function(self, ...)
            local used_color = self._color
            
            if self._use_custom_color then
                used_color = self._custom_color
            end
            
            local t = self._t
            while t > 0 do
                BetterLightFX:SetColor(used_color.red, used_color.green, used_color.blue, (t / self._t), self.name)
                local dt = coroutine.yield()
                t = t - dt
            end
            
            self._ran_once = true
        end})
        
    BetterLightFX:RegisterEvent("TakenSevereDamage", {priority = 50, enabled = true, blend = true, loop = true, _color = Color(1, 1, 0, 0), _hurtamount = 0, 
        options = {
            {parameter = "enabled", typ = "bool", localization = "Enabled"},
            {parameter = "_color", typ = "color", localization = "Color"},
        },
        run = function(self, ...)
            BetterLightFX:SetColor(self._color.red, self._color.green, self._color.blue, self._hurtamount, self.name)
            coroutine.yield()
            self._ran_once = true
        end})
        
    BetterLightFX:RegisterEvent("Bleedout", {priority = 60, enabled = true, loop = true, _color = Color(1, 1, 1, 1),  _progress = 0, 
        options = {
            {parameter = "enabled", typ = "bool", localization = "Enabled"},
            {parameter = "_color", typ = "color", localization = "Color"},
        },
        run = function(self, ...)
            BetterLightFX:SetColor(self._color.red, self._color.green, self._color.blue, self._progress, self.name)
            
            if self._progress >= 1 then
                BetterLightFX:EndEvent(self.name)
            end
            
            coroutine.yield()
            self._ran_once = true
        end})
        
    BetterLightFX:RegisterEvent("SwanSong", {priority = 70, enabled = true, loop = true, _color = Color(1, 0, 0.80, 1),  _t = 3, _frequency = 2,
        options = {
            {parameter = "enabled", typ = "bool", localization = "Enabled"},
            {parameter = "_color", typ = "color", localization = "Color"},
            {parameter = "_frequency", typ = "number", localization = "Blinking Frequency", minVal = 0, maxVal = 30},
        },
        run = function(self, ...)
            local dt = coroutine.yield()
            self._t = self._t - dt
            local cv = math.abs((math.sin(self._t * 90 * self._frequency * 1)))
            local color2set = Color(1, self._color.red * cv, self._color.green * cv, self._color.blue * cv)
            
            BetterLightFX:SetColor(color2set.red, color2set.green, color2set.blue, color2set.alpha, self.name)
            self._ran_once = true
        end})
        
    BetterLightFX:RegisterEvent("Electrocuted", {priority = 80, enabled = true, blend = true, loop = true, _color = Color(1, 0, 0.80, 1), use_custom_color = false, _random_color = Color(1, 1, 1, 1), _alpha_fade_mod = 0,
        options = {
            {parameter = "enabled", typ = "bool", localization = "Enabled"},
            {parameter = "use_custom_color", typ = "bool", localization = "Use Custom Color"},
            {parameter = "_color", typ = "color", localization = "Color"},
        },
        run = function(self, ...)
            
            if self.use_custom_color then
                BetterLightFX:SetColor(self._color.red, self._color.green, self._color.blue, self._color.alpha - self._alpha_fade_mod, self.name)
            else
                BetterLightFX:SetColor(self._random_color.red, self._random_color.green, self._random_color.blue, self._random_color.alpha - self._alpha_fade_mod, self.name)
            end
            self._alpha_fade_mod = math.min(self._alpha_fade_mod + 0.01, 1)
            coroutine.yield()
            self._ran_once = true
        end})
        
    BetterLightFX:RegisterEvent("Flashbang", {priority = 90, enabled = true, blend = true, loop = true, _color = Color(1, 1, 1, 1), _flashamount = 0, 
        options = {
            {parameter = "enabled", typ = "bool", localization = "Enabled"},
            {parameter = "_color", typ = "color", localization = "Color"},
        },
        run = function(self, ...)
            BetterLightFX:SetColor(self._color.red, self._color.green, self._color.blue, self._flashamount, self.name)
            coroutine.yield()
            self._ran_once = true
        end})
        
    BetterLightFX:RegisterEvent("EndLoss", {priority = 100, enabled = true, loop = true, 
        options = {
            {parameter = "enabled", typ = "bool", localization = "Enabled"},
        }, 
        run = function(self, ...)
            while true do
                BetterLightFX:SetColor(0, 0, 1, 1, self.name)
                BetterLightFX:wait(0.125)
                BetterLightFX:SetColor(0, 0, 1, 0, self.name)
                BetterLightFX:wait(0.125)
                BetterLightFX:SetColor(0, 0, 1, 1, self.name)
                BetterLightFX:wait(0.125)
                BetterLightFX:SetColor(0, 0, 1, 0, self.name)
                BetterLightFX:wait(0.25)
                
                BetterLightFX:SetColor(1, 0, 0, 1, self.name)
                BetterLightFX:wait(0.125)
                BetterLightFX:SetColor(1, 0, 0, 0, self.name)
                BetterLightFX:wait(0.125)
                BetterLightFX:SetColor(1, 0, 0, 1, self.name)
                BetterLightFX:wait(0.125)
                BetterLightFX:SetColor(1, 0, 0, 0, self.name)
                BetterLightFX:wait(0.25)
                
                self._ran_once = true
            end
        end})
        
    BetterLightFX:RegisterEvent("LevelUp", {priority = 110, enabled = true, blend = true, loop = false, _color = Color(1, 0, 0, 1),
        options = {
            {parameter = "enabled", typ = "bool", localization = "Enabled"},
            {parameter = "_color", typ = "color", localization = "Color"},
        }, 
        run = function(self, ...)
            
            --Fade in
            for glow_count = 0, 1, 0.05 do
                BetterLightFX:SetColor(self._color.red, self._color.green, self._color.blue, glow_count, self.name)
                coroutine.yield()
            end
            
            BetterLightFX:wait(1)
            
            --Fade out
            for glow_count = 1, 0, -0.05 do
                BetterLightFX:SetColor(self._color.red, self._color.green, self._color.blue, glow_count, self.name)
                coroutine.yield()
            end
            
            BetterLightFX:EndEvent(self.name)
            self._ran_once = true
        end})
        
    BetterLightFX:RegisterEvent("SafeDrilled", {priority = 120, enabled = true, blend = true, loop = false, _color = Color(1, 1, 1, 1), _duration = 5,
        options = {
            {parameter = "enabled", typ = "bool", localization = "Enabled"},
            {parameter = "_duration", typ = "number", localization = "Light Duration (Seconds)", maxVal = 30},
        }, 
        run = function(self, ...)
            
            --Fade in
            for glow_count = 0, 1, 0.05 do
                BetterLightFX:SetColor(self._color.red, self._color.green, self._color.blue, glow_count, self.name)
                coroutine.yield()
            end
            
            BetterLightFX:wait(self._duration)
            
            --Fade out
            for glow_count = 1, 0, -0.05 do
                BetterLightFX:SetColor(self._color.red, self._color.green, self._color.blue, glow_count, self.name)
                coroutine.yield()
            end
            
            self._ran_once = true
        end})
end

function BetterLightFX:Processor()
    if not self._initialized then
        return
    end
    
    BetterLightFX:CreateCoroutine()
    
    Hooks:Add("MenuUpdate", "MenuUpdate_BetterLightFX", function( t, dt )
        BetterLightFX:Tick( t, dt )
    end)

    Hooks:Add("GameSetupUpdate", "GameSetupUpdate_BetterLightFX", function( t, dt )
        BetterLightFX:Tick( t, dt )
    end)
end

function BetterLightFX:Tick( t, dt )
    local debug_clockstart = os.clock() --DEBUG
    
    --Blending
    if self._current_blend_event and self.events[self._current_blend_event] then
        
        if self.blendroutine and coroutine.status(self.blendroutine) == "suspended" then
            local success, errorMessage = coroutine.resume(self.blendroutine, dt)
            
            if not success then -- check if there is an error
                log("There was an error in blend routine: " .. errorMessage)
            end
        elseif not self.blendroutine or coroutine.status(self.blendroutine) == "dead" then
            self.blendroutine = coroutine.create(function(dt)
                while true do
                    if self._current_blend_event then
                        if self.events[self._current_blend_event] then
                            
                            if self.events[self._current_blend_event].loop then
                                self.events[self._current_blend_event]:run()
                            else
                                if self.events[self._current_blend_event]._ran_once then
                                    BetterLightFX:EndEvent(self._current_blend_event)
                                else
                                    self.events[self._current_blend_event]:run()
                                end
                            end
                        end
                        --BetterLightFX:PrintDebug("Ran " .. self._current_event, BetterLightFX.LOG_LEVEL_DEBUG)
                        coroutine.yield()
                    end
                end
            end)
            
            local success, errorMessage = coroutine.resume(self.blendroutine, dt)
            
            if not success then -- check if there is an error
                log("There was an error in blend routine: " .. errorMessage)
            end
        end
        
    end
    
    
    --Events
    if BetterLightFX.routine and coroutine.status(BetterLightFX.routine) ~= "dead" then
        if coroutine.status(BetterLightFX.routine) == "suspended" then
            local success, errorMessage = coroutine.resume(BetterLightFX.routine, dt)
            
            if not success then -- check if there is an error
                log("There was an error in main: " .. errorMessage)
            end
        end
    elseif not BetterLightFX.routine or coroutine.status(BetterLightFX.routine) == "dead" then
        BetterLightFX:CreateCoroutine()
        
        if coroutine.status(BetterLightFX.routine) == "suspended" then
            local success, errorMessage = coroutine.resume(BetterLightFX.routine, dt)
            
            if not success then -- check if there is an error
                log("There was an error in main: " .. errorMessage)
            end
        end
    end
    --BetterLightFX:PrintDebug("Status of self.routine " .. coroutine.status(BetterLightFX.routine), BetterLightFX.LOG_LEVEL_DEBUG)
    
    BetterLightFX:PrintDebugElapsed(os.clock() - debug_clockstart, "BetterLightFX:Tick", BetterLightFX.LOG_LEVEL_WARNING) --DEBUG
end


function BetterLightFX:CreateCoroutine()
    local debug_clockstart = os.clock() --DEBUG
    BetterLightFX.routine = coroutine.create(function(dt)
        while true do
            if self._current_event then
                if self.events[self._current_event] then
                    --BetterLightFX:PrintDebug("Attempting to run " .. self._current_event, BetterLightFX.LOG_LEVEL_DEBUG)
                    
                    if self.events[self._current_event].loop then
                        self.events[self._current_event]:run()
                    else
                        if self.events[self._current_event]._ran_once then
                            BetterLightFX:EndEvent(self._current_event)
                        else
                            self.events[self._current_event]:run()
                        end
                    end
                    
                end
                --BetterLightFX:PrintDebug("Ran " .. self._current_event, BetterLightFX.LOG_LEVEL_DEBUG)
            else
                if self.idle_events[BetterLightFX.IdleEventModOptions[BetterLightFX.Options.IdleEvent].event_name] then
                    self.idle_events[BetterLightFX.IdleEventModOptions[BetterLightFX.Options.IdleEvent].event_name]:run()
                end
            end
            coroutine.yield()
        end
    end)
    
    BetterLightFX:PrintDebugElapsed(os.clock() - debug_clockstart, "BetterLightFX:CreateCoroutine", BetterLightFX.LOG_LEVEL_WARNING) --DEBUG
end

function BetterLightFX:wait(seconds, fixed_dt)
	local t = 0
	while seconds > t do
		local dt = coroutine.yield()
		t = t + (fixed_dt and 0.033333335 or dt)
	end
end

function BetterLightFX:RegisterEvent(name, parameters, override)
    local debug_clockstart = os.clock() --DEBUG
    if self.events[name] and not override then
        BetterLightFX:PrintDebug("[BetterLightFX] Cannot replace existing event, " .. name, BetterLightFX.LOG_LEVEL_INFO)
        return
    end
    
    if self.events[name] and override then
        parameters.priority = self.events[name].priority
    end
    
    if not parameters.run then
        parameters.run = function(self, ...)
            self._ran_once = true
        end
    end
    
    self.events[name] = parameters
    self.events[name].name = name
    self.events[name].display_name = "blfx_" .. name
    self.events[name].enabled = true
    
    for i, eventOpt in pairs(BetterLightFX.EventModOptions) do
        if eventOpt.event_name == name then
            table.remove(BetterLightFX.EventModOptions, i)
        end
    end
    
    if parameters.options then
        table.insert(BetterLightFX.EventModOptions, {
            event_name = name,
            options = parameters.options
        })
    end
    
    if self.Options[name] then
        for param, data in pairs(self.Options[name]) do
            if type(data) == "table" then
                self.events[name][param] = self.events[name][param] or Color.white
                for color, value in pairs(data) do
                    self.events[name][param][color] = value
                end
            else
                self.events[name][param] = data
            end
        end
    end
    
    BetterLightFX:PrintDebug("[BetterLightFX] Registered event " .. name, BetterLightFX.LOG_LEVEL_INFO)
    BetterLightFX:PrintDebugElapsed(os.clock() - debug_clockstart, "BetterLightFX:RegisterEvent", BetterLightFX.LOG_LEVEL_WARNING) --DEBUG
end

function BetterLightFX:RegisterIdleEvent(name, parameters)
    local debug_clockstart = os.clock() --DEBUG
    if self.idle_events[name] then
        BetterLightFX:PrintDebug("[BetterLightFX] Cannot replace existing idle event, " .. name, BetterLightFX.LOG_LEVEL_INFO)
        return
    end
    
    self.idle_events[name] = parameters
    self.idle_events[name].name = name
    self.idle_events[name].display_name = "blfx_" .. name
    
    for i, eventOpt in pairs(BetterLightFX.IdleEventModOptions) do
        if eventOpt.event_name == name then
            table.remove(BetterLightFX.IdleEventModOptions, i)
        end
    end
    
    if parameters.options then
        table.insert(BetterLightFX.IdleEventModOptions, {
            event_name = name,
            options = parameters.options
        })
    else
        table.insert(BetterLightFX.IdleEventModOptions, {
            event_name = name,
            options = {}
        })
    end
    
    if self.Options[name] then
        for param, data in pairs(self.Options[name]) do
            if type(data) == "table" then
                self.idle_events[name][param] = self.idle_events[name][param] or Color.white
                for color, value in pairs(data) do
                    self.idle_events[name][param][color] = value
                end
            else
                self.idle_events[name][param] = data
            end
        end
    end
    
    BetterLightFX:PrintDebug("[BetterLightFX] Registered idle event " .. name, BetterLightFX.LOG_LEVEL_INFO)
    BetterLightFX:PrintDebugElapsed(os.clock() - debug_clockstart, "BetterLightFX:RegisterIdleEvent", BetterLightFX.LOG_LEVEL_WARNING) --DEBUG
end

function BetterLightFX:GetNextRunningEvent()
    local returnevent = nil
    
    for key, event in ipairs(self.running_events) do
        if not returnevent then
            returnevent = event
        else
            
            if BetterLightFX.events[returnevent].priority < BetterLightFX.events[event].priority then
                returnevent = event
            end
            
        end
    end
    
    return returnevent
end

function BetterLightFX:RemoveRunningEvent(event)
    
    for key, runningevent in ipairs(self.running_events) do
        if runningevent == event then
            table.remove(self.running_events, key)
            do return end
        end
    end
    
end

function BetterLightFX:GetEventParamaterValue(name, param)
    if not self:DoesEventExist(name) then
        return
    end
    
    return self.events[name][param]
end

function BetterLightFX:GetIdleEventParamaterValue(name, param)
    if not self:DoesIdleEventExist(name) then
        return
    end
    
    return self.idle_events[name][param]
end

function BetterLightFX:DoesEventExist(name)
    if not self.events[name] then
        BetterLightFX:PrintDebug("[BetterLightFX] Event does not exist, " .. tostring(name), BetterLightFX.LOG_LEVEL_WARNING)
        return false
    else
        return true
    end
end

function BetterLightFX:DoesIdleEventExist(name)
    if not self.idle_events[name] then
        BetterLightFX:PrintDebug("[BetterLightFX] Idle event does not exist, " .. tostring(name), BetterLightFX.LOG_LEVEL_WARNING)
        return false
    else
        return true
    end
end

function BetterLightFX:StartEvent(name)
    local debug_clockstart = os.clock() --DEBUG
    --BetterLightFX:PrintDebug("[BetterLightFX] Starting event, " .. name, BetterLightFX.LOG_LEVEL_DEBUG)
    if not self:DoesEventExist(name) then
        return
    end
    
    if not self.events[name].enabled then
        return
    end
    
    if self.events[name].blend then
        
        if self._current_blend_event and self.events[self._current_blend_event].priority < self.events[name].priority then
            self._current_blend_event = name
            BetterLightFX.blendroutine = nil
            self.events[name]._ran_once = false
            --table.insert(self.running_events, name)
            BetterLightFX:PrintDebug("[BetterLightFX] Blend event started, " .. name, BetterLightFX.LOG_LEVEL_DEBUG)
        elseif not self._current_blend_event then
            self._current_blend_event = name
            BetterLightFX.blendroutine = nil
            self.events[name]._ran_once = false
            --table.insert(self.running_events, name)
            BetterLightFX:PrintDebug("[BetterLightFX] Blend event started, " .. name, BetterLightFX.LOG_LEVEL_DEBUG)
        end
        
        return
    end
    
    if self._current_event and self._current_event == name then
        return
    end
     
    if self._current_event and self.events[self._current_event].priority < self.events[name].priority then
        self._current_event = name
        self.events[name]._ran_once = false
        table.insert(self.running_events, name)
        BetterLightFX:PrintDebug("[BetterLightFX] Event started, " .. name, BetterLightFX.LOG_LEVEL_DEBUG)
    elseif self._current_event and self.events[self._current_event].priority >= self.events[name].priority then
        self.events[name]._ran_once = false
        table.insert(self.running_events, name)
        BetterLightFX:PrintDebug("[BetterLightFX] Event appended to running list, " .. name, BetterLightFX.LOG_LEVEL_DEBUG)
    elseif not self._current_event then
        self._current_event = name
        self.events[name]._ran_once = false
        table.insert(self.running_events, name)
        BetterLightFX:PrintDebug("[BetterLightFX] Event started, " .. name, BetterLightFX.LOG_LEVEL_DEBUG)
    end
    
    BetterLightFX:PrintDebugElapsed(os.clock() - debug_clockstart, "BetterLightFX:StartEvent", BetterLightFX.LOG_LEVEL_WARNING) --DEBUG
end

function BetterLightFX:EndEvent(name)
    local debug_clockstart = os.clock() --DEBUG
    --BetterLightFX:PrintDebug("[BetterLightFX] Ending event, " .. name, BetterLightFX.LOG_LEVEL_DEBUG)
    if not self:DoesEventExist(name) then
        return
    end
    
    if self._current_blend_event and self._current_blend_event == name then
        self._current_blend_event = nil
        BetterLightFX.blendroutine = nil
        BetterLightFX:PrintDebug("[BetterLightFX] Blend event ended, " .. name, BetterLightFX.LOG_LEVEL_DEBUG)
        
    elseif self._current_event and self._current_event == name then
        
        BetterLightFX:RemoveRunningEvent(name)
        
        self._current_event = BetterLightFX:GetNextRunningEvent()
        BetterLightFX:PrintDebug("[BetterLightFX] Event ended, " .. name, BetterLightFX.LOG_LEVEL_DEBUG)
        
        if self._current_event then
            BetterLightFX:PrintDebug("[BetterLightFX] Restored Event, " .. self._current_event, BetterLightFX.LOG_LEVEL_DEBUG)
        end
    elseif self._current_blend_event and self._current_blend_event == name then
        
    end
    
    BetterLightFX:PrintDebugElapsed(os.clock() - debug_clockstart, "BetterLightFX:EndEvent", BetterLightFX.LOG_LEVEL_WARNING) --DEBUG
end

function BetterLightFX:UpdateEvent(name, parameters)
    local debug_clockstart = os.clock() --DEBUG
    --BetterLightFX:PrintDebug("[BetterLightFX] Updating event, " .. name, BetterLightFX.LOG_LEVEL_DEBUG)
    if not self:DoesEventExist(name) then
        return
    end
    
    for parameter, value in pairs(parameters) do
        self.events[name][parameter] = value
    end
    
     --BetterLightFX:PrintDebug("[BetterLightFX] Event updated, " .. name, BetterLightFX.LOG_LEVEL_DEBUG)
     BetterLightFX:PrintDebugElapsed(os.clock() - debug_clockstart, "BetterLightFX:UpdateEvent", BetterLightFX.LOG_LEVEL_WARNING) --DEBUG
end

function BetterLightFX:PushColor(color, event)
    local debug_clockstart = os.clock() --DEBUG
    
    if not BetterLightFX.Options.Enabled then
        return
    end
    
    if self._current_blend_event and self._current_blend_event == event then
        self.current_blend_color = color
        return
    end
    
    if os.clock() - BetterLightFX._last_light_set_at < BetterLightFX.Options.LEDRefreshRate then
        return
    end
    
    --Color is already being set
    if BetterLightFX.is_setting_color then
        return
    end
    
    --Blend the colors
    if self._current_blend_event then
        local tempColor = Color(0, 0, 0, 0)
        tempColor.alpha = 1 - (1 - self.current_blend_color.alpha) * (1 - color.alpha)
        if tempColor.alpha > 0 then
            tempColor.red = self.current_blend_color.red * self.current_blend_color.alpha / tempColor.alpha + color.red * color.alpha * (1 - self.current_blend_color.alpha) / tempColor.alpha;
            tempColor.green = self.current_blend_color.green * self.current_blend_color.alpha / tempColor.alpha + color.green * color.alpha * (1 - self.current_blend_color.alpha) / tempColor.alpha;
            tempColor.blue = self.current_blend_color.blue * self.current_blend_color.alpha / tempColor.alpha + color.blue * color.alpha * (1 - self.current_blend_color.alpha) / tempColor.alpha;
        end
        color = tempColor
    end
    
    --Standardize the color
    if color then
        if color.red > 1 then
            color.red = color.red / 255.0
        elseif color.red < 0 then
            color.red = 0
        end
        if color.green > 1 then
            color.green = color.green / 255.0
        elseif color.green < 0 then
            color.green = 0
        end
        if color.blue > 1 then
            color.blue = color.blue / 255.0
        elseif color.blue < 0 then
            color.blue = 0
        end
        if color.alpha > 1 then
            color.alpha = color.alpha / 255.0
        elseif color.alpha < 0 then
            color.alpha = 0
        end
    end
    
    --Same color, no need to update.
    if BetterLightFX.current_color == color then
        return
    end
    
    if SystemInfo:platform() == Idstring("WIN32") and managers.network.account:has_alienware() and not BetterLightFX.is_setting_color and event == BetterLightFX._current_event then
        BetterLightFX.is_setting_color = true
        --RGB to Mono
        
        local mono_color = ((color.red + color.green + color.blue) / 3.0 ) + BetterLightFX.Options.Monochrome_Brightness
        if mono_color > 1 then
            mono_color = 1
        elseif mono_color < 0 then
            mono_color = 0
        end
        
        if BetterLightFX.ColorSchemeOptions[BetterLightFX.Options.ColorScheme].name  == "RED" then
            BetterLightFX.current_color = Color(color.alpha, mono_color, 0, 0) 
        elseif BetterLightFX.ColorSchemeOptions[BetterLightFX.Options.ColorScheme].name == "GREEN" then
            BetterLightFX.current_color = Color(color.alpha, 0, mono_color, 0) 
        elseif BetterLightFX.ColorSchemeOptions[BetterLightFX.Options.ColorScheme].name == "BLUE" then
            BetterLightFX.current_color = Color(color.alpha, 0, 0, mono_color)
        elseif BetterLightFX.ColorSchemeOptions[BetterLightFX.Options.ColorScheme].name == "WHITE" then
            BetterLightFX.current_color = Color(color.alpha, mono_color, mono_color, mono_color)
        else
            BetterLightFX.current_color = color
        end
        
        LightFX:set_lamps_betterfx(math.floor(BetterLightFX.current_color.red * 255.0), math.floor(BetterLightFX.current_color.green * 255.0), math.floor(BetterLightFX.current_color.blue * 255.0), math.floor(BetterLightFX.current_color.alpha * 255.0))
        BetterLightFX._last_light_set_at = os.clock()
        BetterLightFX.is_setting_color = false
    end
    
    BetterLightFX:PrintDebugElapsed(os.clock() - debug_clockstart, "BetterLightFX:PushColor", BetterLightFX.LOG_LEVEL_WARNING) --DEBUG
end

function BetterLightFX:SetColor(red, green, blue, alpha, event)
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
        item.dirty_callback = nil
    end
    
    local new_menu_divider = node:create_item({type = "MenuItemDivider"}, {name = "divider_color_" .. params.event, no_text = true, size = 8,})
    node:add_item(new_menu_divider)
end

function BetterLightFX:CreateNumberOption(node, params)
    local data = {
        type = "CoreMenuItemSlider.ItemSlider",
        min = params.valMin or 0,
        max = params.valMax or 200,
        step = 0.5,
        show_value = true
    }

    local itemparams = {
        name = params.event .. "|" .. params.param,
        text_id = params.localization,
        callback = params.callback or "blfx_EventNumberCallback",
        disabled_color = Color( 0.25, 1, 1, 1 ),
        localize = false,
        eventParams = params
    }
    local item = node:create_item(data, itemparams)
    item:set_value(params.value)
    node:add_item(item)
    item.dirty_callback = nil
    
    local new_menu_divider = node:create_item({type = "MenuItemDivider"}, {name = "divider_number" .. params.event, no_text = true, size = 8,})
    node:add_item(new_menu_divider)
end

function BetterLightFX:CreateBoolOption(node, params)
    local data = {
		type = "CoreMenuItemToggle.ItemToggle",
		{
			_meta = "option",
			icon = "guis/textures/menu_tickbox",
			value = "on",
			x = 24,
			y = 0,
			w = 24,
			h = 24,
			s_icon = "guis/textures/menu_tickbox",
			s_x = 24,
			s_y = 24,
			s_w = 24,
			s_h = 24
		},
		{
			_meta = "option",
			icon = "guis/textures/menu_tickbox",
			value = "off",
			x = 0,
			y = 0,
			w = 24,
			h = 24,
			s_icon = "guis/textures/menu_tickbox",
			s_x = 0,
			s_y = 24,
			s_w = 24,
			s_h = 24
		}
	}

	local itemparams = {
		name = params.event .. "|" .. params.param,
		text_id = params.localization,
		callback = params.callback or "blfx_EventBoolCallback",
		disabled_color = Color( 0.25, 1, 1, 1 ),
		icon_by_text = false,
		localize = false,
        eventParams = params
	}

	local item = node:create_item( data, itemparams )
	item:set_value( params.value and "on" or "off" )
    node:add_item(item)
    item.dirty_callback = nil
    
    local new_menu_divider = node:create_item({type = "MenuItemDivider"}, {name = "divider_bool" .. params.event, no_text = true, size = 8,})
    node:add_item(new_menu_divider)
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
			[BetterLightFX.name .."toggle_help"] = "Toggles the BetterLightFX",
            [BetterLightFX.name .. "color_scheme_title"] = "Color Scheme",
			[BetterLightFX.name .. "color_scheme_desc"] = "Allows for selection of preferred coloring, in the event that you do not have an RGB device",
            [BetterLightFX.name .. "monochrome_brightness_title"] = "Monochrome Brightness",
			[BetterLightFX.name .. "monochrome_brightness_desc"] = "Adjusts the brightness for monochrome color scheme",
            [BetterLightFX.name .. "led_refresh_rate_title"] = "Lights Update Rate",
			[BetterLightFX.name .. "led_refresh_rate_desc"] = "The rate at which lights are updated per second (Less = smooth effects, high performance impact, More = choppy effects, lower performance impact)",
            [BetterLightFX.name .. "idleEvent_title"] = "Idle Action",
			[BetterLightFX.name .. "idleEvent_desc"] = "When lights are not being set, this event will be played",
            [BetterLightFX.name .. "IdleEvents_title"] = "Idle Settings",
			[BetterLightFX.name .. "IdleEvents_desc"] = "Change options of currently selected Idle Event",
            [BetterLightFX.name .. "modEvents_title"] = "Modify Events",
			[BetterLightFX.name .. "modEvents_desc"] = "Change options of BetterLightFX events",
            [BetterLightFX.name .. "events_title"] = "Event",
			[BetterLightFX.name .. "events_desc"] = "Select an event to modify",
            
            ["blfx_ColorsOut"] = "Dark",
            ["blfx_SingleColor"] = "Single Color",
            ["blfx_TwoColorFade"] = "Two Color Fade",
            ["blfx_Rainbow"] = "Rainbow",
            
            ["BLFXevent_Suspicion"] = "Suspicion",
			["BLFXevent_AssaultIndicator"] = "Assault Indicator",
            ["BLFXevent_PointOfNoReturn"] = "Point Of No Return",
            ["BLFXevent_TakenDamage"] = "Taken Damage",
            ["BLFXevent_TakenSevereDamage"] = "Critical Damage",
            ["BLFXevent_Bleedout"] = "Bleedout",
            ["BLFXevent_SwanSong"] = "Swan Song",
            ["BLFXevent_Electrocuted"] = "Electrocution",
            ["BLFXevent_Flashbang"] = "Flashbang",
            ["BLFXevent_EndLoss"] = "Game Over",
            ["BLFXevent_LevelUp"] = "Level Up",
            ["BLFXevent_SafeDrilled"] = "Safe Drilled",
            
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
        MenuHelper:NewMenu(BetterLightFX.menuIdleEventOptions)
        
    end)
    
    Hooks:RegisterHook(BetterLightFX.name .. "CreateEvents")
    
    Hooks:Add("MenuManagerPopulateCustomMenus", "Base_Populate" .. BetterLightFX.name .. "Menus", function( menu_manager, nodes )
        MenuCallbackHandler.blfx_options_opened = function(this, item)
            local node = nodes[BetterLightFX.menuOptions]
            if managers and managers.network and managers.network.account and not managers.network.account:has_alienware() then
                if not node:item("LightFX_ERROR") then
                    local item_params = {
                        name = "LightFX_ERROR",
                        text_id = "LightFX device is not present",
                        help_id = "Please check that your LightFX device is on or if your LightFX Extender is installed",
                        disabled_color = Color(0.80, 1, 0, 0),
                        localize_help = false,
                    }
                    
                    local item = node:create_item({ type = "CoreMenuItem.Item" }, item_params)
                    item:set_enabled(false)
                    node:insert_item(item, 1)
                end
            else
                if node:item("LightFX_ERROR") then
                    node:delete_item("LightFX_ERROR")
                end
            end
        end
        
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
        
        MenuCallbackHandler.blfx_LEDRefreshRate_Changed = function(this, item)
            BetterLightFX.Options.LEDRefreshRate = item:value()
            BetterLightFX:Save()
        end
        
        MenuHelper:AddSlider({
            id = BetterLightFX.name .. "led_refresh_rate",
            title = BetterLightFX.name .. "led_refresh_rate_title",
            desc = BetterLightFX.name .. "led_refresh_rate_desc",
            callback = "blfx_LEDRefreshRate_Changed",
            menu_id = BetterLightFX.menuOptions,
            value = BetterLightFX.Options.LEDRefreshRate,
            min = 0.001,
            max = 0.1,
            step = 0.001,
            show_value = true,
            priority = 998
        })
        
        MenuHelper:AddDivider({
            id = "LEDRefreshRateDivider",
            size = 16,
            menu_id = BetterLightFX.menuOptions,
            priority = 998,
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
        
        MenuCallbackHandler.blfx_monochrome_brightness = function(this, item)
            BetterLightFX.Options.Monochrome_Brightness = item:value()
            BetterLightFX:Save()
        end
        
        MenuHelper:AddSlider({
            id = BetterLightFX.name .. "monochrome_brightness",
            title = BetterLightFX.name .. "monochrome_brightness_title",
            desc = BetterLightFX.name .. "monochrome_brightness_desc",
            callback = "blfx_monochrome_brightness",
            menu_id = BetterLightFX.menuOptions,
            value = BetterLightFX.Options.Monochrome_Brightness,
            min = 0,
            max = 1,
            step = 0.01,
            show_value = true,
            priority = 997
        })
        
        MenuHelper:AddDivider({
            id = "RGB_Divider",
            size = 16,
            menu_id = BetterLightFX.menuOptions,
            priority = 996
        })
        
        MenuCallbackHandler.blfx_IdleEventChange = function(this, item)
            BetterLightFX.Options.IdleEvent = item:value()
            BetterLightFX:Save()
        end
        
        MenuHelper:AddMultipleChoice({
			id = BetterLightFX.name .. "idleEvent",
			title = BetterLightFX.name .. "idleEvent_title",
			desc = BetterLightFX.name .. "idleEvent_desc",
			callback = "blfx_IdleEventChange",
			menu_id = BetterLightFX.menuOptions,
			value = BetterLightFX.Options.IdleEvent,
			items = BetterLightFX:GetSubVariableFromArray(BetterLightFX.IdleEventModOptions, "event_name", "blfx_"),
			priority = 995
		})
        
        
        MenuCallbackHandler.blfx_createIdleEventMenuItems = function(this, item)
            local node = nodes[BetterLightFX.menuIdleEventOptions]
            
            node:set_items({})
            
            local eventData = BetterLightFX.IdleEventModOptions[BetterLightFX.Options.IdleEvent]
            
            if eventData and eventData.options then
                for _, opt in ipairs(eventData.options) do 
                    BetterLightFX:CreateEventOptionButton(node, {
                        event = eventData.event_name, 
                        typ = opt.typ, 
                        value = BetterLightFX:GetIdleEventParamaterValue(eventData.event_name, opt.parameter),
                        param = opt.parameter, 
                        localization = opt.localization,
                        valMin = opt.minVal or 0,
                        valMax = opt.maxVal or 0
                    })
                end
            end
            
            managers.menu:add_back_button(node)
            
            local selected_node = managers.menu:active_menu().logic:selected_node()
            managers.menu:active_menu().renderer:refresh_node(selected_node)
            local selected_item = selected_node:selected_item()
            selected_node:select_item(selected_item and selected_item:name())
            managers.menu:active_menu().renderer:highlight_item(selected_item)
        end
        
        MenuHelper:AddButton({
                id = "IdleEvents",
                title = BetterLightFX.name .. "IdleEvents_title",
                desc = BetterLightFX.name .. "IdleEvents_desc",
                callback = "blfx_createIdleEventMenuItems",
                next_node = BetterLightFX.menuIdleEventOptions,
                menu_id = BetterLightFX.menuOptions,
                priority = 994
            })
    
        MenuHelper:AddDivider({
                id = "IdleEventsDivider",
                size = 16,
                menu_id = BetterLightFX.menuIdleEventOptions,
                priority = 993,
            })
    
        MenuCallbackHandler.blfx_createEventModMenuItems = function(this, item)
            BetterLightFX.currentEvent = item:name() == (BetterLightFX.name .. "events") and item:value() or BetterLightFX.currentEvent or 1
            local node = nodes[BetterLightFX.menuEventOptions]
            
            node:set_items({
                node:item(BetterLightFX.name .. "events"),
                node:item("EventDivider")
            })
            
            local eventData = BetterLightFX.EventModOptions[BetterLightFX.currentEvent]
            
            if eventData and eventData.options then
                for _, opt in ipairs(eventData.options) do 
                    BetterLightFX:CreateEventOptionButton(node, {
                        event = eventData.event_name, 
                        typ = opt.typ, 
                        value = BetterLightFX:GetEventParamaterValue(eventData.event_name, opt.parameter),
                        param = opt.parameter, 
                        localization = opt.localization,
                        valMin = opt.minVal or 0,
                        valMax = opt.maxVal or 0
                    })
                end
            end
            
            managers.menu:add_back_button(node)
            
            local selected_node = managers.menu:active_menu().logic:selected_node()
            managers.menu:active_menu().renderer:refresh_node(selected_node)
            local selected_item = selected_node:selected_item()
            selected_node:select_item(selected_item and selected_item:name())
            managers.menu:active_menu().renderer:highlight_item(selected_item)
        end
        
        Hooks:Call(BetterLightFX.name .. "CreateEvents", BetterLightFX)
        
        if #BetterLightFX.EventModOptions > 0 then
            MenuHelper:AddButton({
                id = "ModEvents",
                title = BetterLightFX.name .. "modEvents_title",
                desc = BetterLightFX.name .. "modEvents_desc",
                callback = "blfx_createEventModMenuItems",
                next_node = BetterLightFX.menuEventOptions,
                menu_id = BetterLightFX.menuOptions,
                priority = 992
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
            
            BetterLightFX.Options[event] = BetterLightFX.Options[event] or {}
            BetterLightFX.Options[event][param] = BetterLightFX.Options[event][param] or {}
            BetterLightFX.Options[event][param][color] = item:value() / 255
            
            BetterLightFX:Save()
            
            if BetterLightFX.events[event] then
                BetterLightFX.events[event][param][color] = item:value() / 255
            elseif BetterLightFX.idle_events[event] then
                BetterLightFX.idle_events[event][param][color] = item:value() / 255
            end
        end
        
        MenuCallbackHandler.blfx_EventNumberCallback = function(this, item)
            local event = item:parameters().eventParams.event
            local param = item:parameters().eventParams.param
            
            BetterLightFX.Options[event] = BetterLightFX.Options[event] or {}
            BetterLightFX.Options[event][param] = item:value()
            
            BetterLightFX:Save()
            
            if BetterLightFX.events[event] then
                BetterLightFX.events[event][param] = item:value()
            elseif BetterLightFX.idle_events[event] then
                BetterLightFX.idle_events[event][param] = item:value()
            end
        end
        
        MenuCallbackHandler.blfx_EventBoolCallback = function(this, item)
            local event = item:parameters().eventParams.event
            local param = item:parameters().eventParams.param
            
            BetterLightFX.Options[event] = BetterLightFX.Options[event] or {}
            BetterLightFX.Options[event][param] = item:value() == "on" and true or false
            
            BetterLightFX:Save()
            
            if BetterLightFX.events[event] then
                BetterLightFX.events[event][param] = item:value() == "on" and true or false
            elseif BetterLightFX.idle_events[event] then
                BetterLightFX.idle_events[event][param] = item:value() == "on" and true or false
            end
        end
        
    end)
    
    Hooks:Add("MenuManagerBuildCustomMenus", "Base_Build" .. BetterLightFX.name .. "Menus", function(menu_manager, nodes)
		nodes[BetterLightFX.menuOptions] = MenuHelper:BuildMenu(BetterLightFX.menuOptions)
        nodes[BetterLightFX.menuEventOptions] = MenuHelper:BuildMenu(BetterLightFX.menuEventOptions)
        nodes[BetterLightFX.menuIdleEventOptions] = MenuHelper:BuildMenu(BetterLightFX.menuIdleEventOptions)
        

        local node = nodes[LuaModManager.Constants._lua_mod_options_menu_id]
        local item_params = {
            name = "BLFOptionsBtn",
            text_id = BetterLightFX.name .. "MainOptionsButton",
            help_id = BetterLightFX.name .. "MainOptionsButtonDescription",
            callback = "blfx_options_opened",
            next_node = BetterLightFX.menuOptions
        }
        
        local item = node:create_item({ type = "CoreMenuItem.Item" }, item_params)
        node:add_item(item)
        
    end)

end