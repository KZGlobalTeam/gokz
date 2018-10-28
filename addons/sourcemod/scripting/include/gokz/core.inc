/* 	
	GOKZ Core Include File
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_core_included_
#endinput
#endif
#define _gokz_core_included_

#include <topmenus>

#include <gokz>
#include <movementapi>



// =========================  DEFINITIONS  ========================= //

#define MAX_COURSES 256
#define OPTIONS_MENU_CAT_GENERAL "general"



// =========================  ENUMERATIONS  ========================= //

enum
{
	TimeType_Nub = 0, 
	TimeType_Pro, 
	TIMETYPE_COUNT
};

enum
{
	MapPrefix_Other = 0, 
	MapPrefix_KZPro, 
	MAPPREFIX_COUNT
};

enum OptionProp
{
	OptionProp_Cookie = 0, 
	OptionProp_Type, 
	OptionProp_DefaultValue, 
	OptionProp_MinValue, 
	OptionProp_MaxValue, 
	OPTIONPROP_COUNT
};

enum OptionType
{
	OptionType_Int = 0, 
	OptionType_Float
};

enum Option
{
	OPTION_INVALID = -1, 
	Option_Mode, 
	Option_Style, 
	Option_ShowingPlayers, 
	Option_ShowingWeapon, 
	Option_AutoRestart, 
	Option_SlayOnEnd, 
	Option_Pistol, 
	Option_CheckpointMessages, 
	Option_CheckpointSounds, 
	Option_TeleportSounds, 
	Option_ErrorSounds, 
	Option_JumpBeam, 
	Option_HelpAndTips, 
	OPTION_COUNT
};

enum
{
	Mode_Vanilla = 0, 
	Mode_SimpleKZ, 
	Mode_KZTimer, 
	MODE_COUNT
};

enum
{
	Style_Normal = 0, 
	STYLE_COUNT
};

enum
{
	ShowingPlayers_Disabled = 0, 
	ShowingPlayers_Enabled, 
	SHOWINGPLAYERS_COUNT
};

enum
{
	ShowingWeapon_Disabled = 0, 
	ShowingWeapon_Enabled, 
	SHOWINGWEAPON_COUNT
};

enum
{
	AutoRestart_Disabled = 0, 
	AutoRestart_Enabled, 
	AUTORESTART_COUNT
};

enum
{
	SlayOnEnd_Disabled = 0, 
	SlayOnEnd_Enabled, 
	SLAYONEND_COUNT
};

enum
{
	Pistol_USP = 0, 
	Pistol_Glock, 
	Pistol_P250, 
	Pistol_Dualies, 
	Pistol_Deagle, 
	Pistol_CZ75A, 
	Pistol_FiveSeveN, 
	Pistol_Tec9, 
	Pistol_R8Revolver, 
	Pistol_Disabled, 
	PISTOL_COUNT
};

enum
{
	CheckpointMessages_Disabled = 0, 
	CheckpointMessages_Enabled, 
	CHECKPOINTMESSAGES_COUNT
};

enum
{
	CheckpointSounds_Disabled = 0, 
	CheckpointSounds_Enabled, 
	CHECKPOINTSOUNDS_COUNT
};

enum
{
	TeleportSounds_Disabled = 0, 
	TeleportSounds_Enabled, 
	TELEPORTSOUNDS_COUNT
};

enum
{
	ErrorSounds_Disabled = 0, 
	ErrorSounds_Enabled, 
	ERRORSOUNDS_COUNT
};

enum
{
	JumpBeam_Disabled = 0, 
	JumpBeam_Feet, 
	JumpBeam_Head, 
	JumpBeam_FeetAndHead, 
	JumpBeam_Ground, 
	JUMPBEAM_COUNT
};

enum
{
	HelpAndTips_Disabled = 0, 
	HelpAndTips_Enabled, 
	HELPANDTIPS_COUNT
};

enum
{
	ModeCVar_Accelerate = 0, 
	ModeCVar_Friction, 
	ModeCVar_AirAccelerate, 
	ModeCVar_LadderScaleSpeed, 
	ModeCVar_MaxVelocity, 
	ModeCVar_Gravity, 
	ModeCVar_EnableBunnyhopping, 
	ModeCVar_AutoBunnyhopping, 
	ModeCVar_StaminaMax, 
	ModeCVar_StaminaLandCost, 
	ModeCVar_StaminaJumpCost, 
	ModeCVar_StaminaRecoveryRate, 
	ModeCVar_MaxSpeed, 
	ModeCVar_WaterAccelerate, 
	ModeCVar_TimeBetweenDucks, 
	ModeCVar_AccelerateUseWeaponSpeed, 
	ModeCVar_JumpImpulse, 
	MODECVAR_COUNT
};



// =========================  PHRASES  ========================= //

stock char gC_ModeNames[MODE_COUNT][] = 
{
	"Vanilla", 
	"SimpleKZ", 
	"KZTimer"
};

stock char gC_ModeNamesShort[MODE_COUNT][] = 
{
	"VNL", 
	"SKZ", 
	"KZT"
};

stock char gC_StyleNamesShort[STYLE_COUNT][] = 
{
	"NRM"
};

stock char gC_TimeTypeNames[TIMETYPE_COUNT][] = 
{
	"NUB", 
	"PRO"
};

stock char gC_PistolNames[PISTOL_COUNT][] = 
{
	"P2000 / USP-S", 
	"Glock-18", 
	"P250", 
	"Dual Berettas", 
	"Desert Eagle", 
	"CZ75-Auto", 
	"Five-SeveN", 
	"Tec-9", 
	"R8 Revolver", 
	"DISABLED" // Disabled option
};



// =========================  OTHER  ========================= //

stock const char gC_CoreOptionNames[OPTION_COUNT][] = 
{
	"mode", 
	"style", 
	"showplayers", 
	"showweapon", 
	"autorestart", 
	"slayonend", 
	"pistol", 
	"checkpointmessages", 
	"checkpointsounds", 
	"teleportsounds", 
	"errorsounds", 
	"jumpbeam", 
	"helpandtips"
};

stock char gC_ModeCVars[MODECVAR_COUNT][] = 
{
	"sv_accelerate", 
	"sv_friction", 
	"sv_airaccelerate", 
	"sv_ladder_scale_speed", 
	"sv_maxvelocity", 
	"sv_gravity", 
	"sv_enablebunnyhopping", 
	"sv_autobunnyhopping", 
	"sv_staminamax", 
	"sv_staminalandcost", 
	"sv_staminajumpcost", 
	"sv_staminarecoveryrate", 
	"sv_maxspeed", 
	"sv_wateraccelerate", 
	"sv_timebetweenducks", 
	"sv_accelerate_use_weapon_speed", 
	"sv_jump_impulse"
};



// =========================  FORWARDS  ========================= //

/**
 * Called when a player has been set up e.g. options, timer etc.
 *
 * @param client		Client index.
 * @noreturn
 */
