/*
	gokz-hud Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_hud_included_
#endinput
#endif
#define _gokz_hud_included_



// =====[ ENUMS ]=====

enum HUDOption:
{
	HUDOPTION_INVALID = -1, 
	HUDOption_TPMenu, 
	HUDOption_InfoPanel, 
	HUDOption_ShowKeys, 
	HUDOption_TimerText, 
	HUDOption_TimerStyle,
	HUDOption_TimerType, 
	HUDOption_SpeedText,
	HUDOption_ShowWeapon,
	HUDOption_ShowControls,
	HUDOption_DeadstrafeColor,
	HUDOption_UpdateRate,
	HUDOption_ShowSpectators,
	HUDOption_DynamicMenu,
	HUDOPTION_COUNT
};

enum
{
	TPMenu_Disabled = 0, 
	TPMenu_Simple, 
	TPMenu_Advanced, 
	TPMENU_COUNT
};

enum
{
	InfoPanel_Disabled = 0, 
	InfoPanel_Enabled, 
	INFOPANEL_COUNT
};

enum
{
	ShowKeys_Spectating = 0, 
	ShowKeys_Always, 
	ShowKeys_Disabled, 
	SHOWKEYS_COUNT
};

enum
{
	TimerText_Disabled = 0, 
	TimerText_InfoPanel, 
	TimerText_TPMenu, 
	TimerText_Bottom, 
	TimerText_Top, 
	TIMERTEXT_COUNT
};

enum
{
	TimerStyle_Standard = 0, 
	TimerStyle_Precise, 
	TIMERSTYLE_COUNT
};

enum
{
	TimerType_Disabled = 0,
	TimerType_Enabled,
	TIMERTYPE_COUNT
};

enum
{
	SpeedText_Disabled = 0, 
	SpeedText_InfoPanel, 
	SpeedText_Bottom, 
	SPEEDTEXT_COUNT
};

enum
{
	ShowWeapon_Disabled = 0, 
	ShowWeapon_Enabled, 
	SHOWWEAPON_COUNT
};

enum
{
	ReplayControls_Disabled = 0,
	ReplayControls_Enabled,
	REPLAYCONTROLS_COUNT
};

enum
{
	DeadstrafeColor_Disabled = 0, 
	DeadstrafeColor_Enabled, 
	DEADSTRAFECOLOR_COUNT
};

enum
{
	ShowSpecs_Disabled = 0,
	ShowSpecs_Number,
	ShowSpecs_Full,
	SHOWSPECS_COUNT
};


enum
{
	UpdateRate_Slow = 0,
	UpdateRate_Fast,
	UPDATERATE_COUNT,
};

enum
{
	DynamicMenu_Legacy = 0,
	DynamicMenu_Disabled,
	DynamicMenu_Enabled,
	DYNAMICMENU_COUNT
};

// =====[ STRUCTS ]======

enum struct HUDInfo
{
	bool TimerRunning;
	int TimeType;
	float Time;
	bool Paused;
	bool OnGround;
	bool OnLadder;
	bool Noclipping;
	bool Ducking;
	bool HitBhop;
	bool IsTakeoff;
	float Speed;
	int ID;
	bool Jumped;
	bool HitPerf;
	bool HitJB;
	float TakeoffSpeed;
	int Buttons;
	int CurrentTeleport;
}



// =====[ CONSTANTS ]=====

#define HUD_OPTION_CATEGORY "HUD"
#define HUD_MAX_BHOP_GROUND_TICKS 5
#define HUD_MAX_HINT_SIZE 227

stock char gC_HUDOptionNames[HUDOPTION_COUNT][] = 
{
	"GOKZ HUD - Teleport Menu", 
	"GOKZ HUD - Centre Panel", 
	"GOKZ HUD - Show Keys", 
	"GOKZ HUD - Timer Text", 
	"GOKZ HUD - Timer Style", 
	"GOKZ HUD - Show Time Type",
	"GOKZ HUD - Speed Text", 
	"GOKZ HUD - Show Weapon",
	"GOKZ HUD - Show Controls",
	"GOKZ HUD - Dead Strafe",
	"GOKZ HUD - Update Rate",
	"GOKZ HUD - Show Spectators",
	"GOKZ HUD - Dynamic Menu"
};

stock char gC_HUDOptionDescriptions[HUDOPTION_COUNT][] = 
{
	"Teleport Menu - 0 = Disabled, 1 = Simple, 2 = Advanced", 
	"Centre Information Panel - 0 = Disabled, 1 = Enabled", 
	"Key Press Display - 0 = Spectating, 1 = Always, 2 = Disabled", 
	"Timer Display - 0 = Disabled, 1 = Centre Panel, 2 = Teleport Menu, 3 = Bottom, 4 = Top", 
	"Timer Style - 0 = Standard, 1 = Precise",
	"Timer Type - 0 = Disabled, 1 = Enabled", 
	"Speed Display - 0 = Disabled, 1 = Centre Panel, 2 = Bottom",
	"Weapon Viewmodel - 0 = Disabled, 1 = Enabled",
	"Replay Controls Display - 0 = Disbled, 1 = Enabled",
	"Dead Strafe Indicator - 0 = Disabled, 1 = Enabled",
	"HUD Update Rate - 0 = Slow, 1 = Fast",
	"Show Spectators - 0 = Disabled, 1 = Number Only, 2 = Number and Names",
	"Dynamic Menu - 0 = Legacy, 1 = Disabled, 2 = Enabled"
};

stock char gC_HUDOptionPhrases[HUDOPTION_COUNT][] = 
{
	"Options Menu - Teleport Menu", 
	"Options Menu - Info Panel", 
	"Options Menu - Show Keys", 
	"Options Menu - Timer Text", 
	"Options Menu - Timer Style", 
	"Options Menu - Timer Type",
	"Options Menu - Speed Text",
	"Options Menu - Show Weapon",
	"Options Menu - Show Controls",
	"Options Menu - Dead Strafe Indicator",
	"Options Menu - Update Rate",
	"Options Menu - Show Spectators",
	"Options Menu - Dynamic Menu"
};

stock int gI_HUDOptionCounts[HUDOPTION_COUNT] = 
{
	TPMENU_COUNT, 
	INFOPANEL_COUNT, 
	SHOWKEYS_COUNT, 
	TIMERTEXT_COUNT, 
	TIMERSTYLE_COUNT,
	TIMERTYPE_COUNT, 
	SPEEDTEXT_COUNT,
	SHOWWEAPON_COUNT,
	REPLAYCONTROLS_COUNT,
	DEADSTRAFECOLOR_COUNT,
	UPDATERATE_COUNT,
	SHOWSPECS_COUNT,
	DYNAMICMENU_COUNT
};

stock int gI_HUDOptionDefaults[HUDOPTION_COUNT] = 
{
	TPMenu_Advanced, 
	InfoPanel_Enabled, 
	ShowKeys_Spectating, 
	TimerText_InfoPanel, 
	TimerStyle_Standard, 
	TimerType_Enabled,
	SpeedText_InfoPanel,
	ShowWeapon_Enabled,
	ReplayControls_Enabled,
	DeadstrafeColor_Disabled,
	UpdateRate_Slow,
	ShowSpecs_Disabled,
	DynamicMenu_Legacy
};

stock char gC_TPMenuPhrases[TPMENU_COUNT][] = 
{
	"Options Menu - Disabled", 
	"Options Menu - Simple", 
	"Options Menu - Advanced"
};

stock char gC_ShowKeysPhrases[SHOWKEYS_COUNT][] = 
{
	"Options Menu - Spectating", 
	"Options Menu - Always", 
	"Options Menu - Disabled"
};

stock char gC_TimerTextPhrases[TIMERTEXT_COUNT][] = 
{
	"Options Menu - Disabled", 
	"Options Menu - Info Panel", 
	"Options Menu - Teleport Menu", 
	"Options Menu - Bottom", 
	"Options Menu - Top"
};

stock char gC_TimerTypePhrases[TIMERTYPE_COUNT][] = 
{
	"Options Menu - Disabled",
	"Options Menu - Enabled"
};

stock char gC_SpeedTextPhrases[SPEEDTEXT_COUNT][] = 
{
	"Options Menu - Disabled", 
	"Options Menu - Info Panel", 
	"Options Menu - Bottom"
};

stock char gC_ShowControlsPhrases[REPLAYCONTROLS_COUNT][] =
{
	"Options Menu - Disabled",
	"Options Menu - Enabled"
};

stock char gC_DeadstrafeColorPhrases[DEADSTRAFECOLOR_COUNT][] = 
{
	"Options Menu - Disabled",
	"Options Menu - Enabled"
};

stock char gC_ShowSpecsPhrases[SHOWSPECS_COUNT][] =
{
	"Options Menu - Disabled",
	"Options Menu - Number",
	"Options Menu - Number and Names"
};

stock char gC_HUDUpdateRatePhrases[UPDATERATE_COUNT][]=
{
	"Options Menu - Slow",
	"Options Menu - Fast"
};

stock char gC_DynamicMenuPhrases[DYNAMICMENU_COUNT][]=
{
	"Options Menu - Legacy",
	"Options Menu - Disabled",
	"Options Menu - Enabled"
};

// =====[ NATIVES ]=====

/**
 * Forces the client's TP menu to update.
 *
 * @param client		Client index.
 */
