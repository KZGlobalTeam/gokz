/*
	gokz-core Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_core_included_
#endinput
#endif
#define _gokz_core_included_

#include <cstrike>
#include <regex>
#include <topmenus>

#include <gokz>



// =====[ ENUMS ]=====

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

enum StartPositionType:
{
	StartPositionType_Spawn, 
	StartPositionType_Custom, 
	StartPositionType_MapButton, 
	StartPositionType_MapStart, 
	STARTPOSITIONTYPE_COUNT
};

enum CourseTimerType:
{
	CourseTimerType_None,
	CourseTimerType_Default,
	CourseTimerType_Button,
	CourseTimerType_ZoneLegacy,
	CourseTimerType_ZoneNew,
	CourseTimerType_COUNT
};

enum OptionProp:
{
	OptionProp_Cookie = 0, 
	OptionProp_Type, 
	OptionProp_DefaultValue, 
	OptionProp_MinValue, 
	OptionProp_MaxValue, 
	OPTIONPROP_COUNT
};

enum OptionType:
{
	OptionType_Int = 0, 
	OptionType_Float
};

enum Option:
{
	OPTION_INVALID = -1, 
	Option_Mode, 
	Option_Style,
	Option_CheckpointMessages,
	Option_CheckpointSounds, 
	Option_TeleportSounds, 
	Option_ErrorSounds, 
	Option_VirtualButtonIndicators, 
	Option_TimerButtonZoneType,
	Option_ButtonThroughPlayers,
	Option_Safeguard,
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
	VirtualButtonIndicators_Disabled = 0, 
	VirtualButtonIndicators_Enabled, 
	VIRTUALBUTTONINDICATORS_COUNT
};

enum
{
	TimerButtonZoneType_BothButtons = 0,
	TimerButtonZoneType_EndZone,
	TimerButtonZoneType_BothZones,
	TIMERBUTTONZONETYPE_COUNT
};

enum
{
	ButtonThroughPlayers_Disabled = 0,
	ButtonThroughPlayers_Enabled,
	BUTTONTHROUGHPLAYERS_COUNT
};

enum
{
	Safeguard_Disabled = 0,
	Safeguard_EnabledNUB,
	Safeguard_EnabledPRO,
	SAFEGUARD_COUNT
};

enum
{
	ModeCVar_Accelerate = 0, 
	ModeCVar_AccelerateUseWeaponSpeed, 
	ModeCVar_AirAccelerate, 
	ModeCVar_AirMaxWishSpeed, 
	ModeCVar_EnableBunnyhopping, 
	ModeCVar_Friction, 
	ModeCVar_Gravity, 
	ModeCVar_JumpImpulse, 
	ModeCVar_LadderScaleSpeed, 
	ModeCVar_LedgeMantleHelper, 
	ModeCVar_MaxSpeed, 
	ModeCVar_MaxVelocity, 
	ModeCVar_StaminaJumpCost, 
	ModeCVar_StaminaLandCost, 
	ModeCVar_StaminaMax, 
	ModeCVar_StaminaRecoveryRate, 
	ModeCVar_StandableNormal, 
	ModeCVar_TimeBetweenDucks, 
	ModeCVar_WalkableNormal, 
	ModeCVar_WaterAccelerate, 
	MoveCVar_WaterMoveSpeedMultiplier, 
	MoveCVar_WaterSwimMode, 
	MoveCVar_WeaponEncumbrancePerItem, 
	ModeCVar_WeaponEncumbranceScale, 
	MODECVAR_COUNT
};

// NOTE: gokz-core/map/entlump.sp
enum EntlumpTokenType
{
	EntlumpTokenType_OpenBrace,  // {
	EntlumpTokenType_CloseBrace, // }
	EntlumpTokenType_Identifier, // everything that's inside quotations
	EntlumpTokenType_Unknown,
	EntlumpTokenType_EndOfStream
};

// NOTE: gokz-core/map/triggers.sp
// NOTE: corresponds to climb_teleport_type in kz_mapping_api.fgd
enum TeleportType
{
	TeleportType_Invalid = -1,
	TeleportType_Normal,
	TeleportType_MultiBhop,
	TeleportType_SingleBhop,
	TeleportType_SequentialBhop,
	TELEPORTTYPE_COUNT
};

enum TriggerType
{
	TriggerType_Invalid = 0,
	TriggerType_Teleport,
	TriggerType_Antibhop
};



// =====[ CONSTANTS ]=====

#define GOKZ_CHECKPOINT_VERSION 2
#define GOKZ_MAX_CHECKPOINTS 2048
#define GOKZ_MAX_COURSES 100

#define GOKZ_BHOP_NO_CHECKPOINT_TIME 0.15
#define GOKZ_MULT_NO_CHECKPOINT_TIME 0.11
#define GOKZ_LADDER_NO_CHECKPOINT_TIME 1.5
#define GOKZ_PAUSE_COOLDOWN 1.0
#define GOKZ_TIMER_START_NO_TELEPORT_TICKS 4
#define GOKZ_TIMER_START_GROUND_TICKS 4
#define GOKZ_TIMER_START_NOCLIP_TICKS 4
#define GOKZ_JUMPSTATS_NOCLIP_RESET_TICKS 4
#define GOKZ_TIMER_SOUND_COOLDOWN 0.15
#define GOKZ_VIRTUAL_BUTTON_USE_DETECTION_TIME 2.0
#define GOKZ_TURNBIND_COOLDOWN 0.3

#define GOKZ_MAPPING_API_VERSION_NONE 0 // the map doesn't have a mapping api version
#define GOKZ_MAPPING_API_VERSION 1

#define GOKZ_ANTI_BHOP_TRIGGER_DEFAULT_DELAY 0.2
#define GOKZ_TELEPORT_TRIGGER_DEFAULT_TYPE TeleportType_Normal
#define GOKZ_TELEPORT_TRIGGER_DEFAULT_DELAY 0.0
#define GOKZ_TELEPORT_TRIGGER_DEFAULT_USE_DEST_ANGLES true
#define GOKZ_TELEPORT_TRIGGER_DEFAULT_RESET_SPEED true
#define GOKZ_TELEPORT_TRIGGER_DEFAULT_RELATIVE_DESTINATION false
#define GOKZ_TELEPORT_TRIGGER_DEFAULT_REORIENT_PLAYER false
#define GOKZ_TELEPORT_TRIGGER_BHOP_MIN_DELAY 0.08

#define GOKZ_SOUND_CHECKPOINT "buttons/blip1.wav"
#define GOKZ_SOUND_TELEPORT "buttons/blip1.wav"
#define GOKZ_SOUND_TIMER_STOP "buttons/button18.wav"

#define GOKZ_START_NAME "climb_start"
#define GOKZ_BONUS_START_NAME_REGEX "^climb_bonus(\\d+)_start$"
#define GOKZ_BONUS_END_NAME_REGEX "^climb_bonus(\\d+)_end$"

#define GOKZ_START_BUTTON_NAME "climb_startbutton"
#define GOKZ_END_BUTTON_NAME "climb_endbutton"
#define GOKZ_BONUS_START_BUTTON_NAME_REGEX "^climb_bonus(\\d+)_startbutton$"
#define GOKZ_BONUS_END_BUTTON_NAME_REGEX "^climb_bonus(\\d+)_endbutton$"
#define GOKZ_ANTI_BHOP_TRIGGER_NAME "climb_anti_bhop"
#define GOKZ_ANTI_CP_TRIGGER_NAME "climb_anti_checkpoint"
#define GOKZ_ANTI_PAUSE_TRIGGER_NAME "climb_anti_pause"
#define GOKZ_ANTI_JUMPSTAT_TRIGGER_NAME "climb_anti_jumpstat"
#define GOKZ_BHOP_RESET_TRIGGER_NAME "climb_bhop_reset"
#define GOKZ_TELEPORT_TRIGGER_NAME "climb_teleport"

#define GOKZ_START_ZONE_NAME "climb_startzone"
#define GOKZ_END_ZONE_NAME "climb_endzone"
#define GOKZ_BONUS_START_ZONE_NAME_REGEX "^climb_bonus(\\d+)_startzone$"
#define GOKZ_BONUS_END_ZONE_NAME_REGEX "^climb_bonus(\\d+)_endzone$"

#define GOKZ_CFG_SERVER "sourcemod/gokz/gokz.cfg"
#define GOKZ_CFG_OPTIONS "cfg/sourcemod/gokz/options.cfg"
#define GOKZ_CFG_OPTIONS_SORTING "cfg/sourcemod/gokz/options_menu_sorting.cfg"
#define GOKZ_CFG_OPTIONS_ROOT "Options"
#define GOKZ_CFG_OPTIONS_DESCRIPTION "description"
#define GOKZ_CFG_OPTIONS_DEFAULT "default"

#define GOKZ_OPTION_MAX_NAME_LENGTH 30
#define GOKZ_OPTION_MAX_DESC_LENGTH 255
#define GENERAL_OPTION_CATEGORY "General"

// TODO: where do i put the defines?
#define GOKZ_BSP_HEADER_IDENTIFIER (('P' << 24) | ('S' << 16) | ('B' << 8) | 'V')
#define GOKZ_ENTLUMP_MAX_KEY 32
#define GOKZ_ENTLUMP_MAX_VALUE 1024

#define GOKZ_MAX_MAPTRIGGERS_ERROR_LENGTH 256

#define CHAR_ESCAPE view_as<char>(27)

#define GOKZ_SAFEGUARD_RESTART_MIN_DELAY 0.6
#define GOKZ_SAFEGUARD_RESTART_MAX_DELAY 5.0

// Prevents the player from retouching a trigger too often.
#define GOKZ_MAX_RETOUCH_TRIGGER_COUNT 4

stock char gC_TimeTypeNames[TIMETYPE_COUNT][] = 
{
	"NUB", 
	"PRO"
};

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

stock char gC_ModeKeys[MODE_COUNT][] = 
{
	"vanilla", 
	"simplekz", 
	"kztimer"
};

stock float gF_ModeVirtualButtonRanges[MODE_COUNT] = 
{
	0.0, 
	32.0, 
	70.0
};

stock char gC_ModeStartSounds[MODE_COUNT][] = 
{
	"common/wpn_select.wav", 
	"buttons/button9.wav", 
	"buttons/button3.wav"
};

stock char gC_ModeEndSounds[MODE_COUNT][] = 
{
	"common/wpn_select.wav", 
	"buttons/bell1.wav", 
	"buttons/button3.wav"
};

stock char gC_ModeFalseEndSounds[MODE_COUNT][] = 
{
	"common/wpn_select.wav", 
	"buttons/button11.wav", 
	"buttons/button2.wav"
};

stock char gC_StyleNames[STYLE_COUNT][] = 
{
	"Normal"
};

stock char gC_StyleNamesShort[STYLE_COUNT][] = 
{
	"NRM"
};

stock char gC_CoreOptionNames[OPTION_COUNT][] = 
{
	"GOKZ - Mode", 
	"GOKZ - Style", 
	"GOKZ - Checkpoint Messages", 
	"GOKZ - Checkpoint Sounds", 
	"GOKZ - Teleport Sounds", 
	"GOKZ - Error Sounds", 
	"GOKZ - VB Indicators",
	"GOKZ - Timer Button Zone Type",
	"GOKZ - Button Through Players",
	"GOKZ - Safeguard"
};

stock char gC_CoreOptionDescriptions[OPTION_COUNT][] = 
{
	"Movement Mode - 0 = Vanilla, 1 = SimpleKZ, 2 = KZTimer", 
	"Movement Style - 0 = Normal", 
	"Checkpoint Messages - 0 = Disabled, 1 = Enabled", 
	"Checkpoint Sounds - 0 = Disabled, 1 = Enabled", 
	"Teleport Sounds - 0 = Disabled, 1 = Enabled", 
	"Error Sounds - 0 = Disabled, 1 = Enabled", 
	"Virtual Button Indicators - 0 = Disabled, 1 = Enabled",
	"Timer Button Zone Type - 0 = Both buttons, 1 = Only end zone, 2 = Both zones",
	"Button Through Players - 0 = Disabled, 1 = Enabled",
	"Safeguard - 0 = Disabled, 1 = Enabled (NUB), 2 = Enabled (PRO)"
};

stock char gC_CoreOptionPhrases[OPTION_COUNT][] = 
{
	"Options Menu - Mode", 
	"Options Menu - Style", 
	"Options Menu - Checkpoint Messages", 
	"Options Menu - Checkpoint Sounds", 
	"Options Menu - Teleport Sounds", 
	"Options Menu - Error Sounds", 
	"Options Menu - Virtual Button Indicators",
	"Options Menu - Timer Button Zone Type",
	"Options Menu - Button Through Players",
	"Options Menu - Safeguard"
};

stock char gC_TimerButtonZoneTypePhrases[TIMERBUTTONZONETYPE_COUNT][] = 
{
	"Timer Button Zone Type - Both Buttons",
	"Timer Button Zone Type - Only End Zone",
	"Timer Button Zone Type - Both Zones"
};

stock char gC_SafeGuardPhrases[SAFEGUARD_COUNT][] =
{
	"Options Menu - Disabled",
	"Safeguard - Enabled NUB",
	"Safeguard - Enabled PRO"
}

stock int gI_CoreOptionCounts[OPTION_COUNT] = 
{
	MODE_COUNT, 
	STYLE_COUNT, 
	CHECKPOINTMESSAGES_COUNT, 
	CHECKPOINTSOUNDS_COUNT, 
	TELEPORTSOUNDS_COUNT, 
	ERRORSOUNDS_COUNT, 
	VIRTUALBUTTONINDICATORS_COUNT,
	TIMERBUTTONZONETYPE_COUNT,
	BUTTONTHROUGHPLAYERS_COUNT,
	SAFEGUARD_COUNT
};

stock int gI_CoreOptionDefaults[OPTION_COUNT] = 
{
	Mode_KZTimer, 
	Style_Normal, 
	CheckpointMessages_Disabled, 
	CheckpointSounds_Enabled, 
	TeleportSounds_Disabled, 
	ErrorSounds_Enabled, 
	VirtualButtonIndicators_Disabled,
	TimerButtonZoneType_BothButtons,
	ButtonThroughPlayers_Enabled,
	Safeguard_Disabled
};

stock char gC_ModeCVars[MODECVAR_COUNT][] = 
{
	"sv_accelerate", 
	"sv_accelerate_use_weapon_speed", 
	"sv_airaccelerate", 
	"sv_air_max_wishspeed", 
	"sv_enablebunnyhopping", 
	"sv_friction", 
	"sv_gravity", 
	"sv_jump_impulse", 
	"sv_ladder_scale_speed", 
	"sv_ledge_mantle_helper", 
	"sv_maxspeed", 
	"sv_maxvelocity", 
	"sv_staminajumpcost", 
	"sv_staminalandcost", 
	"sv_staminamax", 
	"sv_staminarecoveryrate", 
	"sv_standable_normal", 
	"sv_timebetweenducks", 
	"sv_walkable_normal", 
	"sv_wateraccelerate", 
	"sv_water_movespeed_multiplier", 
	"sv_water_swim_mode", 
	"sv_weapon_encumbrance_per_item", 
	"sv_weapon_encumbrance_scale"
};


// =====[ STRUCTS ]=====

enum struct Checkpoint
{
	float origin[3];
	float angles[3];
	float ladderNormal[3];
	bool onLadder;
	int groundEnt;

	void Create(int client)
	{
		Movement_GetOrigin(client, this.origin);
		Movement_GetEyeAngles(client, this.angles);
		GetEntPropVector(client, Prop_Send, "m_vecLadderNormal", this.ladderNormal);
		this.onLadder = Movement_GetMovetype(client) == MOVETYPE_LADDER;
		this.groundEnt = GetEntPropEnt(client, Prop_Data, "m_hGroundEntity");
	}
}

enum struct UndoTeleportData
{
	float tempOrigin[3];
	float tempAngles[3];
	float origin[3];
	float angles[3];
	// Undo TP properties
	bool lastTeleportOnGround;
	bool lastTeleportInBhopTrigger;
	bool lastTeleportInAntiCpTrigger;
	
	void Init(int client, bool lastTeleportInBhopTrigger, bool lastTeleportOnGround, bool lastTeleportInAntiCpTrigger)
	{
		Movement_GetOrigin(client, this.tempOrigin);
		Movement_GetEyeAngles(client, this.tempAngles);
		this.lastTeleportInBhopTrigger = lastTeleportInBhopTrigger;
		this.lastTeleportOnGround = lastTeleportOnGround;
		this.lastTeleportInAntiCpTrigger = lastTeleportInAntiCpTrigger;
	}
	
	void Update()
	{
		this.origin = this.tempOrigin;
		this.angles = this.tempAngles;
	}
}


// NOTE: gokz-core/map/entlump.sp
enum struct EntlumpToken
{
	EntlumpTokenType type;
	char string[GOKZ_ENTLUMP_MAX_VALUE];
}

// NOTE: gokz-core/map/triggers.sp
enum struct AntiBhopTrigger
{
	int entRef;
	int hammerID;
	float time;
}

enum struct TeleportTrigger
{
	int hammerID;
	TeleportType type;
	float delay;
	char tpDestination[256];
	bool useDestAngles;
	bool resetSpeed;
	bool relativeDestination;
	bool reorientPlayer;
}

enum struct TouchedTrigger
{
	TriggerType triggerType;
	int entRef; // entref of one of the TeleportTriggers
	int startTouchTick; // tick where the player touched the trigger
	int groundTouchTick; // tick where the player touched the ground
}

// Legacy triggers that activate timer buttons.
enum struct TimerButtonTrigger
{
	int hammerID;
	int course;
	bool isStartTimer;
}

// =====[ FORWARDS ]=====

/**
 * Called when a player's options values are loaded from clientprefs.
 *
 * @param client		Client index.
 */
