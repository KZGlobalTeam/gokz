/*
	GOKZ KZPlayer Methodmap Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_kzplayer_included_
#endinput
#endif
#define _gokz_kzplayer_included_

#include <movementapi>

#include <gokz>



methodmap KZPlayer < MovementAPIPlayer {
	
	public KZPlayer(int client) {
		return view_as<KZPlayer>(MovementAPIPlayer(client));
	}
	
	
	
	// =====[ GENERAL ]=====
	
	property bool Valid {
		public get() {
			return IsValidClient(this.ID);
		}
	}
	
	property bool InGame {
		public get() {
			return IsClientInGame(this.ID);
		}
	}
	
	property bool Authorized {
		public get() {
			return IsClientAuthorized(this.ID);
		}
	}
	
	property bool Fake {
		public get() {
			return IsFakeClient(this.ID);
		}
	}
	
	property bool Alive {
		public get() {
			return IsPlayerAlive(this.ID);
		}
	}
	
	property ObsMode ObserverMode {
		public get() {
			return GetObserverMode(this.ID);
		}
	}
	
	property int ObserverTarget {
		public get() {
			return GetObserverTarget(this.ID);
		}
	}
	
	
	
	// =====[ CORE ]=====
	#if defined _gokz_core_included_
	
	public void StartTimer(int course) {
		GOKZ_StartTimer(this.ID, course);
	}
	
	public void EndTimer(int course) {
		GOKZ_EndTimer(this.ID, course);
	}
	
	public bool StopTimer() {
		return GOKZ_StopTimer(this.ID);
	}
	
	public void TeleportToStart() {
		GOKZ_TeleportToStart(this.ID);
	}
	
	public void TeleportToSearchStart(int course) {
		GOKZ_TeleportToSearchStart(this.ID, course);
	}
	
	public void TeleportToEnd(int course) {
		GOKZ_TeleportToEnd(this.ID, course);
	}

	property StartPositionType StartPositionType {
		public get() {
			return GOKZ_GetStartPositionType(this.ID);
		}
	}
	
	public void MakeCheckpoint() {
		GOKZ_MakeCheckpoint(this.ID);
	}
	
	property bool CanMakeCheckpoint {
		public get() {
			return GOKZ_GetCanMakeCheckpoint(this.ID);
		}
	}

	public void TeleportToCheckpoint() {
		GOKZ_TeleportToCheckpoint(this.ID);
	}
	
	property bool CanTeleportToCheckpoint {
		public get() {
			return GOKZ_GetCanTeleportToCheckpoint(this.ID);
		}
	}
	
	public void PrevCheckpoint() {
		GOKZ_PrevCheckpoint(this.ID);
	}
	
	property bool CanPrevCheckpoint {
		public get() {
			return GOKZ_GetCanPrevCheckpoint(this.ID);
		}
	}
	
	public void NextCheckpoint() {
		GOKZ_NextCheckpoint(this.ID);
	}
	
	property bool CanNextCheckpoint {
		public get() {
			return GOKZ_GetCanNextCheckpoint(this.ID);
		}
	}
	
	public void UndoTeleport() {
		GOKZ_UndoTeleport(this.ID);
	}
	
	property bool CanUndoTeleport {
		public get() {
			return GOKZ_GetCanUndoTeleport(this.ID);
		}
	}
	
	public void Pause() {
		GOKZ_Pause(this.ID);
	}
	
	property bool CanPause {
		public get() {
			return GOKZ_GetCanPause(this.ID);
		}
	}
	
	public void Resume() {
		GOKZ_Resume(this.ID);
	}
	
	property bool CanResume {
		public get() {
			return GOKZ_GetCanResume(this.ID);
		}
	}
	
	public void TogglePause() {
		GOKZ_TogglePause(this.ID);
	}
	
	public void PlayErrorSound() {
		GOKZ_PlayErrorSound(this.ID);
	}
	
	property bool TimerRunning {
		public get() {
			return GOKZ_GetTimerRunning(this.ID);
		}
	}
	
	property int Course {
		public get() {
			return GOKZ_GetCourse(this.ID);
		}
	}
	
	property bool Paused {
		public get() {
			return GOKZ_GetPaused(this.ID);
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
	
	property bool CanTeleportToStart {
		public get() {
			return GOKZ_GetCanTeleportToStartOrEnd(this.ID);
		}
	}
	
	property float Time {
		public get() {
			return GOKZ_GetTime(this.ID);
		}
		public set(float value) {
			GOKZ_SetTime(this.ID, value);
		}
	}
	
	property int CheckpointCount {
		public get() {
			return GOKZ_GetCheckpointCount(this.ID);
		}
		public set(int cpCount) {
			GOKZ_SetCheckpointCount(this.ID, cpCount);
		}
	}
	
	property ArrayList CheckpointData {
		public get() {
			return GOKZ_GetCheckpointData(this.ID);
		}
		public set(ArrayList checkpoints) {
			GOKZ_SetCheckpointData(this.ID, checkpoints, GOKZ_CHECKPOINT_VERSION);
		}
	}
	
	property int TeleportCount {
		public get() {
			return GOKZ_GetTeleportCount(this.ID);
		}
		public set(int value) {
			GOKZ_SetTeleportCount(this.ID, value);
		}
	}
	
	property int TimeType {
		public get() {
			return GOKZ_GetTimeType(this.ID);
		}
	}
	
	property bool GOKZHitPerf {
		public get() {
			return GOKZ_GetHitPerf(this.ID);
		}
		public set(bool value) {
			GOKZ_SetHitPerf(this.ID, value);
		}
	}
	
	property float GOKZTakeoffSpeed {
		public get() {
			return GOKZ_GetTakeoffSpeed(this.ID);
		}
		public set(float value) {
			GOKZ_SetTakeoffSpeed(this.ID, value);
		}
	}
	
	property bool ValidJump {
		public get() {
			return GOKZ_GetValidJump(this.ID);
		}
	}
	
	public any GetOption(const char[] option) {
		return GOKZ_GetOption(this.ID, option);
	}
	
	public bool SetOption(const char[] option, any value) {
		return GOKZ_SetOption(this.ID, option, value);
	}
	
	public bool CycleOption(const char[] option) {
		return GOKZ_CycleOption(this.ID, option);
	}
	
	public any GetCoreOption(Option option) {
		return GOKZ_GetCoreOption(this.ID, option);
	}
	
	public bool SetCoreOption(Option option, int value) {
		return GOKZ_SetCoreOption(this.ID, option, value);
	}
	
	public bool CycleCoreOption(Option option) {
		return GOKZ_CycleCoreOption(this.ID, option);
	}
	
	property int Mode {
		public get() {
			return this.GetCoreOption(Option_Mode);
		}
		public set(int value) {
			this.SetCoreOption(Option_Mode, value);
		}
	}
	
	property int Style {
		public get() {
			return this.GetCoreOption(Option_Style);
		}
		public set(int value) {
			this.SetCoreOption(Option_Style, value);
		}
	}
	
	property int CheckpointMessages {
		public get() {
			return this.GetCoreOption(Option_CheckpointMessages);
		}
		public set(int value) {
			this.SetCoreOption(Option_CheckpointMessages, value);
		}
	}
	
	property int CheckpointSounds {
		public get() {
			return this.GetCoreOption(Option_CheckpointSounds);
		}
		public set(int value) {
			this.SetCoreOption(Option_CheckpointSounds, value);
		}
	}
	
	property int TeleportSounds {
		public get() {
			return this.GetCoreOption(Option_TeleportSounds);
		}
		public set(int value) {
			this.SetCoreOption(Option_TeleportSounds, value);
		}
	}
	
	property int ErrorSounds {
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
		return GOKZ_HUD_GetOption(this.ID, option);
	}
	
	public bool SetHUDOption(HUDOption option, any value) {
		return GOKZ_HUD_SetOption(this.ID, option, value);
	}
	
	public bool CycleHUDOption(HUDOption option) {
		return GOKZ_HUD_CycleOption(this.ID, option);
	}
	
	property int TPMenu {
		public get() {
			return this.GetHUDOption(HUDOption_TPMenu);
		}
		public set(int value) {
			this.SetHUDOption(HUDOption_TPMenu, value);
		}
	}
	
	property int InfoPanel {
		public get() {
			return this.GetHUDOption(HUDOption_InfoPanel);
		}
		public set(int value) {
			this.SetHUDOption(HUDOption_InfoPanel, value);
		}
	}
	
	property int ShowKeys {
		public get() {
			return this.GetHUDOption(HUDOption_ShowKeys);
		}
		public set(int value) {
			this.SetHUDOption(HUDOption_ShowKeys, value);
		}
	}
	
	property int TimerText {
		public get() {
			return this.GetHUDOption(HUDOption_TimerText);
		}
		public set(int value) {
			this.SetHUDOption(HUDOption_TimerText, value);
		}
	}
	
	property int TimerStyle {
		public get() {
			return this.GetHUDOption(HUDOption_TimerStyle);
		}
		public set(int value) {
			this.SetHUDOption(HUDOption_TimerStyle, value);
		}
	}
	
	property int SpeedText {
		public get() {
			return this.GetHUDOption(HUDOption_SpeedText);
		}
		public set(int value) {
			this.SetHUDOption(HUDOption_SpeedText, value);
		}
	}
	
	property int ShowWeapon {
		public get() {
			return this.GetHUDOption(HUDOption_ShowWeapon);
		}
		public set(int value) {
			this.SetHUDOption(HUDOption_ShowWeapon, value);
		}
	}
	
	property int ReplayControls {
		public get() {
			return this.GetHUDOption(HUDOption_ShowControls);
		}
		public set(int value) {
			this.SetHUDOption(HUDOption_ShowControls, value);
		}
	}

	property int ShowSpectators {
		public get() {
			return this.GetHUDOption(HUDOption_ShowSpectators);
		}
		public set(int value) {
			this.SetHUDOption(HUDOption_ShowSpectators, value);
		}
	}

	property int SpecListPosition {
		public get() {
			return this.GetHUDOption(HUDOption_SpecListPosition);
		}
		public set(int value){
			this.SetHUDOption(HUDOption_SpecListPosition, value);
		}
	}

	property bool MenuShowing {
		public get() {
			return GOKZ_HUD_GetMenuShowing(this.ID);
		}
		public set(bool value) {
			GOKZ_HUD_SetMenuShowing(this.ID, value);
		}
	}
	property int DynamicMenu {
		public get() {
			return this.GetHUDOption(HUDOption_DynamicMenu);
		}
		public set(int value) {
			this.SetHUDOption(HUDOption_DynamicMenu, value);
		}
	}
	#endif
	// =====[ END HUD ]=====
	
	
	
	// =====[ PISTOL ]=====
	#if defined _gokz_pistol_included_
	
	property int Pistol {
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
		return GOKZ_JB_GetOption(this.ID, option);
	}
	
	public bool SetJBOption(JBOption option, any value) {
		return GOKZ_JB_SetOption(this.ID, option, value);
	}
	
	public bool CycleJBOption(JBOption option) {
		return GOKZ_JB_CycleOption(this.ID, option);
	}
	
	property int JBType {
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
	
	property int Tips {
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
	
	property int ShowPlayers {
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
	
	property int SlayOnEnd {
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