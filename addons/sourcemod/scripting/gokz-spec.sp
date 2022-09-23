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

int DisplaySpecMenu(int client, bool useFilter = false, char[] filter = "")
{
	Menu menu = new Menu(MenuHandler_Spec);
	menu.SetTitle("%T", "Spec Menu - Title", client);
	int menuItems = SpecMenuAddItems(client, menu, useFilter, filter);
	if (menuItems == 0 || menuItems == 1)
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

	// Put player in free look mode and apply according movetype
	SetEntProp(client, Prop_Send, "m_iObserverMode", 6);
	SetEntityMoveType(client, MOVETYPE_OBSERVER);	
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
		Spectate(client);
		return true;
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
	return 0;
}

// Returns number of items added to the menu
int SpecMenuAddItems(int client, Menu menu, bool useFilter, char[] filter)
{
	char display[MAX_NAME_LENGTH + 4];
	int targetCount = 0;	
	int latestResult;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || i == client)
		{
			continue;
		}
		if (useFilter)
		{	
			FormatEx(display, sizeof(display), "%N", i);		
			if (StrContains(display, filter, false) != -1) 
			{
				if (IsFakeClient(i))
				{
					FormatEx(display, sizeof(display), "BOT %N", i);
				}
			}
			else // If it doesn't fit the filter, move on
			{
				continue;
			}
		}
		else
		{
			if (IsFakeClient(i))
			{
				FormatEx(display, sizeof(display), "BOT %N", i);
			}
			else
			{
				FormatEx(display, sizeof(display), "%N", i);
			}
		}
		latestResult = i;
		menu.AddItem(IntToStringEx(GetClientUserId(i)), display, ITEMDRAW_DEFAULT);
		targetCount++;
	}
	// The only spectate-able player is the latest result, this happens when the player issuing the command also fits in the filter
	if (targetCount == 1)
	{
		SpectatePlayer(client, latestResult);
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

		char targetName[MAX_TARGET_LENGTH];
		int targetList[1], targetCount;
		bool tnIsML;
		int flags = COMMAND_FILTER_NO_MULTI | COMMAND_FILTER_NO_IMMUNITY | COMMAND_FILTER_ALIVE;

		if ((targetCount = ProcessTargetString(
			specifiedPlayer,
			client, 
			targetList, 
			1, 
			flags,
			targetName,
			sizeof(targetName),
			tnIsML)) == 1)
		{
			SpectatePlayer(client, targetList[0]);
		}
		else if (targetCount == COMMAND_TARGET_AMBIGUOUS)
		{
			DisplaySpecMenu(client, true, specifiedPlayer);
		}
		else
		{
			ReplyToTargetError(client, targetCount);
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
	return Plugin_Handled;
} 