forward void GOKZ_OnOptionsLoaded(int client);

/**
 * Called when a player's option's value is changed.
 * Only called if client is in game.
 *
 * @param client		Client index.
 * @param option		Option name.
 * @param newValue		New value of the option.
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
 */
forward void GOKZ_OnNextCheckpoint_Post(int client);

/**
 * Called when a player teleports to start.
 *
 * @param client		Client index.
 * @param course		Course index.
 * @return				Plugin_Handled or Plugin_Stop to block, Plugin_Continue to proceed.
 */
forward Action GOKZ_OnTeleportToStart(int client, int course);

/**
 * Called when a player has teleported to start.
 *
 * @param client		Client index.
 * @param course		Course index.
 */
forward void GOKZ_OnTeleportToStart_Post(int client, int course);

/**
 * Called when a player teleports to end.
 *
 * @param client		Client index.
 * @param course		Course index.
 * @return				Plugin_Handled or Plugin_Stop to block, Plugin_Continue to proceed.
 */
forward Action GOKZ_OnTeleportToEnd(int client, int course);

/**
 * Called when a player has teleported to end.
 *
 * @param client		Client index.
 * @param course		Course index.
 */
forward void GOKZ_OnTeleportToEnd_Post(int client, int course);

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
 */
forward void GOKZ_OnUndoTeleport_Post(int client);

