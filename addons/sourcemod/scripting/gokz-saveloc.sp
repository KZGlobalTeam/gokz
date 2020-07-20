#include <sourcemod>

#include <cstrike>
#include <sdktools>

#include <gokz/core>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>



public Plugin myinfo = 
{
	name = "GOKZ SaveLoc", 
	author = "JWL", 
	description = "Allows players to save/load locations that preserve position, angles, and velocity", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-saveloc.txt"

#define MAX_LOCATION_NAME_LENGTH 32

ArrayList gA_Position;
ArrayList gA_Angles;
ArrayList gA_Velocity;
ArrayList gF_DuckSpeed;
ArrayList gF_Stamina;
ArrayList gA_LocationName;
ArrayList gA_LocationCreator;
ArrayList gA_MoveType;
ArrayList gA_LadderNormal;
bool gB_LocMenuOpen[MAXPLAYERS + 1];
int gI_MostRecentLocation[MAXPLAYERS + 1];



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-saveloc");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-saveloc.phrases");
	
	HookEvents();
	RegisterCommands();
	CreateArrays();
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

public void OnMapStart()
{
	ClearLocations();
}



// =====[ CLIENT EVENTS ]=====

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	CloseLocMenu(client);
}

public void OnPlayerJoinTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = event.GetInt("team");
	
	if (team == CS_TEAM_SPECTATOR)
	{
		CloseLocMenu(client);
	}
}

public Action GOKZ_OnTimerStart(int client, int course)
{
	CloseLocMenu(client);
}



// =====[ GENERAL ]=====

void HookEvents()
{
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_team", OnPlayerJoinTeam);
}



// =====[ COMMANDS ]=====

void RegisterCommands()
{
	RegConsoleCmd("sm_saveloc", Command_SaveLoc, "[KZ] Save location. Usage: !saveloc <name>");
	RegConsoleCmd("sm_loadloc", Command_LoadLoc, "[KZ] Load location. Usage: !loadloc <#id OR name>");
	RegConsoleCmd("sm_locmenu", Command_LocMenu, "[KZ] Open location menu.");
	RegConsoleCmd("sm_nameloc", Command_NameLoc, "[KZ] Name location. Usage: !nameloc <#id> <name>");
}

public Action Command_SaveLoc(int client, int args)
{
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if (args == 0)
	{
		// save location with empty <name>
		SaveLocation(client, "");
	}
	else if (args == 1)
	{
		// get location <name>
		char arg[MAX_LOCATION_NAME_LENGTH];
		GetCmdArg(1, arg, sizeof(arg));
		
		if (IsValidLocationName(arg))
		{
			// save location with <name>
			SaveLocation(client, arg);
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "NameLoc - Naming Format");
		}
	}
	else
	{
		GOKZ_PrintToChat(client, true, "%t", "SaveLoc - Usage");
	}
	
	return Plugin_Handled;
}

public Action Command_LoadLoc(int client, int args)
{
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	else if (!IsPlayerAlive(client))
	{
		GOKZ_PrintToChat(client, true, "%t", "Must Be Alive");
		return Plugin_Handled;
	}
	else if (gA_Position.Length == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "No Locations Found");
		return Plugin_Handled;
	}
	
	if (GOKZ_GetTimerRunning(client))
	{
		GOKZ_PrintToChat(client, true, "%t", "Timer Running");
		return Plugin_Handled;
	}
	
	if (args == 0)
	{
		// load most recent location
		int id = gI_MostRecentLocation[client];
		LoadLocation(client, id);
	}
	else if (args == 1)
	{
		// get location <#id OR name>
		char arg[MAX_LOCATION_NAME_LENGTH];
		GetCmdArg(1, arg, sizeof(arg));
		int id;
		
		if (arg[0] == '#')
		{
			// load location <#id>
			id = StringToInt(arg[1]);
		}
		else
		{
			// load location <name>
			id = gA_LocationName.FindString(arg);
		}
		
		if (IsValidLocationId(id))
		{
			LoadLocation(client, id);
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Location Not Found");
		}
	}
	else
	{
		GOKZ_PrintToChat(client, true, "%t", "LoadLoc - Usage");
	}
	
	return Plugin_Handled;
}

