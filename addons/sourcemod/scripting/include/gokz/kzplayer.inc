/*
	GOKZ KZPlayer Methodmap Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_kzplayer_included_
#endinput
#endif
#define _gokz_kzplayer_included_

#include <gokz>
#include <movementapi>



methodmap KZPlayer < MovementAPIPlayer {
	
	public KZPlayer(int client) {
		return view_as<KZPlayer>(MovementAPIPlayer(client));
	}
	
	
	
	// =====[ GENERAL ]=====
	
	property bool valid {
		public get() {
			return IsValidClient(this.id);
		}
	}
	
	property bool inGame {
		public get() {
			return IsClientInGame(this.id);
		}
	}
	
	property bool authorized {
		public get() {
			return IsClientAuthorized(this.id);
		}
	}
	
	property bool fake {
		public get() {
			return IsFakeClient(this.id);
		}
	}
	
	property bool alive {
		public get() {
			return IsPlayerAlive(this.id);
		}
	}
	
	property ObsMode observerMode {
		public get() {
			return GetObserverMode(this.id);
		}
	}
	
	property int observerTarget {
		public get() {
			return GetObserverTarget(this.id);
		}
	}
	
	
	
	// =====[ CORE ]=====
	#if defined _gokz_core_included_
	
	public void StartTimer(int course) {
		GOKZ_StartTimer(this.id, course);
	}
	
	public void EndTimer(int course) {
		GOKZ_EndTimer(this.id, course);
	}
	
	public bool StopTimer() {
		return GOKZ_StopTimer(this.id);
	}
	
	public void TeleportToStart() {
		GOKZ_TeleportToStart(this.id);
	}
	
	property bool hasStartPosition {
		public get() {
			return GOKZ_GetHasStartPosition(this.id);
		}
	}
	
	public void MakeCheckpoint() {
		GOKZ_MakeCheckpoint(this.id);
	}
	
	public void TeleportToCheckpoint() {
		GOKZ_TeleportToCheckpoint(this.id);
	}
	
	property bool canTeleportToCheckpoint {
		public get() {
			return GOKZ_GetCanTeleportToCheckpoint(this.id);
		}
	}
	
	public void PrevCheckpoint() {
		GOKZ_PrevCheckpoint(this.id);
	}
	
	property bool canPrevCheckpoint {
		public get() {
			return GOKZ_GetCanPrevCheckpoint(this.id);
		}
	}
	
	public void NextCheckpoint() {
		GOKZ_NextCheckpoint(this.id);
	}
	
	property bool canNextCheckpoint {
		public get() {
			return GOKZ_GetCanNextCheckpoint(this.id);
		}
	}
	
	public void UndoTeleport() {
		GOKZ_UndoTeleport(this.id);
	}
	
	property bool canUndoTeleport {
		public get() {
			return GOKZ_GetCanUndoTeleport(this.id);
		}
	}
	
	public void Pause() {
		GOKZ_Pause(this.id);
	}
	
	public void Resume() {
		GOKZ_Resume(this.id);
	}
	
	public void TogglePause() {
		GOKZ_TogglePause(this.id);
	}
	
	public void PlayErrorSound() {
		GOKZ_PlayErrorSound(this.id);
	}
	
	property bool timerRunning {
		public get() {
			return GOKZ_GetTimerRunning(this.id);
		}
	}
	
	property int course {
		public get() {
			return GOKZ_GetCourse(this.id);
		}
	}
	
	property bool paused {
		public get() {
			return GOKZ_GetPaused(this.id);
		}
		public set(bool pause) {
			if (pause) {
				this.Pause();
			}
			else {
				this.Resume();
			}
		}
	}
	
	property float time {
		public get() {
			return GOKZ_GetTime(this.id);
		}
		public set(float value) {
			GOKZ_SetTime(this.id, value);
		}
	}
	
	property int checkpointCount {
		public get() {
			return GOKZ_GetCheckpointCount(this.id);
		}
		public set(int value) {
			GOKZ_SetCheckpointCount(this.id, value);
		}
	}
	
	property int teleportCount {
		public get() {
			return GOKZ_GetTeleportCount(this.id);
		}
		public set(int value) {
			GOKZ_SetTeleportCount(this.id, value);
		}
	}
	
	property int timeType {
		public get() {
			return GOKZ_GetTimeType(this.id);
		}
	}
	
	property bool gokzHitPerf {
		public get() {
			return GOKZ_GetHitPerf(this.id);
		}
		public set(bool value) {
			GOKZ_SetHitPerf(this.id, value);
		}
	}
	
	property float gokzTakeoffSpeed {
		public get() {
			return GOKZ_GetTakeoffSpeed(this.id);
		}
		public set(float value) {
			GOKZ_SetTakeoffSpeed(this.id, value);
		}
	}
	
	property bool validJump {
		public get() {
			return GOKZ_GetValidJump(this.id);
		}
	}
	
	public any GetOption(const char[] option) {
		return GOKZ_GetOption(this.id, option);
	}
	
	public bool SetOption(const char[] option, any value) {
		return GOKZ_SetOption(this.id, option, value);
	}
	
	public bool CycleOption(const char[] option) {
		return GOKZ_CycleOption(this.id, option);
	}
	
	public any GetCoreOption(Option option) {
		return GOKZ_GetCoreOption(this.id, option);
	}
	
	public bool SetCoreOption(Option option, int value) {
		return GOKZ_SetCoreOption(this.id, option, value);
	}
	
	public bool CycleCoreOption(Option option) {
		return GOKZ_CycleCoreOption(this.id, option);
	}
	
	property int mode {
		public get() {
			return this.GetCoreOption(Option_Mode);
		}
		public set(int value) {
			this.SetCoreOption(Option_Mode, value);
		}
	}
	
	property int style {
		public get() {
			return this.GetCoreOption(Option_Style);
		}
		public set(int value) {
			this.SetCoreOption(Option_Style, value);
		}
	}
	
	property int autoRestart {
		public get() {
			return this.GetCoreOption(Option_AutoRestart);
		}
		public set(int value) {
			this.SetCoreOption(Option_AutoRestart, value);
		}
	}
	
	property int checkpointMessages {
		public get() {
			return this.GetCoreOption(Option_CheckpointMessages);
		}
		public set(int value) {
			this.SetCoreOption(Option_CheckpointMessages, value);
		}
	}
	
	property int checkpointSounds {
		public get() {
			return this.GetCoreOption(Option_CheckpointSounds);
		}
		public set(int value) {
			this.SetCoreOption(Option_CheckpointSounds, value);
		}
	}
	
	property int teleportSounds {
		public get() {
			return this.GetCoreOption(Option_TeleportSounds);
		}
		public set(int value) {
			this.SetCoreOption(Option_TeleportSounds, value);
		}
	}
	
	property int errorSounds {
		public get() {
			return this.GetCoreOption(Option_ErrorSounds);
		}
		public set(int value) {
			this.SetCoreOption(Option_ErrorSounds, value);
		}
	}
	
	#endif
	// =====[ END CORE ]=====
	
	
	
	// =====[ HUD ]=====
	#if defined _gokz_hud_included_
	
	public any GetHUDOption(HUDOption option) {
		return GOKZ_HUD_GetOption(this.id, option);
	}
	
	public bool SetHUDOption(HUDOption option, any value) {
		return GOKZ_HUD_SetOption(this.id, option, value);
	}
	
	public bool CycleHUDOption(HUDOption option) {
		return GOKZ_HUD_CycleOption(this.id, option);
	}
	
	property int tpMenu {
		public get() {
			return this.GetHUDOption(HUDOption_TPMenu);
		}
		public set(int value) {
			this.SetHUDOption(HUDOption_TPMenu, value);
		}
	}
	
	property int infoPanel {
		public get() {
			return this.GetHUDOption(HUDOption_InfoPanel);
		}
		public set(int value) {
			this.SetHUDOption(HUDOption_InfoPanel, value);
		}
	}
	
	property int showKeys {
		public get() {
			return this.GetHUDOption(HUDOption_ShowKeys);
		}
		public set(int value) {
			this.SetHUDOption(HUDOption_ShowKeys, value);
		}
	}
	
	property int timerText {
		public get() {
			return this.GetHUDOption(HUDOption_TimerText);
		}
		public set(int value) {
			this.SetHUDOption(HUDOption_TimerText, value);
		}
	}
	
	property int speedText {
		public get() {
			return this.GetHUDOption(HUDOption_SpeedText);
		}
		public set(int value) {
			this.SetHUDOption(HUDOption_SpeedText, value);
		}
	}
	
	property int showWeapon {
		public get() {
			return this.GetHUDOption(HUDOption_ShowWeapon);
		}
		public set(int value) {
			this.SetHUDOption(HUDOption_ShowWeapon, value);
		}
	}
	
	#endif
	// =====[ END HUD ]=====
	
	
	
	// =====[ PISTOL ]=====
	#if defined _gokz_pistol_included_
	
	property int pistol {
		public get() {
			return this.GetOption(PISTOL_OPTION_NAME);
		}
		public set(int value) {
			this.SetOption(PISTOL_OPTION_NAME, value);
		}
	}
	
	#endif
	// =====[ END PISTOL ]=====
	
	
	
	// =====[ JUMP BEAM ]=====
	#if defined _gokz_jumpbeam_included_
	
	public any GetJBOption(JBOption option) {
		return GOKZ_JB_GetOption(this.id, option);
	}
	
	public bool SetJBOption(JBOption option, any value) {
		return GOKZ_JB_SetOption(this.id, option, value);
	}
	
	public bool CycleJBOption(JBOption option) {
		return GOKZ_JB_CycleOption(this.id, option);
	}
	
	property int jbType {
		public get() {
			return this.GetJBOption(JBOption_Type);
		}
		public set(int value) {
			this.SetJBOption(JBOption_Type, value);
		}
	}
	
	#endif
	// =====[ END JUMP BEAM ]=====
	
	
	
	// =====[ TIPS ]=====
	#if defined _gokz_tips_included_
	
	property int tips {
		public get() {
			return this.GetOption(TIPS_OPTION_NAME);
		}
		public set(int value) {
			this.SetOption(TIPS_OPTION_NAME, value);
		}
	}
	
	#endif
	// =====[ END TIPS ]=====
	
	
	
	// =====[ QUIET ]=====
	#if defined _gokz_quiet_included_
	
	property int showPlayers {
		public get() {
			return this.GetOption(gC_QTOptionNames[QTOption_ShowPlayers]);
		}
		public set(int value) {
			this.SetOption(gC_QTOptionNames[QTOption_ShowPlayers], value);
		}
	}
	
	#endif
	// =====[ END QUIET ]=====
	
	
	
	// =====[ SLAY ON END ]=====
	#if defined _gokz_slayonend_included_
	
	property int slayOnEnd {
		public get() {
			return this.GetOption(SLAYONEND_OPTION_NAME);
		}
		public set(int value) {
			this.SetOption(SLAYONEND_OPTION_NAME, value);
		}
	}
	
	#endif
	// =====[ END SLAY ON END ]=====
} 