/**
 * Called when a player has performed a counted teleport (teleport count went up)
 * i.e. a catch-all for teleport to checkpoint, teleport to start, undo teleport etc.
 *
 * @param client		Client index.
 */
forward void GOKZ_OnCountedTeleport_Post(int client);

/**
 * Called when a player's start position is set.
 *
 * @param client		Client index.
 * @param type			Start position type.
 * @param origin		Start position origin.
 * @param angles		Start position eye angles.
 */
forward void GOKZ_OnStartPositionSet_Post(int client, StartPositionType type, const float origin[3], const float angles[3]);

/**
 * Called when player's begins a jump that is deemed valid.
 * A jump is deemed invalid if a player is teleported.
 *
 * @param client		Client index.
 * @param jumped		Whether player jumped.
 * @param ladderJump	Whether it was a ladder jump.
 * @param jumpbug		Whether player performed a jumpbug.
 */
forward void GOKZ_OnJumpValidated(int client, bool jumped, bool ladderJump, bool jumpbug);

/**
 * Called when player's current jump is invalidated.
 * A jump is deemed invalid if a player is teleported.
 *
 * @param client		Client index.
 */
forward void GOKZ_OnJumpInvalidated(int client);

/**
 * Called when a player has been switched to a team.
 *
 * @param client		Client index.
 */