forward void GOKZ_OnClientSetup(int client);

/**
 * Called when a player's option's value is changed.
 * Only called if client is in game.
 *
 * @param client		Client index.
 * @param option		Option name.
 * @param newValue		New value of the option.
 * @noreturn
 */
forward void GOKZ_OnOptionChanged(int client, const char[] option, any newValue);

/**
 * Called when a player starts their timer.
 *
 * @param client		Client index.
 * @param course    	Course number.
 * @return				Plugin_Handled or Plugin_Stop to block, Plugin_Continue to proceed.
 */
forward Action GOKZ_OnTimerStart(int client, int course);

/**
 * Called when a player has started their timer.
 *
 * @param client		Client index.
 * @param course    	Course number.
 * @noreturn
 */
forward void GOKZ_OnTimerStart_Post(int client, int course);

/**
 * Called when a player ends their timer.
 *
 * @param client			Client index.
 * @param course    		Course number.
 * @param time				Player's end time.
 * @param teleportsUsed		Number of teleports used by player.
 * @return					Plugin_Handled or Plugin_Stop to block, Plugin_Continue to proceed.
 */
forward Action GOKZ_OnTimerEnd(int client, int course, float time, int teleportsUsed);

/**
 * Called when a player has ended their timer.
 *
 * @param client			Client index.
 * @param course    		Course number.
 * @param time				Player's end time.
 * @param teleportsUsed		Number of teleports used by player.
 * @noreturn
 */
forward void GOKZ_OnTimerEnd_Post(int client, int course, float time, int teleportsUsed);

/**
 * Called when the end timer message is printed to chat.
 *
 * @param client			Client index.
 * @param course    		Course number.
 * @param time				Player's end time.
 * @param teleportsUsed		Number of teleports used by player.
 * @return					Plugin_Handled or Plugin_Stop to block, Plugin_Continue to proceed.
 */
forward Action GOKZ_OnTimerEndMessage(int client, int course, float time, int teleportsUsed);

/**
 * Called when a player's timer has been forcefully stopped.
 *
 * @param client		Client index.
 * @noreturn
 */
forward void GOKZ_OnTimerStopped(int client);

/**
 * Called when a player pauses.
 *
 * @param client		Client index.
 * @return				Plugin_Handled or Plugin_Stop to block, Plugin_Continue to proceed.
 */
