#include <sourcemod>

#include <cstrike>

#include <gokz/core>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Spectate Menu", 
	author = "DanZay", 
	description = "Provides easy ways to spectate players", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-spec.txt"



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-spec");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("gokz-common.phrases");
	LoadTranslations("gokz-spec.phrases");
	
	RegisterCommands();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
}



// =====[ SPEC MENU ]=====

int DisplaySpecMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Spec);
	menu.SetTitle("%T", "Spec Menu - Title", client);
	int menuItems = SpecMenuAddItems(client, menu);
	if (menuItems == 0)
	{
		delete menu;
	}
	else
	{
		menu.Display(client, MENU_TIME_FOREVER);
	}
	return menuItems;
}

bool Spectate(int client)
{
	if (!CanSpectate(client))
	{
		return false;
	}
	
	GOKZ_JoinTeam(client, CS_TEAM_SPECTATOR);
	return true;
}

// Returns whether change to spectating the target was successful
bool SpectatePlayer(int client, int target, bool printMessage = true)
{
	if (!CanSpectate(client))
	{
		return false;
	}
	
	if (target == client)
	{
		if (printMessage)
		{
			GOKZ_PrintToChat(client, true, "%t", "Spectate Failure (Not Yourself)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	else if (!IsPlayerAlive(target))
	{
		if (printMessage)
		{
			GOKZ_PrintToChat(client, true, "%t", "Spectate Failure (Dead)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	
	GOKZ_JoinTeam(client, CS_TEAM_SPECTATOR);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 4);
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", target);
	
	return true;
}

bool CanSpectate(int client)
{
	return GOKZ_GetPaused(client) || GOKZ_GetCanPause(client);
}

public int MenuHandler_Spec(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[16];
		menu.GetItem(param2, info, sizeof(info));
		int target = GetClientOfUserId(StringToInt(info));
		
		if (!IsValidClient(target))
		{
			GOKZ_PrintToChat(param1, true, "%t", "Player No Longer Valid");
			GOKZ_PlayErrorSound(param1);
			DisplaySpecMenu(param1);
		}
		else if (!SpectatePlayer(param1, target))
		{
			DisplaySpecMenu(param1);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

// Returns number of items added to the menu
int SpecMenuAddItems(int client, Menu menu)
{
	char display[MAX_NAME_LENGTH + 4];
	int targetCount = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || i == client)
		{
			continue;
		}
		
		if (IsFakeClient(i))
		{
			FormatEx(display, sizeof(display), "BOT %N", i);
		}
		else
		{
			FormatEx(display, sizeof(display), "%N", i);
		}
		
		menu.AddItem(IntToStringEx(GetClientUserId(i)), display, ITEMDRAW_DEFAULT);
		targetCount++;
	}
	
	return targetCount;
}



// =====[ COMMANDS ]=====

void RegisterCommands()
{
	RegConsoleCmd("sm_spec", CommandSpec, "[KZ] Spectate another player. Usage: !spec <player>");
	RegConsoleCmd("sm_specs", CommandSpecs, "[KZ] List currently spectating players in chat.");
	RegConsoleCmd("sm_speclist", CommandSpecs, "[KZ] List currently spectating players in chat.");
}

public Action CommandSpec(int client, int args)
{
	// If no arguments, display the spec menu
	if (args < 1)
	{
		if (DisplaySpecMenu(client) == 0)
		{
			// No targets, so just join spec
			Spectate(client);
		}
	}
	// Otherwise try to spectate the player
	else
	{
		char specifiedPlayer[MAX_NAME_LENGTH];
		GetCmdArg(1, specifiedPlayer, sizeof(specifiedPlayer));
		
		int target = FindTarget(client, specifiedPlayer, false, false);
		if (target != -1)
		{
			SpectatePlayer(client, target);
		}
	}
	return Plugin_Handled;
}

public Action CommandSpecs(int client, int args)
{
	int specs = 0;
	char specNames[1024];
	
	int target = IsPlayerAlive(client) ? client : GetObserverTarget(client);
	int targetSpecs = 0;
	char targetSpecNames[1024];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && IsSpectating(i))
		{
			specs++;
			if (specs == 1)
			{
				FormatEx(specNames, sizeof(specNames), "{lime}%N", i);
			}
			else
			{
				Format(specNames, sizeof(specNames), "%s{grey}, {lime}%N", specNames, i);
			}
			
			if (target != -1 && GetObserverTarget(i) == target)
			{
				targetSpecs++;
				if (targetSpecs == 1)
				{
					FormatEx(targetSpecNames, sizeof(targetSpecNames), "{lime}%N", i);
				}
				else
				{
					Format(targetSpecNames, sizeof(targetSpecNames), "%s{grey}, {lime}%N", targetSpecNames, i);
				}
			}
		}
	}
	
	if (specs == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "Spectator List (None)");
	}
	else
	{
		GOKZ_PrintToChat(client, true, "%t", "Spectator List", specs, specNames);
		if (targetSpecs == 0)
		{
			GOKZ_PrintToChat(client, false, "%t", "Target Spectator List (None)", target);
		}
		else
		{
			GOKZ_PrintToChat(client, false, "%t", "Target Spectator List", target, targetSpecs, targetSpecNames);
		}
	}
} 