forward void GOKZ_OnJoinTeam(int client, int team);

/**
 * Called the first time a player spawns in on a team.
 *
 * @param client		Client index.
 */
forward void GOKZ_OnFirstSpawn(int client);

/**
 * Called when a mode has been loaded.
 *
 * @param mode			Mode loaded.
 */
forward void GOKZ_OnModeLoaded(int mode);

/**
 * Called when a mode has been unloaded.
 *
 * @param mode			Mode unloaded.
 */
forward void GOKZ_OnModeUnloaded(int mode);

/**
 * Called when a plugin other than gokz-core calls a native 
 * that may affect a player's timer or teleport count in 
 * their favour e.g. GOKZ_StartTimer, GOKZ_EndTimer,
 * GOKZ_SetTime and GOKZ_SetTeleportCount.
 *
 * @param plugin		Handle of the calling plugin.
 * @param client		Client index.
 * @return				Plugin_Handled or Plugin_Stop to block, Plugin_Continue to proceed.
 */
forward Action GOKZ_OnTimerNativeCalledExternally(Handle plugin, int client);

/**
 * Called when the options menu has been created and 3rd 
 * party plugins can grab the handle or add categories.
 *
 * @param topMenu		Options top menu handle.
 */
forward void GOKZ_OnOptionsMenuCreated(TopMenu topMenu);

/**
 * Called when the options menu is ready to have items added.
 *
 * @param topMenu		Options top menu handle.
 */
forward void GOKZ_OnOptionsMenuReady(TopMenu topMenu);

/**
 * Called when a course is registered. A course is registered if both the
 * start and end of it (e.g. timer buttons) have been detected.
 *
 * @param course		Course number.
 */
forward void GOKZ_OnCourseRegistered(int course);

/**
 * Called when a player's run becomes invalidated.
 * An invalidated run doesn't necessarily stop the timer.
 *
 * @param client     	Client index.
 */
forward void GOKZ_OnRunInvalidated(int client);

/**
 * Called when a sound is emitted to the client via GOKZ Core.
 *
 * @param client			Client index.
 * @param sample			Sound file name relative to the "sound" folder.
 * @param volume			Sound volume.
 * @param description		Optional description.
 * @return					Plugin_Continue to allow the sound to be played, Plugin_Stop to block it, 
 *							Plugin_Changed when any parameter has been modified.
 */
