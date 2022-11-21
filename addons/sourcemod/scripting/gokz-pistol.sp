#include <sourcemod>

#include <cstrike>
#include <sdktools>

#include <gokz/core>
#include <gokz/pistol>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Pistol", 
	author = "DanZay", 
	description = "Allows players to pick a pistol to KZ with", 
	version = GOKZ_VERSION, 
	url = GOKZ_SOURCE_URL
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-pistols.txt"

TopMenu gTM_Options;
TopMenuObject gTMO_CatGeneral;
TopMenuObject gTMO_ItemPistol;
bool gB_CameFromOptionsMenu[MAXPLAYERS + 1];



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-pistol");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-common.phrases");
	LoadTranslations("gokz-pistol.phrases");

	HookEvents();
	RegisterCommands();
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

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) // player_spawn post hook 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client))
	{
		UpdatePistol(client);
	}
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	if (StrEqual(option, PISTOL_OPTION_NAME))
	{
		UpdatePistol(client);
	}
}



// =====[ OTHER EVENTS ]=====

public void GOKZ_OnOptionsMenuReady(TopMenu topMenu)
{
	OnOptionsMenuReady_Options();
	OnOptionsMenuReady_OptionsMenu(topMenu);
}



// =====[ GENERAL ]=====

void HookEvents()
{
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}



// =====[ PISTOL ]=====

void UpdatePistol(int client)
{
	GivePistol(client, GOKZ_GetOption(client, PISTOL_OPTION_NAME));
}

void GivePistol(int client, int pistol)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client)
		 || GetClientTeam(client) == CS_TEAM_NONE)
	{
		return;
	}

	int playerTeam = GetClientTeam(client);
	bool switchedTeams = false;

	// Switch teams to the side that buys that gun so that gun skins load
	if (gI_PistolTeams[pistol] == CS_TEAM_CT && playerTeam != CS_TEAM_CT)
	{
		CS_SwitchTeam(client, CS_TEAM_CT);
		switchedTeams = true;
	}
	else if (gI_PistolTeams[pistol] == CS_TEAM_T && playerTeam != CS_TEAM_T)
	{
		CS_SwitchTeam(client, CS_TEAM_T);
		switchedTeams = true;
	}

	// Give the player this pistol (or remove it)
	int currentPistol = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if (currentPistol != -1)
	{
		RemovePlayerItem(client, currentPistol);
	}

	if (pistol == Pistol_Disabled)
	{
		// Force switch to knife to avoid weird behaviour
		// Doesn't use EquipPlayerWeapon because server hangs when player spawns
		FakeClientCommand(client, "use weapon_knife");
	}
	else
	{
		GivePlayerItem(client, gC_PistolClassNames[pistol]);
	}

	// Go back to original team
	if (switchedTeams)
	{
		CS_SwitchTeam(client, playerTeam);
	}
}



// =====[ PISTOL MENU ]=====

void DisplayPistolMenu(int client, int atItem = 0, bool fromOptionsMenu = false)
{
	Menu menu = new Menu(MenuHandler_Pistol);
	menu.SetTitle("%T", "Pistol Menu - Title", client);
	PistolMenuAddItems(client, menu);
	menu.DisplayAt(client, atItem, MENU_TIME_FOREVER);

	gB_CameFromOptionsMenu[client] = fromOptionsMenu;
}

public int MenuHandler_Pistol(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		GOKZ_SetOption(param1, PISTOL_OPTION_NAME, param2);
		DisplayPistolMenu(param1, param2 / 6 * 6, gB_CameFromOptionsMenu[param1]); // Re-display menu at same spot
	}
	else if (action == MenuAction_Cancel && gB_CameFromOptionsMenu[param1])
	{
		gTM_Options.Display(param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void PistolMenuAddItems(int client, Menu menu)
{
	int selectedPistol = GOKZ_GetOption(client, PISTOL_OPTION_NAME);
	char display[32];

	for (int pistol = 0; pistol < PISTOL_COUNT; pistol++)
	{
		if (pistol == Pistol_Disabled)
		{
			FormatEx(display, sizeof(display), "%T", "Options Menu - Disabled", client);
		}
		else
		{
			FormatEx(display, sizeof(display), "%s", gC_PistolNames[pistol]);
		}

		// Add asterisk to selected pistol
		if (pistol == selectedPistol)
		{
			Format(display, sizeof(display), "%s*", display);
		}

		menu.AddItem("", display, ITEMDRAW_DEFAULT);
	}
}



// =====[ OPTIONS ]=====

void OnOptionsMenuReady_Options()
{
	RegisterOption();
}

void RegisterOption()
{
	GOKZ_RegisterOption(PISTOL_OPTION_NAME, PISTOL_OPTION_DESCRIPTION, 
		OptionType_Int, Pistol_USPS, 0, PISTOL_COUNT - 1);
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
	gTMO_ItemPistol = gTM_Options.AddItem(PISTOL_OPTION_NAME, TopMenuHandler_Pistol, gTMO_CatGeneral);
}

public void TopMenuHandler_Pistol(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (topobj_id != gTMO_ItemPistol)
	{
		return;
	}

	if (action == TopMenuAction_DisplayOption)
	{
		int pistol = GOKZ_GetOption(param, PISTOL_OPTION_NAME);
		if (pistol == Pistol_Disabled)
		{
			FormatEx(buffer, maxlength, "%T - %T", 
				"Options Menu - Pistol", param, 
				"Options Menu - Disabled", param);
		}
		else
		{
			FormatEx(buffer, maxlength, "%T - %s", 
				"Options Menu - Pistol", param, 
				gC_PistolNames[pistol]);
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayPistolMenu(param, _, true);
	}
}



// =====[ COMMANDS ]=====

void RegisterCommands()
{
	RegConsoleCmd("sm_pistol", CommandPistolMenu, "[KZ] Open the pistol selection menu.");
}

public Action CommandPistolMenu(int client, int args)
{
	DisplayPistolMenu(client);
	return Plugin_Handled;
} 