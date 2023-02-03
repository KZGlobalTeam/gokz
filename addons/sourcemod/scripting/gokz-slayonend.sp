#include <sourcemod>

#include <gokz/core>
#include <gokz/slayonend>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Slay On End", 
	author = "DanZay", 
	description = "Adds option to slay the player upon ending their timer", 
	version = GOKZ_VERSION, 
	url = GOKZ_SOURCE_URL
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-slayonend.txt"

TopMenu gTM_Options;
TopMenuObject gTMO_CatGeneral;
TopMenuObject gTMO_ItemSlayOnEnd;



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-slayonend");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-common.phrases");
	LoadTranslations("gokz-slayonend.phrases");
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}

	TopMenu topMenu;
	if (LibraryExists("gokz-core") && ((topMenu = GOKZ_GetOptionsTopMenu()) != null))
	{
		GOKZ_OnOptionsMenuReady(topMenu);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
}



// =====[ CLIENT EVENTS ]=====

public void GOKZ_OnTimerEnd_Post(int client, int course, float time, int teleportsUsed)
{
	OnTimerEnd_SlayOnEnd(client);
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	OnOptionChanged_Options(client, option, newValue);
}



// =====[ OTHER EVENTS ]=====

public void GOKZ_OnOptionsMenuReady(TopMenu topMenu)
{
	OnOptionsMenuReady_Options();
	OnOptionsMenuReady_OptionsMenu(topMenu);
}



// =====[ SLAY ON END ]=====

void OnTimerEnd_SlayOnEnd(int client)
{
	if (GOKZ_GetOption(client, SLAYONEND_OPTION_NAME) == SlayOnEnd_Enabled)
	{
		CreateTimer(3.0, Timer_SlayPlayer, GetClientUserId(client));
	}
}

public Action Timer_SlayPlayer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		ForcePlayerSuicide(client);
	}
	return Plugin_Continue;
}



// =====[ OPTIONS ]=====

void OnOptionsMenuReady_Options()
{
	RegisterOption();
}

void RegisterOption()
{
	GOKZ_RegisterOption(SLAYONEND_OPTION_NAME, SLAYONEND_OPTION_DESCRIPTION, 
		OptionType_Int, SlayOnEnd_Disabled, 0, SLAYONEND_COUNT - 1);
}

void OnOptionChanged_Options(int client, const char[] option, any newValue)
{
	if (StrEqual(option, SLAYONEND_OPTION_NAME))
	{
		switch (newValue)
		{
			case SlayOnEnd_Disabled:
			{
				GOKZ_PrintToChat(client, true, "%t", "Option - Slay On End - Disable");
			}
			case SlayOnEnd_Enabled:
			{
				GOKZ_PrintToChat(client, true, "%t", "Option - Slay On End - Enable");
			}
		}
	}
}



// =====[ OPTIONS MENU ]=====

void OnOptionsMenuReady_OptionsMenu(TopMenu topMenu)
{
	if (gTM_Options == topMenu)
	{
		return;
	}

	gTM_Options = topMenu;
	gTMO_CatGeneral = gTM_Options.FindCategory(GENERAL_OPTION_CATEGORY);
	gTMO_ItemSlayOnEnd = gTM_Options.AddItem(SLAYONEND_OPTION_NAME, TopMenuHandler_SlayOnEnd, gTMO_CatGeneral);
}

public void TopMenuHandler_SlayOnEnd(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (topobj_id != gTMO_ItemSlayOnEnd)
	{
		return;
	}

	if (action == TopMenuAction_DisplayOption)
	{
		if (GOKZ_GetOption(param, SLAYONEND_OPTION_NAME) == SlayOnEnd_Disabled)
		{
			FormatEx(buffer, maxlength, "%T - %T", 
				"Options Menu - Slay On End", param, 
				"Options Menu - Disabled", param);
		}
		else
		{
			FormatEx(buffer, maxlength, "%T - %T", 
				"Options Menu - Slay On End", param, 
				"Options Menu - Enabled", param);
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		GOKZ_CycleOption(param, SLAYONEND_OPTION_NAME);
		gTM_Options.Display(param, TopMenuPosition_LastCategory);
	}
} 