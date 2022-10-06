#include <sourcemod>

#include <cstrike>
#include <sdktools>

#include <gokz/core>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Goto", 
	author = "DanZay", 
	description = "Allows players to teleport to another player", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-goto.txt"



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-goto");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("gokz-common.phrases");
	LoadTranslations("gokz-goto.phrases");
	
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



// =====[ GOTO ]=====

// Returns whether teleport to target was successful
bool GotoPlayer(int client, int target, bool printMessage = true)
{
	if (GOKZ_GetCoreOption(client, Option_Safeguard) > Safeguard_Disabled && GOKZ_GetTimerRunning(client) && GOKZ_GetValidTimer(client))
	{
		if (printMessage)
		{
			GOKZ_PrintToChat(client, true, "%t", "Safeguard - Blocked");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	if (target == client)
	{
		if (printMessage)
		{
			GOKZ_PrintToChat(client, true, "%t", "Goto Failure (Not Yourself)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	if (!IsPlayerAlive(target))
	{
		if (printMessage)
		{
			GOKZ_PrintToChat(client, true, "%t", "Goto Failure (Dead)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	
	float targetOrigin[3];
	float targetAngles[3];
	
	Movement_GetOrigin(target, targetOrigin);
	Movement_GetEyeAngles(target, targetAngles);
	
	if (!IsPlayerAlive(client))
	{
		GOKZ_RespawnPlayer(client);
	}
	
	TeleportPlayer(client, targetOrigin, targetAngles);
	
	GOKZ_PrintToChat(client, true, "%t", "Goto Success", target);
	
	if (GOKZ_GetTimerRunning(client))
	{
		GOKZ_PrintToChat(client, true, "%t", "Timer Stopped (Goto)");
		GOKZ_StopTimer(client);
	}
	
	return true;
}



// =====[ GOTO MENU ]=====

int DisplayGotoMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Goto);
	menu.SetTitle("%T", "Goto Menu - Title", client);
	int menuItems = GotoMenuAddItems(client, menu);
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

public int MenuHandler_Goto(Menu menu, MenuAction action, int param1, int param2)
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
			DisplayGotoMenu(param1);
		}
		else if (!GotoPlayer(param1, target))
		{
			DisplayGotoMenu(param1);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

// Returns number of items added to the menu
int GotoMenuAddItems(int client, Menu menu)
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
	RegConsoleCmd("sm_goto", CommandGoto, "[KZ] Teleport to another player. Usage: !goto <player>");
}

public Action CommandGoto(int client, int args)
{
	// If no arguments, display the goto menu
	if (args < 1)
	{
		if (DisplayGotoMenu(client) == 0)
		{
			// No targets, so show error
			GOKZ_PrintToChat(client, true, "%t", "No Players Found");
			GOKZ_PlayErrorSound(client);
		}
	}
	// Otherwise try to teleport to the specified player
	else
	{
		char specifiedPlayer[MAX_NAME_LENGTH];
		GetCmdArg(1, specifiedPlayer, sizeof(specifiedPlayer));
		
		int target = FindTarget(client, specifiedPlayer, false, false);
		if (target != -1)
		{
			GotoPlayer(client, target);
		}
	}
	return Plugin_Handled;
} 