public Action Command_NameLoc(int client, int args)
{
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	else if (gA_Position.Length == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "No Locations Found");
		return Plugin_Handled;
	}
	
	if (args == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "NameLoc - Usage");
	}
	else if (args == 1)
	{
		// name most recent location
		char arg[MAX_LOCATION_NAME_LENGTH];
		GetCmdArg(1, arg, sizeof(arg));
		int id = gI_MostRecentLocation[client];
		
		if (IsValidLocationName(arg) && IsClientLocationCreator(client, id))
		{
			NameLocation(client, id, arg);
		}
		else if (!IsClientLocationCreator(client, id))
		{
			GOKZ_PrintToChat(client, true, "%t", "NameLoc - Not Creator");
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "NameLoc - Naming Format");
		}
	}
	else if (args == 2)
	{
		// name specified location
		char arg1[MAX_LOCATION_NAME_LENGTH];
		char arg2[MAX_LOCATION_NAME_LENGTH];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		int id = StringToInt(arg1[1]);
		
		if (IsValidLocationId(id))
		{
			
			if (IsValidLocationName(arg2) && IsClientLocationCreator(client, id))
			{
				NameLocation(client, id, arg2);
			}
			else if (!IsClientLocationCreator(client, id))
			{
				GOKZ_PrintToChat(client, true, "%t", "NameLoc - Not Creator");
			}
			else
			{
				GOKZ_PrintToChat(client, true, "%t", "NameLoc - Naming Format");
			}
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Location Not Found");
		}
	}
	else
	{
		GOKZ_PrintToChat(client, true, "%t", "NameLoc - Usage");
	}
	
	return Plugin_Handled;
}

public Action Command_LocMenu(int client, int args)
{
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	else if (!IsPlayerAlive(client))
	{
		GOKZ_PrintToChat(client, true, "%t", "Must Be Alive");
		return Plugin_Handled;
	}
	else if (gA_Position.Length == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "No Locations Found");
		return Plugin_Handled;
	}
	
	if (GOKZ_GetTimerRunning(client))
	{
		GOKZ_PrintToChat(client, true, "%t", "Timer Running");
		return Plugin_Handled;
	}
	
	ShowLocMenu(client);
	
	return Plugin_Handled;
}



// ====[ SAVELOC MENU ]====

void ShowLocMenu(int client)
{
	Menu locMenu = new Menu(LocMenuHandler, MENU_ACTIONS_ALL);
	locMenu.SetTitle("%t", "LocMenu - Title");
	
	// fill the menu with all locations
	for (int i = 0; i < gA_Position.Length; i++)
	{
		char item[MAX_LOCATION_NAME_LENGTH];
		Format(item, sizeof(item), "%i", i);
		locMenu.AddItem(item, item);
	}
	
	// calculate which page of the menu contains client's most recent location
	int firstItem;
	if (gI_MostRecentLocation[client] > 5)
	{
		firstItem = gI_MostRecentLocation[client] - (gI_MostRecentLocation[client] % 6);
	}
	
	locMenu.DisplayAt(client, firstItem, MENU_TIME_FOREVER);
}



// ====[ SAVELOC MENU HANDLER ]====