forward Action GOKZ_OnEmitSoundToClient(int client, const char[] sample, float &volume, const char[] description);


// =====[ NATIVES ]=====

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
 */
native void GOKZ_SetModeLoaded(int mode, bool loaded, int version = -1);

/**
 * Gets the total number of loaded modes.
 *
 * @return				Number of loaded modes.
 */
native int GOKZ_GetLoadedModeCount();

/**
 * Sets the player's current mode.
 * If the player's timer is running, it will be stopped.
 *
 * @param client     	Client index.
 * @param mode       	Mode.
 * @return           	Whether the operation was successful.
 */
native bool GOKZ_SetMode(int client, int mode);

/**
 * Gets the Handle to the options top menu.
 *
 * @return				Handle to the options top menu, 
 *						or null if not created yet.
 */
native TopMenu GOKZ_GetOptionsTopMenu();

/**
 * Gets whether a course is registered. A course is registered if both the
 * start and end of it (e.g. timer buttons) have been detected.
 *
 * @param course		Course number.
 * @return				Whether course has been registered.
 */
native bool GOKZ_GetCourseRegistered(int course);

/**
 * Prints a message to a client's chat, formatting colours and optionally 
 * adding the chat prefix. If using the chat prefix, specify a colour at 
 * the beginning of the message e.g. "{default}Hello!".
 *
 * @param client		Client index.
 * @param addPrefix		Whether to add the chat prefix.
 * @param format		Formatting rules.
 * @param any			Variable number of format parameters.
 */
native void GOKZ_PrintToChat(int client, bool addPrefix, const char[] format, any...);

/**
 * Prints a message to a client's chat, formatting colours and optionally 
 * adding the chat prefix. If using the chat prefix, specify a colour at 
 * the beginning of the message e.g. "{default}Hello!". Also prints the
 * message to the server log.
 *
 * @param client		Client index.
 * @param addPrefix		Whether to add the chat prefix.
 * @param format		Formatting rules.
 * @param any			Variable number of format parameters.
 */
native void GOKZ_PrintToChatAndLog(int client, bool addPrefix, const char[] format, any...);

/**
 * Starts a player's timer for a course on the current map.
 * This can be blocked by OnTimerNativeCalledExternally().
 *
 * @param client    	Client index.
 * @param course    	Course number.
 * @param allowMidair	Whether player is allowed to start timer midair.
 * @return				Whether player's timer was started.
 */
native bool GOKZ_StartTimer(int client, int course, bool allowOffGround = false);

/**
 * Ends a player's timer for a course on the current map.
 * This can be blocked by OnTimerNativeCalledExternally().
 *
 * @param client    	Client index.
 * @param course    	Course number.
 * @return				Whether player's timer was ended.
 */
native bool GOKZ_EndTimer(int client, int course);

/**
 * Forces a player's timer to stop. Intended for run invalidation.
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
 */
native void GOKZ_StopTimerAll(bool playSound = true);

/**
 * Gets whether or not a player's timer is running i.e. isn't 'stopped'.
 *
 * @param client    	Client index.
 * @return				Whether player's timer is running.
 */
native bool GOKZ_GetTimerRunning(int client);

/**
 * Gets whether or not a player's timer is valid i.e the run is a valid run.
 *
 * @param client    	Client index.
 * @return				Whether player's timer is running.
 */
native bool GOKZ_GetValidTimer(int client);

/**
 * Gets the course a player is currently running.
 *
 * @param client    	Client index.
 * @return		    	Course number.
 */
native int GOKZ_GetCourse(int client);

/**
 * Set the player's current course.
 * This can be blocked by OnTimerNativeCalledExternally().
 *
 * @param client     	Client index.
 * @param course     	Course number.
 * @return				Whether native was allowed to proceed.
 */
native bool GOKZ_SetCourse(int client, int course);

/**
 * Gets whether a player is paused.
 *
 * @param client    	Client index.
 * @return				Whether player is paused.
 */
native bool GOKZ_GetPaused(int client);

/**
 * Gets a player's current run time.
 *
 * @param client    	Client index.
 * @return				Player's current run time.
 */
native float GOKZ_GetTime(int client);

/**
 * Gets a player's current run time.
 * This can be blocked by OnTimerNativeCalledExternally().
 *
 * @param client    	Client index.
 * @param time			Run time to set to.
 * @return				Whether native was allowed to proceed.
 */
native bool GOKZ_SetTime(int client, float time);

/**
 * Mark a player's run as invalid without stopping the timer.
 *
 * @param client     	Client index.
 */
native void GOKZ_InvalidateRun(int client);

/**
 * Gets a player's current checkpoint count.
 *
 * @param client    	Client index.
 * @return				Player's current checkpoint count.
 */
native int GOKZ_GetCheckpointCount(int client);

/**
 * Sets a player's current checkpoint count.
 * This can be blocked by OnTimerNativeCalledExternally().
 *
 * @param client      	Client index.
 * @param cpCount     	Checkpoint count to set to.
 * @return				Whether native was allowed to proceed.
 */
native int GOKZ_SetCheckpointCount(int client, int cpCount);

/**
 * Gets checkpoint data of a player.
 *
 * @param client     	Client index.
 * @return           	Client's checkpoint data.
 */
native ArrayList GOKZ_GetCheckpointData(int client);

/**
 * Sets checkpoint data of a player. The checkpoint data is assumed to be ordered.
 * This can be blocked by OnTimerNativeCalledExternally().
 *
 * @param client        Client index.
 * @param checkpoints   Checkpoint data.
 * @param version		Checkpoint version.
 * @return				Whether native was allowed to proceed and operation was successful.
 */
native bool GOKZ_SetCheckpointData(int client, ArrayList checkpoints, int version);

