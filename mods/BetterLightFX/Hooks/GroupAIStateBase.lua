function GroupAIStateBase:set_assault_mode(enabled)
	if self._assault_mode ~= enabled then
		self._assault_mode = enabled
		self:set_ambience_flag()
		SoundDevice:set_state("wave_flag", enabled and "assault" or "control")
		managers.network:session():send_to_peers_synched("sync_assault_mode", enabled)
		if not enabled then
			self._warned_about_deploy_this_control = nil
			self._warned_about_freed_this_control = nil
			if not Global.game_settings.single_player and table.size(self:all_char_criminals()) == 1 then
				self._coach_clbk = callback(self, self, "_coach_last_man_clbk")
				managers.enemy:add_delayed_clbk("_coach_last_man_clbk", self._coach_clbk, Application:time() + 15)
			end
		end
	end
end