public int LocMenuHandler(Menu menu, MenuAction action, int client, int choice)
{
	switch (action)
	{
		case MenuAction_Display:
		{
			gB_LocMenuOpen[client] = true;
		}
		
		case MenuAction_DisplayItem:
		{
			char item[MAX_LOCATION_NAME_LENGTH];
			menu.GetItem(choice, item, sizeof(item));
			
			int id = StringToInt(item);
			char name[MAX_LOCATION_NAME_LENGTH];
			gA_LocationName.GetString(id, name, sizeof(name));
			
			if (id == gI_MostRecentLocation[client])
			{
				Format(item, sizeof(item), "> #%i %s", id, name);
			}
			else
			{
				Format(item, sizeof(item), "#%i %s", id, name);
			}
			
			return RedrawMenuItem(item);
		}
		
		case MenuAction_Select:
		{
			char item[MAX_LOCATION_NAME_LENGTH];
			menu.GetItem(choice, item, sizeof(item));
			ReplaceString(item, sizeof(item), "#", "");
			int id = StringToInt(item);
			
			LoadLocation(client, id);
		}
		
		case MenuAction_Cancel:
		{
			gB_LocMenuOpen[client] = false;
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}



// ====[ SAVE LOCATION ]====

void SaveLocation(int client, char[] name)
{
	float position[3];
	float angles[3];
	float velocity[3];
	float ladderNormal[3];
	float duckSpeed;
	float stamina;
	char creator[MAX_NAME_LENGTH];
	int id = gA_Position.Length;
	MoveType movetype;
	
	GetClientAbsOrigin(client, position);
	GetClientEyeAngles(client, angles);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	duckSpeed = Movement_GetDuckSpeed(client);
	stamina = GetEntPropFloat(client, Prop_Send, "m_flStamina");
	GetClientName(client, creator, sizeof(creator));
	movetype = Movement_GetMovetype(client);
	GetEntPropVector(client, Prop_Send, "m_vecLadderNormal", ladderNormal);
	
	gI_MostRecentLocation[client] = id;
	gA_Position.PushArray(position);
	gA_Angles.PushArray(angles);
	gA_Velocity.PushArray(velocity);
	gF_DuckSpeed.Push(duckSpeed);
	gF_Stamina.Push(stamina);
	gA_LocationName.PushString(name);
	gA_LocationCreator.PushString(creator);
	gA_MoveType.Push(movetype);
	gA_LadderNormal.PushArray(ladderNormal);
	
	GOKZ_PrintToChat(client, true, "%t", "SaveLoc - ID Name", id, name);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		RefreshLocMenu(i);
	}
}



// ====[ LOAD LOCATION ]====

bool LoadLocation(int client, int id)
{
	if (!IsPlayerAlive(client))
	{
		GOKZ_PrintToChat(client, true, "%t", "Must Be Alive");
		return false;
	}
	
	if (GOKZ_GetTimerRunning(client))
	{
		GOKZ_PrintToChat(client, true, "%t", "Timer Running");
		return false;
	}
	
	float position[3];
	float angles[3];
	float velocity[3];
	float ladderNormal[3];
	float duckSpeed;
	float stamina;
	char name[MAX_LOCATION_NAME_LENGTH];
	char creator[MAX_NAME_LENGTH];
	char clientName[MAX_NAME_LENGTH];
	MoveType movetype;
	
	gA_Position.GetArray(id, position, sizeof(position));
	gA_Angles.GetArray(id, angles, sizeof(angles));
	gA_Velocity.GetArray(id, velocity, sizeof(velocity));
	duckSpeed = gF_DuckSpeed.Get(id);
	stamina = gF_Stamina.Get(id);
	gA_LocationName.GetString(id, name, sizeof(name));
	gA_LocationCreator.GetString(id, creator, sizeof(creator));
	GetClientName(client, clientName, sizeof(clientName));
	movetype = gA_MoveType.Get(id);
	gA_LadderNormal.GetArray(id, ladderNormal, sizeof(ladderNormal));
	
	TeleportEntity(client, position, angles, velocity);
	Movement_SetDuckSpeed(client, duckSpeed);
	SetEntPropFloat(client, Prop_Send, "m_flStamina", stamina);
	Movement_SetMovetype(client, movetype);
	SetEntPropVector(client, Prop_Send, "m_vecLadderNormal", ladderNormal);
	
	// print message if loading new location
	if (gI_MostRecentLocation[client] != id)
	{
		gI_MostRecentLocation[client] = id;
		
		if (StrEqual(clientName, creator))
		{
			GOKZ_PrintToChat(client, true, "%t", "LoadLoc - ID Name", id, name);
		}
		else
		{
			if (StrEqual(name, ""))
			{
				GOKZ_PrintToChat(client, true, "%t", "LoadLoc - ID Creator", id, creator);
			}
			else
			{
				GOKZ_PrintToChat(client, true, "%t", "LoadLoc - ID Name Creator", id, name, creator);
			}
		}
	}
	
	RefreshLocMenu(client);
	
	return true;
}



// ====[ NAME LOCATION ]====

void NameLocation(int client, int id, char[] name)
{
	gA_LocationName.SetString(id, name);
	
	GOKZ_PrintToChat(client, true, "%t", "NameLoc - ID Name", id, name);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		RefreshLocMenu(i);
	}
}



// =====[ HELPER FUNCTIONS ]=====

void CreateArrays()
{
	gA_Position = new ArrayList(3);
	gA_Angles = new ArrayList(3);
	gA_Velocity = new ArrayList(3);
	gF_DuckSpeed = new ArrayList(1);
	gF_Stamina = new ArrayList(1);
	gA_LocationName = new ArrayList(ByteCountToCells(MAX_LOCATION_NAME_LENGTH));
	gA_LocationCreator = new ArrayList(ByteCountToCells(MAX_NAME_LENGTH));
	gA_MoveType = new ArrayList(1);
	gA_LadderNormal = new ArrayList(3);
}

void ClearLocations()
{
	gA_Position.Clear();
	gA_Angles.Clear();
	gA_Velocity.Clear();
	gF_DuckSpeed.Clear();
	gF_Stamina.Clear();
	gA_LocationName.Clear();
	gA_LocationCreator.Clear();
	gA_MoveType.Clear();
	gA_LadderNormal.Clear();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		gI_MostRecentLocation[i] = -1;
		gB_LocMenuOpen[i] = false;
	}
}

void RefreshLocMenu(int client)
{
	if (gB_LocMenuOpen[client])
	{
		ShowLocMenu(client);
	}
}

void CloseLocMenu(int client)
{
	if (gB_LocMenuOpen[client])
	{
		CancelClientMenu(client, true);
		gB_LocMenuOpen[client] = false;
	}
}

bool IsValidLocationId(int id)
{
	return !(id < 0) && !(id > gA_Position.Length - 1);
}

bool IsValidLocationName(char[] name)
{
	// check if location name starts with letter and is unique
	return IsCharAlpha(name[0]) && gA_LocationName.FindString(name) == -1;
}

bool IsClientLocationCreator(int client, int id)
{
	char clientName[MAX_NAME_LENGTH];
	char creator[MAX_NAME_LENGTH];
	
	GetClientName(client, clientName, sizeof(clientName));
	gA_LocationCreator.GetString(id, creator, sizeof(creator));
	
	return StrEqual(clientName, creator);
} 