/**
 * Get undo teleport data of a player.
 *
 * @param client     	Client index.
 * @return           	ArrayList of length 1 containing player's undo teleport data.
 */
native ArrayList GOKZ_GetUndoTeleportData(int client);

/**
 * Set undo teleport data of a player.
 * This can be blocked by OnTimerNativeCalledExternally().
 *
 * @param client			     	Client index.
 * @param undoTeleportDataArray		ArrayList of length 1 containing player's undo teleport data.
 * @param version					Checkpoint version.
 * @return              			Whether native was allowed to proceed and operation was successful.
 */
native bool GOKZ_SetUndoTeleportData(int client, ArrayList undoTeleportDataArray, int version);

/**
 * Gets a player's current teleport count.
 *
 * @param client    	Client index.
 * @return				Player's current teleport count.
 */
native int GOKZ_GetTeleportCount(int client);

/**
 * Sets a player's current teleport count.
 * This can be blocked by OnTimerNativeCalledExternally().
 *
 * @param client    	Client index.
 * @param tpCount		Teleport count to set to.
 * @return				Whether native was allowed to proceed.
 */
native bool GOKZ_SetTeleportCount(int client, int tpCount);

/**
 * Teleports a player to start, or respawns them.
 *
 * @param client    	Client index.
 */
native void GOKZ_TeleportToStart(int client);

/**
 * Teleports a player to the start zone/button of the specified course.
 *
 * @param client    	Client index.
 * @param course		Course index.
 */
native void GOKZ_TeleportToSearchStart(int client, int course);

/**
 * Gets the virtual button position the player currently has.
 *
 * @param client    	Client index.
 * @param position		Returns the client's virtual button position.
 * @param isStart		True to get the start button position, false for the end button.
 * @return				The course the button belongs to.
 */
native int GOKZ_GetVirtualButtonPosition(int client, float position[3], bool isStart);

/**
 * Sets the virtual button position the player currently has.
 *
 * @param client    	Client index.
 * @param position		The client's virtual button position.
 * @param course		The course the virtual button belongs to.
 * @param isStart		True to get the start button position, false for the end button.
 */
native void GOKZ_SetVirtualButtonPosition(int client, const float position[3], int course, bool isStart);

/**
 * Resets the player's virtual button.
 *
 * @param client    	Client index.
 * @param isStart		True to get the start button position, false for the end button.
 */
native void GOKZ_ResetVirtualButtonPosition(int client, bool isStart);

/**
 * Locks the virtual button position of a player.
 *
 * @param client    	Client index.
 */
native void GOKZ_LockVirtualButtons(int client);

/**
 * Gets the start position the player currently has.
 *
 * @param client    	Client index.
 * @param position		Returns the client's start position.
 * @param angles		Returns the client's start angles.
 * @return				Player's current start position type.
 */
native StartPositionType GOKZ_GetStartPosition(int client, float position[3], float angles[3]);

/**
 * Sets the start position the player currently has.
 *
 * @param client    	Client index.
 * @param type			The start position type.
 * @param position		The client's start position.
 * @param angles		The client's start angles.
 */
native void GOKZ_SetStartPosition(int client, StartPositionType type, const float position[3], const float angles[3]);

/**
 * Gets the type of start position the player currently has.
 * The "Spawn" type means teleport to start will respawn the player.
 *
 * @param client    	Client index.
 * @return				Player's current start position type.
 */
native StartPositionType GOKZ_GetStartPositionType(int client);

/**
 * Set the start position of the player to the start of a course.
 *
 * @param client    	Client index.
 * @param course        Course index.
 * 
 * @return              False if the course start was not found.
 */
native bool GOKZ_SetStartPositionToMapStart(int client, int course);

/**
 * Teleports a player to end.
 *
 * @param client		Client index.
 * @param course		Course index.
 */
native void GOKZ_TeleportToEnd(int client, int course);

/**
 * Set a new checkpoint at a player's current position.
 *
 * @param client    	Client index.
 */
native void GOKZ_MakeCheckpoint(int client);

/**
 * Gets whether a player can make a new checkpoint.
 * @param client		Client index.
 * @return				Whether player can set a checkpoint.
 */
native bool GOKZ_GetCanMakeCheckpoint(int client);

/**
 * Teleports a player to their last checkpoint.
 *
 * @param client    	Client index.
 */
native void GOKZ_TeleportToCheckpoint(int client);

/**
 * Gets whether a player can teleport to their checkpoint
 * e.g. will return false if player has no checkpoints.
 *
 * @param client		Client index.
 * @return				Whether player can teleport to checkpoint.
 */
native bool GOKZ_GetCanTeleportToCheckpoint(int client);

/**
 * Teleport a player back to a previous checkpoint.
 *
 * @param client    	Client index.
 */
native void GOKZ_PrevCheckpoint(int client);

/**
 * Gets whether a player can go to their previous checkpoint
 * e.g. will return false if player has no checkpoints.
 *
 * @param client		Client index.
 * @return				Whether player can go to previous checkpoint.
 */
native bool GOKZ_GetCanPrevCheckpoint(int client);

/**
 * Teleport a player to a more recent checkpoint.
 *
 * @param client    	Client index.
 */
native void GOKZ_NextCheckpoint(int client);

/**
 * Gets whether a player can go to their next checkpoint
 * e.g. will return false if player has no checkpoints.
 *
 * @param client		Client index.
 * @return				Whether player can go to next checkpoint.
 */
native bool GOKZ_GetCanNextCheckpoint(int client);

/**
 * Teleport a player to where they last teleported from.
 *
 * @param client    	Client index.
 */
native void GOKZ_UndoTeleport(int client);

/**
 * Gets whether a player can undo their teleport
 * e.g. will return false if teleport was from midair.
 *
 * @param client		Client index.
 * @return				Whether player can undo teleport.
 */