forward Action GOKZ_OnPause(int client);

/**
 * Called when a player has paused.
 *
 * @param client		Client index.
 * @noreturn
 */
forward void GOKZ_OnPause_Post(int client);

/**
 * Called when a player resumes.
 *
 * @param client		Client index.
 * @return				Plugin_Handled or Plugin_Stop to block, Plugin_Continue to proceed.
 */
forward Action GOKZ_OnResume(int client);

/**
 * Called when a player has resumed.
 *
 * @param client		Client index.
 * @noreturn
 */
forward void GOKZ_OnResume_Post(int client);

/**
 * Called when a player makes a checkpoint.
 *
 * @param client		Client index.
 * @return				Plugin_Handled or Plugin_Stop to block, Plugin_Continue to proceed.
 */
forward Action GOKZ_OnMakeCheckpoint(int client);

/**
 * Called when a player has made a checkpoint.
 *
 * @param client		Client index.
 * @noreturn
 */
forward void GOKZ_OnMakeCheckpoint_Post(int client);

/**
 * Called when a player teleports to their checkpoint.
 *
 * @param client		Client index.
 * @return				Plugin_Handled or Plugin_Stop to block, Plugin_Continue to proceed.
 */
forward Action GOKZ_OnTeleportToCheckpoint(int client);

/**
 * Called when a player has teleported to their checkpoint.
 *
 * @param client		Client index.
 * @noreturn
 */
forward void GOKZ_OnTeleportToCheckpoint_Post(int client);

/**
 * Called when a player goes to a previous checkpoint.
 *
 * @param client		Client index.
 * @return				Plugin_Handled or Plugin_Stop to block, Plugin_Continue to proceed.
 */
forward Action GOKZ_OnPrevCheckpoint(int client);

/**
 * Called when a player has gone to a previous checkpoint.
 *
 * @param client		Client index.
 * @noreturn
 */
forward void GOKZ_OnPrevCheckpoint_Post(int client);

/**
 * Called when a player goes to a next checkpoint.
 *
 * @param client		Client index.
 * @return				Plugin_Handled or Plugin_Stop to block, Plugin_Continue to proceed.
 */
forward Action GOKZ_OnNextCheckpoint(int client);

/**
 * Called when a player has gone to a next checkpoint.
 *
 * @param client		Client index.
 * @noreturn
 */
forward void GOKZ_OnNextCheckpoint_Post(int client);

/**
 * Called when a player teleports to start.
 *
 * @param client		Client index.
 * @param customPos		Whether a custom start position is in use.
 * @return				Plugin_Handled or Plugin_Stop to block, Plugin_Continue to proceed.
 */
forward Action GOKZ_OnTeleportToStart(int client, bool customPos);

/**
 * Called when a player has teleported to start.
 *
 * @param client		Client index.
 * @param customPos		Whether a custom start position is in use.
 * @noreturn
 */
forward void GOKZ_OnTeleportToStart_Post(int client, bool customPos);

/**
 * Called when a player undoes a teleport.
 *
 * @param client		Client index.
 * @return				Plugin_Handled or Plugin_Stop to block, Plugin_Continue to proceed.
 */
forward Action GOKZ_OnUndoTeleport(int client);

/**
 * Called when a player has undone a teleport.
 *
 * @param client		Client index.
 * @noreturn
 */
forward void GOKZ_OnUndoTeleport_Post(int client);

/**
 * Called when a player has performed a counted teleport (teleport count went up)
 * i.e. a catch-all for teleport to checkpoint, teleport to start, undo teleport etc.
 *
 * @param client		Client index.
 * @noreturn
 */
forward void GOKZ_OnCountedTeleport_Post(int client);

/**
 * Called when player's begins a jump that is deemed valid.
 * A jump is deemed invalid if the player is teleported.
 *
 * @param client		Client index.
 * @param jumped		Whether player jumped.
 * @param ladderJump	Whether it was a ladder jump.
 * @noreturn
 */
forward void GOKZ_OnJumpValidated(int client, bool jumped, bool ladderJump);

/**
 * Called when player's current jump is invalidated.
 * A jump is deemed invalid if the player is teleported.
 *
 * @param client		Client index.
 * @noreturn
 */
forward void GOKZ_OnJumpInvalidated(int client);

/**
 * Called when a player has been switched to a team.
 *
 * @param client		Client index.
 * @noreturn
 */
forward void GOKZ_OnJoinTeam(int client, int team);

/**
 * Called the first time the player spawns in on a team.
 *
 * @param client		Client index.
 * @noreturn
 */
forward void GOKZ_OnFirstSpawn(int client);

