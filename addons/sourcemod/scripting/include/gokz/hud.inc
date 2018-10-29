/* 	
	GOKZ HUD Include File
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_hud_included_
#endinput
#endif
#define _gokz_hud_included_



// =========================  DEFINITIONS  ========================= //

#define OPTIONS_MENU_CAT_HUD "hud"



// =========================  ENUMERATIONS  ========================= //

enum HUDOption
{
	HUDOPTION_INVALID = -1, 
	HUDOption_TPMenu, 
	HUDOption_InfoPanel, 
	HUDOption_ShowKeys, 
	HUDOption_TimerText, 
	HUDOption_SpeedText, 
	HUDOption_ShowWeapon,
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
	TimerText_Bottom, 
	TimerText_Top, 
	TIMERTEXT_COUNT
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



// =========================  OTHER  ========================= //

stock char gC_HUDOptionNames[HUDOPTION_COUNT][] =  { "tpmenu", "infopanel", "showkeys", "timertext", "speedtext", "showweapon" };



// =========================  STOCKS  ========================= //

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
 * Sets the player's gokz-hud option's value.
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