native bool GOKZ_GetCanUndoTeleport(int client);

/**
 * Pause a player's timer and freeze them.
 *
 * @param client    	Client index.
 */
native void GOKZ_Pause(int client);

/**
 * Gets whether a player can pause. Pausing is not allowed
 * under some circumstance when the timer is running.
 *
 * @param client    	Client index.
 */
native bool GOKZ_GetCanPause(int client);

/**
 * Resumes a player's timer and unfreezes them.
 *
 * @param client    	Client index.
 */
native void GOKZ_Resume(int client);

/**
 * Gets whether a player can resume. Resuming is not allowed
 * under some circumstance when the timer is running.
 *
 * @param client    	Client index.
 */
native bool GOKZ_GetCanResume(int client);

/**
 * Toggles the paused state of a player.
 *
 * @param client    	Client index.
 */
native void GOKZ_TogglePause(int client);

/**
 * Gets whether a player can teleport to start.
 *
 * @param client		Client index.
 * @return				Whether player can teleport to start.
 */
native bool GOKZ_GetCanTeleportToStartOrEnd(int client);

/**
 * Plays the error sound to a player if they have the option enabled.
 *
 * @param client		Client index.
 */
native void GOKZ_PlayErrorSound(int client);

/**
 * Set the origin of a player without invalidating any jumpstats.
 * 
 * Only use this in plugins that create a new mode!
 *
 * @param client		Client index.
 * @param origin		The new origin.
 */
native void GOKZ_SetValidJumpOrigin(int client, const float origin[3]);

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
 * Sets a player's option's value. Fails if option doesn't exist,
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
 */
native void GOKZ_SetHitPerf(int client, bool hitPerf);

/**
 * Gets a player's horizontal speed at the time of their last takeoff as recorded by GOKZ.
 *
 * @param client		Client index.
 * @return				Player's last takeoff speed as recorded by GOKZ.
 */
native float GOKZ_GetTakeoffSpeed(int client);

/**
 * Sets a player's recorded horizontal speed at the time of their last takeoff.
 * Intended to be called by GOKZ mode plugins only.
 *
 * @param client		Client index.
 * @param takeoffSpeed	Player's last takeoff speed as recorded by GOKZ.		
 */
native void GOKZ_SetTakeoffSpeed(int client, float takeoffSpeed);

/**
 * Gets whether a player's current or last jump/airtime is valid.
 * A jump is deemed invalid if the player is teleported.
 *
 * @param client		Client index.
 * @return				Validity of player's current or last jump.
 */
native bool GOKZ_GetValidJump(int client);

/**
 * Has a player switch to a team via GOKZ Core.
 *
 * @param client			Client index.
 * @param team				Which team to switch to.
 * @param restorePos		Whether to restore saved position if leaving spectators.
 * @param forceBroadcast	Force JoinTeam forward calling even if client's team did not change.
 */
native void GOKZ_JoinTeam(int client, int team, bool restorePos = true, bool forceBroadcast = false);

/**
 * Emit a sound to a player via GOKZ Core.
 * Sounds emitted by this native will call GOKZ_OnEmitSoundToClient forward.
 * 
 * @param client			Client index.
 * @param sample			Sound file name relative to the "sound" folder.
 * @param volume			Sound volume.
 * @param description		Optional description.
 */
native void GOKZ_EmitSoundToClient(int client, const char[] sample, float volume = SNDVOL_NORMAL, const char[] description = "");


// =====[ STOCKS ]=====

/**
 * Makes a player join a team if they aren't on one and respawns them.
 *
 * @param client		Client index.
 * @param team			Which team to switch to if not on one.
 * @param restorePos	Whether to restore saved position if leaving spectators.
 */
stock void GOKZ_RespawnPlayer(int client, int team = CS_TEAM_T, bool restorePos = true)
{
	if (IsSpectating(client))
	{
		GOKZ_JoinTeam(client, team, restorePos);
	}
	else
	{
		CS_RespawnPlayer(client);
	}
}

/**
 * Prints a message to all client's chat, formatting colours and optionally 
 * adding the chat prefix. If using the chat prefix, specify a colour at 
 * the beginning of the message e.g. "{default}Hello!".
 *
 * @param addPrefix		Whether to add the chat prefix.
 * @param format		Formatting rules.
 * @param any			Variable number of format parameters.
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
 * Gets the player's current time type.
 *
 * @param client		Client index.
 * @return				Player's current time type.
 */
stock int GOKZ_GetTimeType(int client)
{
	return GOKZ_GetTimeTypeEx(GOKZ_GetTeleportCount(client));
}

/**
 * Gets the time type given a teleport count.
 *
 * @param teleports		Teleport count.
 * @return				Time type.
 */
stock int GOKZ_GetTimeTypeEx(int teleportCount)
{
	if (teleportCount == 0)
	{
		return TimeType_Pro;
	}
	return TimeType_Nub;
}

/**
 * Clears and populates a menu with an item for each mode
 * in order of the mode enumeration. Highlights the client's
 * selected mode with an asterisk.
 *
 * @param client				Client index to check selected mode.
 * @param menu					Menu to populate items with.
 * @param disableUnloadedModes	Draw items for unloaded modes as disabled.
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

/**
 * Gets the current default mode.
 *
 * @return				Default mode.
 */
stock int GOKZ_GetDefaultMode()
{
	return GOKZ_GetCoreOptionProp(Option_Mode, OptionProp_DefaultValue);
}

/**
 * Returns whether a course number is a valid (within valid range).
 *
 * @param course		Course number.
 * @param bonus			Whether to only consider bonus course numbers as valid.
 * @return				Whether course number is valid.
 */