/**
 * Called when a mode has been loaded.
 *
 * @param mode			Mode loaded.
 * @noreturn
 */
forward void GOKZ_OnModeLoaded(int mode);

/**
 * Called when a mode has been unloaded.
 *
 * @param mode			Mode unloaded.
 * @noreturn
 */
forward void GOKZ_OnModeUnloaded(int mode);

/**
 * Called when a plugin other than gokz-core calls a native 
 * that may affect the player's timer or teleport count in 
 * their favour e.g. GOKZ_StartTimer, GOKZ_EndTimer,
 * GOKZ_SetCurrentTime and GOKZ_SetTeleportCount.
 *
 * @param plugin		Handle of the calling plugin.
 * @return				Plugin_Handled or Plugin_Stop to block, Plugin_Continue to proceed.
 */
forward Action GOKZ_OnTimerNativeCalledExternally(Handle plugin);

/**
 * Called when a player's custom start position is set.
 *
 * @param client		Client index.
 * @param origin		New custom start position origin.
 * @param angles		New custom start position eye angles.
 * @noreturn
 */
forward void GOKZ_OnCustomStartPositionSet_Post(int client, const float origin[3], const float angles[3]);

/**
 * Called when a player's custom start position is cleared.
 *
 * @param client		Client index.
 * @noreturn
 */
forward void GOKZ_OnCustomStartPositionCleared_Post(int client);

/**
 * Called when the options menu has been created and 3rd 
 * party plugins can grab the handle or add categories.
 *
 * @param topMenu		Options top menu handle.
 * @noreturn
 */
forward void GOKZ_OnOptionsMenuCreated(TopMenu topMenu);

/**
 * Called when the options menu is ready to have items added.
 *
 * @param topMenu		Options top menu handle.
 * @noreturn
 */
forward void GOKZ_OnOptionsMenuReady(TopMenu topMenu);



// =========================  NATIVES  ========================= //

/**
 * Gets whether a mode is loaded.
 *
 * @param mode			Mode.
 * @return				Whether mode is loaded.
 */
native bool GOKZ_GetModeLoaded(int mode);

/**
 * Gets the version number of a loaded mode.
 *
 * @param mode			Mode.
 * @return				Version number of the mode, or -1 if not loaded.
 */
native int GOKZ_GetModeVersion(int mode);

/**
 * Sets whether a mode is loaded. To be used by mode plugins.
 *
 * @param mode			Mode.
 * @param loaded		Whether mode is loaded.
 * @param version		Version number of the mode.
 * @noreturn
 */
native void GOKZ_SetModeLoaded(int mode, bool loaded, int version = -1);

/**
 * Gets the total number of loaded modes.
 *
 * @return				Number of loaded modes.
 */
native int GOKZ_GetLoadedModeCount();

/**
 * Gets the Handle to the options top menu.
 *
 * @return				Handle to the options top menu, 
 *						or INVALID_HANDLE if not created yet.
 */
native TopMenu GOKZ_GetOptionsTopMenu();

/**
 * Prints a message to a client's chat, formatting colours and optionally 
 * adding the chat prefix. If using the chat prefix, specify a colour at 
 * the beginning of the message e.g. "{default}Hello!".
 *
 * @param client		Client index.
 * @param addPrefix		Whether to add the chat prefix.
 * @param format		Formatting rules.
 * @param any			Variable number of format parameters.
 * @noreturn
 */
native void GOKZ_PrintToChat(int client, bool addPrefix, const char[] format, any...);

/**
 * Starts the player's timer for a course on the current map.
 * This can be blocked by OnTimerNativeCalledExternally().
 *
 * @param client    	Client index.
 * @param course    	Course number.
 * @return				Whether native was allowed to proceed.
 */
native bool GOKZ_StartTimer(int client, int course);

/**
 * Ends the player's timer for a course on the current map.
 * This can be blocked by OnTimerNativeCalledExternally().
 *
 * @param client    	Client index.
 * @param course    	Course number.
 * @return				Whether native was allowed to proceed.
 */
native bool GOKZ_EndTimer(int client, int course);

/**
 * Forces the player's timer to stop. Intended for run invalidation.
 *
 * @param client    	Client index.
 * @param playSound		Whether to play the timer stop sound.
 * @return				Whether player's timer was stopped.
 */
native bool GOKZ_StopTimer(int client, bool playSound = true);

/**
 * Forces all players' timers to stop. Intended for run invalidation.
 *
 * @param playSound		Whether to play the timer stop sound.
 * @noreturn
 */
native void GOKZ_StopTimerAll(bool playSound = true);