native void GOKZ_HUD_ForceUpdateTPMenu(int client);

// =====[ STOCKS ]=====

/**
 * Returns whether an option is a gokz-hud option.
 *
 * @param option		Option name.
 * @param optionEnum	Variable to store enumerated gokz-hud option (if it is one).
 * @return				Whether option is a gokz-hud option.
 */
stock bool GOKZ_HUD_IsHUDOption(const char[] option, HUDOption &optionEnum = HUDOPTION_INVALID)
{
	for (HUDOption i; i < HUDOPTION_COUNT; i++)
	{
		if (StrEqual(option, gC_HUDOptionNames[i]))
		{
			optionEnum = i;
			return true;
		}
	}
	return false;
}

/**
 * Gets the current value of a player's gokz-hud option.
 *
 * @param client		Client index.
 * @param option		gokz-hud option.
 * @return				Current value of option.
 */
stock any GOKZ_HUD_GetOption(int client, HUDOption option)
{
	return GOKZ_GetOption(client, gC_HUDOptionNames[option]);
}

/**
 * Sets a player's gokz-hud option's value.
 *
 * @param client		Client index.
 * @param option		gokz-hud option.
 * @param value			New option value.
 * @return				Whether option was successfully set.
 */
stock bool GOKZ_HUD_SetOption(int client, HUDOption option, any value)
{
	return GOKZ_SetOption(client, gC_HUDOptionNames[option], value);
}

/**
 * Increment an integer-type gokz-hud option's value.
 * Loops back to '0' if max value is exceeded.
 *
 * @param client		Client index.
 * @param option		gokz-hud option.
 * @return				Whether option was successfully set.
 */
stock bool GOKZ_HUD_CycleOption(int client, HUDOption option)
{
	return GOKZ_CycleOption(client, gC_HUDOptionNames[option]);
}

/**
 * Represents a time float as a string e.g. 01:23.45
 * and according to the client's HUD options.
 *
 * @param client		Client index.
 * @param time			Time in seconds.
 * @return				String representation of time.
 */
stock char[] GOKZ_HUD_FormatTime(int client, float time)
{
	bool precise = GOKZ_HUD_GetOption(client, HUDOption_TimerStyle) == TimerStyle_Precise;
	return GOKZ_FormatTime(time, precise);
}



// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_gokz_hud = 
{
	name = "gokz-hud", 
	file = "gokz-hud.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_gokz_hud_SetNTVOptional()
{
	MarkNativeAsOptional("GOKZ_HUD_ForceUpdateTPMenu");
}
#endif