stock bool GOKZ_IsValidCourse(int course, bool bonus = false)
{
	return (!bonus && course == 0) || (0 < course && course < GOKZ_MAX_COURSES);
}

/**
 * Returns an integer from an entity's name as matched using a regular expression.
 *
 * @param entity			Entity index.
 * @param re				Regular expression to match the integer with.
 * @param substringID		ID of the substring that will contain the integer.
 * @returns					Integer found in the entity's name, or -1 if not found.
 */
stock int GOKZ_MatchIntFromEntityName(int entity, Regex re, int substringID)
{
	int num = -1;
	char buffer[32];
	GetEntityName(entity, buffer, sizeof(buffer));
	
	if (re.Match(buffer) > 0)
	{
		re.GetSubString(1, buffer, sizeof(buffer));
		num = StringToInt(buffer);
	}
	
	return num;
}

/**
 * Emits a sound to other players that are spectating the client.
 * Sounds emitted by this function will call GOKZ_OnEmitSoundToClient forward.
 *
 * @param sample			Sound file name relative to the "sound" folder.
 * @param volume			Sound volume.
 * @param description		Optional description.
 */
stock void GOKZ_EmitSoundToAll(const char[] sample, float volume = SNDVOL_NORMAL, const char[] description = "")
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			GOKZ_EmitSoundToClient(client, sample, volume, description);
		}
	}
}

/**
 * Emits a sound to other players that are spectating the client.
 * Sounds emitted by this function will call GOKZ_OnEmitSoundToClient forward.
 *
 * @param client			Client being spectated.
 * @param sample			Sound file name relative to the "sound" folder.
 * @param volume			Sound volume.
 * @param description		Optional description.
 */
stock void GOKZ_EmitSoundToClientSpectators(int client, const char[] sample, float volume = SNDVOL_NORMAL, const char[] description = "")
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetObserverTarget(i) == client)
		{
			GOKZ_EmitSoundToClient(i, sample, volume);
		}
	}
}

// =====[ DEPENDENCY ]=====

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
	MarkNativeAsOptional("GOKZ_SetMode");
	MarkNativeAsOptional("GOKZ_GetOptionsTopMenu");
	MarkNativeAsOptional("GOKZ_GetCourseRegistered");
	MarkNativeAsOptional("GOKZ_PrintToChat");
	MarkNativeAsOptional("GOKZ_PrintToChatAndLog");
	MarkNativeAsOptional("GOKZ_StartTimer");
	MarkNativeAsOptional("GOKZ_EndTimer");
	MarkNativeAsOptional("GOKZ_StopTimer");
	MarkNativeAsOptional("GOKZ_StopTimerAll");
	MarkNativeAsOptional("GOKZ_TeleportToStart");
	MarkNativeAsOptional("GOKZ_TeleportToSearchStart");
	MarkNativeAsOptional("GOKZ_GetVirtualButtonPosition");
	MarkNativeAsOptional("GOKZ_SetVirtualButtonPosition");
	MarkNativeAsOptional("GOKZ_ResetVirtualButtonPosition");
	MarkNativeAsOptional("GOKZ_LockVirtualButtons");
	MarkNativeAsOptional("GOKZ_GetStartPosition");
	MarkNativeAsOptional("GOKZ_SetStartPosition");
	MarkNativeAsOptional("GOKZ_GetStartPositionType");
	MarkNativeAsOptional("GOKZ_SetStartPositionToMapStart");
	MarkNativeAsOptional("GOKZ_TeleportToEnd");
	MarkNativeAsOptional("GOKZ_MakeCheckpoint");
	MarkNativeAsOptional("GOKZ_GetCanMakeCheckpoint");
	MarkNativeAsOptional("GOKZ_TeleportToCheckpoint");
	MarkNativeAsOptional("GOKZ_GetCanTeleportToCheckpoint");
	MarkNativeAsOptional("GOKZ_PrevCheckpoint");
	MarkNativeAsOptional("GOKZ_GetCanPrevCheckpoint");
	MarkNativeAsOptional("GOKZ_NextCheckpoint");
	MarkNativeAsOptional("GOKZ_GetCanNextCheckpoint");
	MarkNativeAsOptional("GOKZ_UndoTeleport");
	MarkNativeAsOptional("GOKZ_GetCanUndoTeleport");
	MarkNativeAsOptional("GOKZ_Pause");
	MarkNativeAsOptional("GOKZ_GetCanPause");
	MarkNativeAsOptional("GOKZ_Resume");
	MarkNativeAsOptional("GOKZ_GetCanResume");
	MarkNativeAsOptional("GOKZ_TogglePause");
	MarkNativeAsOptional("GOKZ_GetCanTeleportToStartOrEnd");
	MarkNativeAsOptional("GOKZ_PlayErrorSound");
	MarkNativeAsOptional("GOKZ_SetValidJumpOrigin");
	MarkNativeAsOptional("GOKZ_GetTimerRunning");
	MarkNativeAsOptional("GOKZ_GetCourse");
	MarkNativeAsOptional("GOKZ_SetCourse");
	MarkNativeAsOptional("GOKZ_GetPaused");
	MarkNativeAsOptional("GOKZ_GetTime");
	MarkNativeAsOptional("GOKZ_SetTime");
	MarkNativeAsOptional("GOKZ_InvalidateRun");
	MarkNativeAsOptional("GOKZ_GetCheckpointCount");
	MarkNativeAsOptional("GOKZ_SetCheckpointCount");
	MarkNativeAsOptional("GOKZ_GetCheckpointData");
	MarkNativeAsOptional("GOKZ_SetCheckpointData");
	MarkNativeAsOptional("GOKZ_GetUndoTeleportData");
	MarkNativeAsOptional("GOKZ_SetUndoTeleportData");
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
	MarkNativeAsOptional("GOKZ_EmitSoundToClient");
}
#endif