/**
 * Gets whether client has been set up by GOKZ e.g. options, timer etc.
 *
 * @param client		Client index.
 * @return				Whether client has been set up.
 */
native bool GOKZ_IsClientSetUp(int client);

/**
 * Gets whether or not the player's timer is running i.e. isn't 'stopped'.
 *
 * @param client    	Client index.
 * @return				Whether player's timer is running.
 */
native bool GOKZ_GetTimerRunning(int client);

/**
 * Gets the course the player is currently running.
 *
 * @param client    	Client index.
 * @param course    	Course number.
 */
native bool GOKZ_GetCurrentCourse(int client);

/**
 * Gets whether the player is paused.
 *
 * @param client    	Client index.
 * @return				Whether player is paused.
 */
native bool GOKZ_GetPaused(int client);

/**
 * Gets the player's current run time.
 *
 * @param client    	Client index.
 * @return				Player's current run time.
 */
native float GOKZ_GetCurrentTime(int client);

/**
 * Gets the player's current run time.
 * This can be blocked by OnTimerNativeCalledExternally().
 *
 * @param client    	Client index.
 * @param time			Run time to set to.
 * @return				Whether native was allowed to proceed.
 */
native bool GOKZ_SetCurrentTime(int client, float time);

/**
 * Gets the player's current checkpoint count.
 *
 * @param client    	Client index.
 * @return				Player's current checkpoint count.
 */
native int GOKZ_GetCheckpointCount(int client);

/**
 * Sets the player's current checkpoint count.
 * This can be blocked by OnTimerNativeCalledExternally().
 *
 * @param client    	Client index.
 * @param cpCount		Checkpoint count to set to.
 * @return				Whether native was allowed to proceed.
 */
native int GOKZ_SetCheckpointCount(int client, int cpCount);

/**
 * Gets the player's current teleport count.
 *
 * @param client    	Client index.
 * @return				Player's current teleport count.
 */
native int GOKZ_GetTeleportCount(int client);

/**
 * Sets the player's current teleport count.
 * This can be blocked by OnTimerNativeCalledExternally().
 *
 * @param client    	Client index.
 * @param tpCount		Teleport count to set to.
 * @return				Whether native was allowed to proceed.
 */
native bool GOKZ_SetTeleportCount(int client, int tpCount);

/**
 * Teleports the player to start, or respawns them.
 *
 * @param client    	Client index.
 * @noreturn
 */
native void GOKZ_TeleportToStart(int client);

/**
 * Gets whether player has a start position they can
 * teleport to, whether it is custom or not.
 * 
 *
 * @param client    	Client index.
 * @return				Whether player has a start position.
 */
native bool GOKZ_GetHasStartPosition(int client);

/**
 * Set a new checkpoint at the player's current position.
 *
 * @param client    	Client index.
 * @noreturn
 */
native void GOKZ_MakeCheckpoint(int client);

/**
 * Teleports the player to their last checkpoint.
 *
 * @param client    	Client index.
 * @noreturn
 */
native void GOKZ_TeleportToCheckpoint(int client);

/**
 * Gets whether the player can teleport to their checkpoint
 * e.g. will return false if player has no checkpoints.
 *
 * @param client		Client index.
 * @return				Whether player can teleport to checkpoint.
 */
native bool GOKZ_GetCanTeleportToCheckpoint(int client);

/**
 * Teleport the player back to a previous checkpoint.
 *
 * @param client    	Client index.
 * @noreturn
 */
native void GOKZ_PrevCheckpoint(int client);

/**
 * Gets whether the player can go to their previous checkpoint
 * e.g. will return false if player has no checkpoints.
 *
 * @param client		Client index.
 * @return				Whether player can go to previous checkpoint.
 */
native bool GOKZ_GetCanPrevCheckpoint(int client);

/**
 * Teleport the player to a more recent checkpoint.
 *
 * @param client    	Client index.
 * @noreturn
 */
native void GOKZ_NextCheckpoint(int client);

/**
 * Gets whether the player can go to their next checkpoint
 * e.g. will return false if player has no checkpoints.
 *
 * @param client		Client index.
 * @return				Whether player can go to next checkpoint.
 */
native bool GOKZ_GetCanNextCheckpoint(int client);

/**
 * Teleport the player to where they last teleported from.
 *
 * @param client    	Client index.
 * @noreturn
 */
native void GOKZ_UndoTeleport(int client);

/**
 * Gets whether the player can undo their teleport
 * e.g. will return false if teleport was from midair.
 *
 * @param client		Client index.
 * @return				Whether player can undo teleport.
 */
native bool GOKZ_GetCanUndoTeleport(int client);

/**
 * Pause the player's timer and freeze them.
 *
 * @param client    	Client index.
 * @noreturn
 */
native void GOKZ_Pause(int client);

/**
 * Resumes the player's timer and unfreezes them.
 *
 * @param client    	Client index.
 * @noreturn
 */
native void GOKZ_Resume(int client);

/**
 * Toggles the paused state of the player.
 *
 * @param client    	Client index.
 * @noreturn
 */
native void GOKZ_TogglePause(int client);

/**
 * Plays the error sound to the client if they have the option enabled.
 *
 * @param client		Client index.
 * @noreturn
 */
native void GOKZ_PlayErrorSound(int client);

/**
 * Registers an option with gokz-core, which uses clientprefs to
 * keep track of the option's value and to save it to a database.
 * This also effectively provides natives and forwards for other 
 * plugins to access any options that have been registered.
 *
 * @param name			Option name.
 * @param description	Option description.
 * @param type			Type to treat the option value as.
 * @param defaultValue	Default value of option.
 * @param minValue		Minimum value of option.
 * @param maxValue		Maximum value of option.
 * @return				Whether registration was successful.
 */
native bool GOKZ_RegisterOption(const char[] name, const char[] description, OptionType type, any defaultValue, any minValue, any maxValue);

/**
 * Gets a property of a registered option. If used outside of
 * gokz-core to get the cookie, a clone of its Handle is returned.
 *
 * @param option		Option name.
 * @param prop			Option property to get.
 * @return				Value of property, or -1 (int) if option isn't registered.
 */
native any GOKZ_GetOptionProp(const char[] option, OptionProp prop);

/**
 * Sets a property of a registered option. For safety and simplicity,
 * the cookie property is read-only and will fail to be set.
 *
 * @param option		Option name.
 * @param prop			Option property to set.
 * @param value			Value to set the property to.
 * @return				Whether option property was successfully set.
 */
native bool GOKZ_SetOptionProp(const char[] option, OptionProp prop, any value);

/**
 * Gets the current value of a player's option.
 *
 * @param client		Client index.
 * @param option		Option name.
 * @return				Current value of option, or -1 (int) if option isn't registered.
 */
native any GOKZ_GetOption(int client, const char[] option);

/**
 * Sets the player's option's value. Fails if option doesn't exist,
 * or if desired value is outside the registered value range.
 *
 * @param client		Client index.
 * @param option		Option name.
 * @param value			New option value.
 * @return				Whether option was successfully set.
 */
native bool GOKZ_SetOption(int client, const char[] option, any value);

/**
 * Gets whether player's last takeoff was a perfect bunnyhop as adjusted by GOKZ.
 *
 * @param client		Client index.
 * @return				Whether player's last takeoff was a GOKZ perfect b-hop.
 */
native bool GOKZ_GetHitPerf(int client);

/**
 * Sets whether player's last takeoff was a perfect bunnyhop as adjusted by GOKZ.
 * Intended to be called by GOKZ mode plugins only.
 *
 * @param client		Client index.
 * @param hitPerf		Whether player's last takeoff was a GOKZ perfect b-hop.
 * @noreturn		
 */
native void GOKZ_SetHitPerf(int client, bool hitPerf);

/**
 * Gets the player's horizontal speed at the time of their last takeoff as recorded by GOKZ.
 *
 * @param client		Client index.
 * @return				Player's last takeoff speed as recorded by GOKZ.
 */
native float GOKZ_GetTakeoffSpeed(int client);

/**
 * Sets the player's recorded horizontal speed at the time of their last takeoff.
 * Intended to be called by GOKZ mode plugins only.
 *
 * @param client		Client index.
 * @param takeoffSpeed	Player's last takeoff speed as recorded by GOKZ.
 * @noreturn		
 */
native void GOKZ_SetTakeoffSpeed(int client, float takeoffSpeed);

/**
 * Gets whether the player's current or last jump/airtime is valid.
 * A jump is deemed invalid if the player is teleported.
 *
 * @param client		Client index.
 * @return				Validity of player's current or last jump.
 */
native bool GOKZ_GetValidJump(int client);

/**
 * Has the client switch to a team via GOKZ Core.
 *
 * @param client		Client index.
 * @param team			Which team to switch to.
 * @noreturn
 */
native void GOKZ_JoinTeam(int client, int team);



// =========================  STOCKS  ========================= //

/**
 * Prints a message to all clients' chat, formatting colours and optionally 
 * adding the chat prefix. If using the chat prefix, specify a colour at 
 * the beginning of the message e.g. "{default}Hello!".
 *
 * @param client		Client index.
 * @param addPrefix		Whether to add the chat prefix.
 * @param format		Formatting rules.
 * @param any			Variable number of format parameters.
 * @noreturn
 */
stock void GOKZ_PrintToChatAll(bool addPrefix, const char[] format, any...)
{
	char buffer[1024];
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			SetGlobalTransTarget(client);
			VFormat(buffer, sizeof(buffer), format, 3);
			GOKZ_PrintToChat(client, addPrefix, buffer);
		}
	}
}

/**
 * Prints a chat message to those spectating the client, formatting colours 
 * and optionally adding the chat prefix. If using the chat prefix, specify 
 * a colour at the beginning of the message e.g. "{default}Hello!".
 *
 * @param client		Client index.
 * @param addPrefix		Whether to add the chat prefix.
 * @param format		Formatting rules.
 * @param any			Variable number of format parameters.
 * @noreturn
 */
stock void GOKZ_PrintToChatSpectators(int client, bool addPrefix, const char[] format, any...)
{
	char buffer[1024];
	for (int target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target) && GetObserverTarget(target) == client)
		{
			SetGlobalTransTarget(target);
			VFormat(buffer, sizeof(buffer), format, 4);
			GOKZ_PrintToChat(target, addPrefix, buffer);
		}
	}
}

/**
 * Gets the time type given a teleport count.
 *
 * @param teleports		Teleport count.
 * @return				Time type.
 */
stock int GOKZ_GetTimeType(int teleportCount)
{
	if (teleportCount == 0)
	{
		return TimeType_Pro;
	}
	return TimeType_Nub;
}

/**
 * Gets the player's current time type.
 *
 * @param client		Client index.
 * @return				Player's current time type.
 */
stock int GOKZ_GetCurrentTimeType(int client)
{
	return GOKZ_GetTimeType(GOKZ_GetTeleportCount(client));
}

/**
 * Clears and populates a menu with an item for each mode
 * in order of the mode enumeration. Highlights the client's
 * selected mode with an asterisk.
 *
 * @param client				Client index to check selected mode.
 * @param menu					Menu to populate items with.
 * @param disableUnloadedModes	Draw items for unloaded modes as disabled.
 * @noreturn
 */
stock void GOKZ_MenuAddModeItems(int client, Menu menu, bool disableUnloadedModes)
{
	int selectedMode = GOKZ_GetCoreOption(client, Option_Mode);
	char display[32];
	
	menu.RemoveAllItems();
	
	for (int mode = 0; mode < MODE_COUNT; mode++)
	{
		FormatEx(display, sizeof(display), "%s", gC_ModeNames[mode]);
		// Add asterisk to selected mode
		if (mode == selectedMode)
		{
			Format(display, sizeof(display), "%s*", display);
		}
		
		if (GOKZ_GetModeLoaded(mode))
		{
			menu.AddItem("", display, ITEMDRAW_DEFAULT);
		}
		else
		{
			menu.AddItem("", display, ITEMDRAW_DISABLED);
		}
	}
}

/**
 * Increment an (integer-type) option's value.
 * Loops back to min. value if max. value is exceeded.
 *
 * @param client		Client index.
 * @param option		Option name.
 * @return				Whether option was successfully set.
 */
stock bool GOKZ_CycleOption(int client, const char[] option)
{
	int maxValue = GOKZ_GetOptionProp(option, OptionProp_MaxValue);
	if (maxValue == -1)
	{
		return false;
	}
	
	int newValue = GOKZ_GetOption(client, option) + 1;
	if (newValue > GOKZ_GetOptionProp(option, OptionProp_MaxValue))
	{
		newValue = GOKZ_GetOptionProp(option, OptionProp_MinValue);
	}
	return GOKZ_SetOption(client, option, newValue);
}

/**
 * Returns whether an option is a gokz-core option.
 *
 * @param option		Option name.
 * @param optionEnum	Variable to store enumerated gokz-core option (if it is one).
 * @return				Whether option is a gokz-core option.
 */
stock bool GOKZ_IsCoreOption(const char[] option, Option &optionEnum = OPTION_INVALID)
{
	for (Option i; i < OPTION_COUNT; i++)
	{
		if (StrEqual(option, gC_CoreOptionNames[i]))
		{
			optionEnum = i;
			return true;
		}
	}
	return false;
}

/**
 * Gets a property of a gokz-core option.
 *
 * @param coreOption	gokz-core option.
 * @param prop			Option property to get.
 * @return				Value of property, or -1 if option isn't registered.
 */
stock any GOKZ_GetCoreOptionProp(Option option, OptionProp prop)
{
	return GOKZ_GetOptionProp(gC_CoreOptionNames[option], prop);
}

/**
 * Gets the current value of a player's gokz-core option.
 *
 * @param client		Client index.
 * @param option		gokz-core option.
 * @return				Current value of option.
 */
stock any GOKZ_GetCoreOption(int client, Option option)
{
	return GOKZ_GetOption(client, gC_CoreOptionNames[option]);
}

/**
 * Sets the player's gokz-core option's value.
 *
 * @param client		Client index.
 * @param option		gokz-core option.
 * @param value			New option value.
 * @return				Whether option was successfully set.
 */
stock bool GOKZ_SetCoreOption(int client, Option option, any value)
{
	return GOKZ_SetOption(client, gC_CoreOptionNames[option], value);
}

/**
 * Increment an integer-type gokz-core option's value.
 * Loops back to '0' if max value is exceeded.
 *
 * @param client		Client index.
 * @param option		gokz-core option.
 * @return				Whether option was successfully set.
 */
stock bool GOKZ_CycleCoreOption(int client, Option option)
{
	return GOKZ_CycleOption(client, gC_CoreOptionNames[option]);
}



// =========================  DEPENDENCY  ========================= //

public SharedPlugin __pl_gokz_core = 
{
	name = "gokz-core", 
	file = "gokz-core.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_gokz_core_SetNTVOptional()
{
	MarkNativeAsOptional("GOKZ_GetModeLoaded");
	MarkNativeAsOptional("GOKZ_GetModeVersion");
	MarkNativeAsOptional("GOKZ_SetModeLoaded");
	MarkNativeAsOptional("GOKZ_GetLoadedModeCount");
	MarkNativeAsOptional("GOKZ_PrintToChat");
	MarkNativeAsOptional("GOKZ_GetOptionsTopMenu");
	
	MarkNativeAsOptional("GOKZ_StartTimer");
	MarkNativeAsOptional("GOKZ_EndTimer");
	MarkNativeAsOptional("GOKZ_StopTimer");
	MarkNativeAsOptional("GOKZ_StopTimerAll");
	MarkNativeAsOptional("GOKZ_TeleportToStart");
	MarkNativeAsOptional("GOKZ_GetHasStartPosition");
	MarkNativeAsOptional("GOKZ_MakeCheckpoint");
	MarkNativeAsOptional("GOKZ_TeleportToCheckpoint");
	MarkNativeAsOptional("GOKZ_GetCanTeleportToCheckpoint");
	MarkNativeAsOptional("GOKZ_PrevCheckpoint");
	MarkNativeAsOptional("GOKZ_GetCanPrevCheckpoint");
	MarkNativeAsOptional("GOKZ_NextCheckpoint");
	MarkNativeAsOptional("GOKZ_GetCanNextCheckpoint");
	MarkNativeAsOptional("GOKZ_UndoTeleport");
	MarkNativeAsOptional("GOKZ_GetCanUndoTeleport");
	MarkNativeAsOptional("GOKZ_Pause");
	MarkNativeAsOptional("GOKZ_Resume");
	MarkNativeAsOptional("GOKZ_TogglePause");
	MarkNativeAsOptional("GOKZ_PlayErrorSound");
	
	MarkNativeAsOptional("GOKZ_IsClientSetUp");
	MarkNativeAsOptional("GOKZ_GetTimerRunning");
	MarkNativeAsOptional("GOKZ_GetCurrentCourse");
	MarkNativeAsOptional("GOKZ_GetPaused");
	MarkNativeAsOptional("GOKZ_GetCurrentTime");
	MarkNativeAsOptional("GOKZ_SetCurrentTime");
	MarkNativeAsOptional("GOKZ_GetCheckpointCount");
	MarkNativeAsOptional("GOKZ_SetCheckpointCount");
	MarkNativeAsOptional("GOKZ_GetTeleportCount");
	MarkNativeAsOptional("GOKZ_SetTeleportCount");
	MarkNativeAsOptional("GOKZ_RegisterOption");
	MarkNativeAsOptional("GOKZ_GetOptionProp");
	MarkNativeAsOptional("GOKZ_SetOptionProp");
	MarkNativeAsOptional("GOKZ_GetOption");
	MarkNativeAsOptional("GOKZ_SetOption");
	MarkNativeAsOptional("GOKZ_GetHitPerf");
	MarkNativeAsOptional("GOKZ_SetHitPerf");
	MarkNativeAsOptional("GOKZ_GetTakeoffSpeed");
	MarkNativeAsOptional("GOKZ_SetTakeoffSpeed");
	MarkNativeAsOptional("GOKZ_GetValidJump");
	MarkNativeAsOptional("GOKZ_JoinTeam");
}
#endif