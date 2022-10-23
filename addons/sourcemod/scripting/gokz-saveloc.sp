#include <sourcemod>

#include <cstrike>
#include <sdktools>

#include <gokz/core>
#include <gokz/kzplayer>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>
#include <gokz/hud>
#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name = "GOKZ SaveLoc", 
	author = "JWL", 
	description = "Allows players to save/load locations that preserve position, angles, and velocity", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-saveloc.txt"
#define LOADLOC_INVALIDATE_DURATION 1.0
#define MAX_LOCATION_NAME_LENGTH 32

enum struct Location {
	// Location name must be first for FindString to work.
	char locationName[MAX_LOCATION_NAME_LENGTH];
	char locationCreator[MAX_NAME_LENGTH];
	
	// GOKZ related states
	int mode;
	int course;
	float currentTime;
	ArrayList checkpointData;
	int checkpointCount;
	int teleportCount;
	ArrayList undoTeleportData;

	// Movement related states
	int groundEnt;
	int flags;
	float position[3];
	float angles[3];
	float velocity[3];
	float duckAmount;
	bool ducking;
	bool ducked;
	float lastDuckTime;
	float duckSpeed;
	float stamina;
	MoveType movetype;
	float ladderNormal[3];
	int collisionGroup;
	float waterJumpTime;
	bool hasWalkMovedSinceLastJump;
	float ignoreLadderJumpTimeOffset;
	float lastPositionAtFullCrouchSpeed[2];

	void Create(int client, int target)
	{
		GetClientName(client, this.locationCreator, sizeof(Location::locationCreator));
		this.groundEnt = GetEntPropEnt(target, Prop_Data, "m_hGroundEntity");
		this.flags = GetEntityFlags(target);
		this.mode = GOKZ_GetCoreOption(target, Option_Mode);
		this.course = GOKZ_GetCourse(target);
		GetClientAbsOrigin(target, this.position);
		GetClientEyeAngles(target, this.angles);
		GetEntPropVector(target, Prop_Data, "m_vecVelocity", this.velocity);
		this.duckAmount = GetEntPropFloat(target, Prop_Send, "m_flDuckAmount");
		this.ducking = !!GetEntProp(target, Prop_Send, "m_bDucking");
		this.ducked = !!GetEntProp(target, Prop_Send, "m_bDucked");
		this.lastDuckTime = GetEntPropFloat(target, Prop_Send, "m_flLastDuckTime");
		this.duckSpeed = Movement_GetDuckSpeed(target);
		this.stamina = GetEntPropFloat(target, Prop_Send, "m_flStamina");
		this.movetype = Movement_GetMovetype(target);
		GetEntPropVector(target, Prop_Send, "m_vecLadderNormal", this.ladderNormal);
		this.collisionGroup = GetEntProp(target, Prop_Send, "m_CollisionGroup");
		this.waterJumpTime = GetEntPropFloat(target, Prop_Data, "m_flWaterJumpTime");
		this.hasWalkMovedSinceLastJump = !!GetEntProp(target, Prop_Data, "m_bHasWalkMovedSinceLastJump");
		this.ignoreLadderJumpTimeOffset = GetEntPropFloat(target, Prop_Data, "m_ignoreLadderJumpTime") - GetGameTime();
		GetLastPositionAtFullCrouchSpeed(target, this.lastPositionAtFullCrouchSpeed);
		
		if (GOKZ_GetTimerRunning(target))
		{
			this.currentTime = GOKZ_GetTime(target);
		}
		else
		{
			this.currentTime = -1.0;
		}
		this.checkpointData = GOKZ_GetCheckpointData(target);
		this.checkpointCount = GOKZ_GetCheckpointCount(target);
		this.teleportCount = GOKZ_GetTeleportCount(target);
		this.undoTeleportData = GOKZ_GetUndoTeleportData(target);
	}

	bool Load(int client)
	{
		// Safeguard Check
		if (GOKZ_GetCoreOption(client, Option_Safeguard) > Safeguard_Disabled && GOKZ_GetTimerRunning(client) && GOKZ_GetValidTimer(client))
		{
			GOKZ_PrintToChat(client, true, "%t", "Safeguard - Blocked");
			GOKZ_PlayErrorSound(client);
			return false;
		}
		if (!GOKZ_SetMode(client, this.mode))
		{
			GOKZ_PrintToChat(client, true, "%t", "LoadLoc - Mode Not Available");
		}
		GOKZ_SetCourse(client, this.course);
		if (this.currentTime >= 0.0)
		{
			GOKZ_SetTime(client, this.currentTime);
		}
		GOKZ_SetCheckpointData(client, this.checkpointData, GOKZ_CHECKPOINT_VERSION);
		GOKZ_SetCheckpointCount(client, this.checkpointCount);
		GOKZ_SetTeleportCount(client, this.teleportCount);
		GOKZ_SetUndoTeleportData(client, this.undoTeleportData, GOKZ_CHECKPOINT_VERSION);

		SetEntPropEnt(client, Prop_Data, "m_hGroundEntity", this.groundEnt);
		SetEntityFlags(client, this.flags);
		TeleportEntity(client, this.position, this.angles, this.velocity);
		SetEntPropFloat(client, Prop_Send, "m_flDuckAmount", this.duckAmount);
		SetEntProp(client, Prop_Send, "m_bDucking", this.ducking);
		SetEntProp(client, Prop_Send, "m_bDucked", this.ducked);
		SetEntPropFloat(client, Prop_Send, "m_flLastDuckTime", this.lastDuckTime);
		Movement_SetDuckSpeed(client, this.duckSpeed);
		SetEntPropFloat(client, Prop_Send, "m_flStamina", this.stamina);
		Movement_SetMovetype(client, this.movetype);
		SetEntPropVector(client, Prop_Send, "m_vecLadderNormal", this.ladderNormal);
		SetEntProp(client, Prop_Send, "m_CollisionGroup", this.collisionGroup);
		SetEntPropFloat(client, Prop_Data, "m_flWaterJumpTime", this.waterJumpTime);
		SetEntProp(client, Prop_Data, "m_bHasWalkMovedSinceLastJump", this.hasWalkMovedSinceLastJump);
		SetEntPropFloat(client, Prop_Data, "m_ignoreLadderJumpTime", this.ignoreLadderJumpTimeOffset + GetGameTime());
		SetLastPositionAtFullCrouchSpeed(client, this.lastPositionAtFullCrouchSpeed);

		GOKZ_InvalidateRun(client);
		return true;
	}
}

ArrayList gA_Locations;
bool gB_LocMenuOpen[MAXPLAYERS + 1];
bool gB_UsedLoc[MAXPLAYERS + 1];
int gI_MostRecentLocation[MAXPLAYERS + 1];
float gF_LastLoadlocTime[MAXPLAYERS + 1];

bool gB_GOKZHUD;

// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-saveloc");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-common.phrases");
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
	gB_GOKZHUD = LibraryExists("gokz-hud");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
	gB_GOKZHUD = gB_GOKZHUD || StrEqual(name, "gokz-hud");
}

public void OnLibraryRemoved(const char[] name)
{
	gB_GOKZHUD = gB_GOKZHUD && !StrEqual(name, "gokz-hud");
}

public void OnMapStart()
{
	ClearLocations();
}



// =====[ CLIENT EVENTS ]=====

public void OnClientPutInServer(int client)
{
	gF_LastLoadlocTime[client] = 0.0;
}

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
	gB_UsedLoc[client] = false;
	if (GetGameTime() < gF_LastLoadlocTime[client] + LOADLOC_INVALIDATE_DURATION)
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action GOKZ_OnTimerEnd(int client, int course, float time)
{
	if (gB_UsedLoc[client])
	{
		PrintEndTimeString_SaveLoc(client, course, time);
	}
	return Plugin_Continue;
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
	RegConsoleCmd("sm_prevloc", Command_PrevLoc, "[KZ] Go back to the previous location.");
	RegConsoleCmd("sm_nextloc", Command_NextLoc, "[KZ] Go forward to the next location.");
	RegConsoleCmd("sm_locmenu", Command_LocMenu, "[KZ] Open location menu.");
	RegConsoleCmd("sm_nameloc", Command_NameLoc, "[KZ] Name location. Usage: !nameloc <#id> <name>");
}

public Action Command_SaveLoc(int client, int args)
{
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	int target = -1;
	if (!IsPlayerAlive(client))
	{
		KZPlayer player = KZPlayer(client);
		target = player.ObserverTarget;
		if (target == -1)
		{
			GOKZ_PrintToChat(client, true, "%t", "Must Be Alive");
			GOKZ_PlayErrorSound(client);
			return Plugin_Handled;
		}
	}
	
	if (args == 0)
	{
		// save location with empty <name>
		SaveLocation(client, "", target);
	}
	else if (args == 1)
	{
		// get location <name>
		char arg[MAX_LOCATION_NAME_LENGTH];
		GetCmdArg(1, arg, sizeof(arg));
		
		if (IsValidLocationName(arg))
		{
			// save location with <name>
			SaveLocation(client, arg, target);
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
	else if (gA_Locations.Length == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "No Locations Found");
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
			id = gA_Locations.FindString(arg);
		}
		
		if (IsValidLocationId(id))
		{
			if (LoadLocation(client, id))
			{
				gF_LastLoadlocTime[client] = GetGameTime();
			}
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

public Action Command_PrevLoc(int client, int args)
{
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	else if (gA_Locations.Length == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "No Locations Found");
		return Plugin_Handled;
	}
	else if (gI_MostRecentLocation[client] <= 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "PrevLoc - Can't Prev Location (No Location Found)");
		return Plugin_Handled;
	}
	LoadLocation(client, gI_MostRecentLocation[client] - 1);
	return Plugin_Handled;
}

public Action Command_NextLoc(int client, int args)
{
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	else if (gA_Locations.Length == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "No Locations Found");
		return Plugin_Handled;
	}
	else if (gI_MostRecentLocation[client] >= gA_Locations.Length - 1)
	{
		GOKZ_PrintToChat(client, true, "%t", "NextLoc - Can't Next Location (No Location Found)");
		return Plugin_Handled;
	}
	LoadLocation(client, gI_MostRecentLocation[client] + 1);
	return Plugin_Handled;
}

public Action Command_NameLoc(int client, int args)
{
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	else if (gA_Locations.Length == 0)
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
	else if (gA_Locations.Length == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "No Locations Found");
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
	for (int i = 0; i < gA_Locations.Length; i++)
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
			Location loc;
			char item[MAX_LOCATION_NAME_LENGTH];
			menu.GetItem(choice, item, sizeof(item));
			
			int id = StringToInt(item);
			gA_Locations.GetArray(id, loc);
			char name[MAX_LOCATION_NAME_LENGTH];
			strcopy(name, sizeof(name), loc.locationName);
			
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

void SaveLocation(int client, char[] name, int target)
{
	Location loc;
	if (target == -1)
	{
		target = client;
	}
	loc.Create(client, target);
	strcopy(loc.locationName, sizeof(Location::locationName), name);
	GetClientName(client, loc.locationCreator, sizeof(loc.locationCreator));
	gA_Locations.PushArray(loc);
	gI_MostRecentLocation[client] = gA_Locations.Length - 1;

	GOKZ_PrintToChat(client, true, "%t", "SaveLoc - ID Name", gA_Locations.Length - 1, name);
	
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
	char clientName[MAX_NAME_LENGTH];
	
	GetClientName(client, clientName, sizeof(clientName));
	Location loc;
	gA_Locations.GetArray(id, loc);
	if (loc.Load(client))
	{
		gB_UsedLoc[client] = true;
		if (gB_GOKZHUD)
		{
			GOKZ_HUD_ForceUpdateTPMenu(client);
		}
	}
	else
	{
		return false;
	}
	// print message if loading new location
	if (gI_MostRecentLocation[client] != id)
	{
		gI_MostRecentLocation[client] = id;
		
		if (StrEqual(clientName, loc.locationCreator))
		{
			GOKZ_PrintToChat(client, true, "%t", "LoadLoc - ID Name", id, loc.locationName);
		}
		else
		{
			if (StrEqual(loc.locationName, ""))
			{
				GOKZ_PrintToChat(client, true, "%t", "LoadLoc - ID Creator", id, loc.locationCreator);
			}
			else
			{
				GOKZ_PrintToChat(client, true, "%t", "LoadLoc - ID Name Creator", id, loc.locationName, loc.locationCreator);
			}
		}
	}
	
	RefreshLocMenu(client);
	
	return true;
}



// ====[ NAME LOCATION ]====

void NameLocation(int client, int id, char[] name)
{
	Location loc;
	gA_Locations.GetArray(id, loc);
	strcopy(loc.locationName, sizeof(Location::locationName), name);
	
	GOKZ_PrintToChat(client, true, "%t", "NameLoc - ID Name", id, name);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		RefreshLocMenu(i);
	}
}



// =====[ HELPER FUNCTIONS ]=====

void CreateArrays()
{
	gA_Locations = new ArrayList(sizeof(Location));
}

void ClearLocations()
{
	Location loc;
	for (int i = 0; i < gA_Locations.Length; i++)
	{
		// Prevent memory leak
		gA_Locations.GetArray(i, loc);
		delete loc.checkpointData;
	}
	gA_Locations.Clear();
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
	return !(id < 0) && !(id > gA_Locations.Length - 1);
}

bool IsValidLocationName(char[] name)
{
	// check if location name starts with letter and is unique
	return IsCharAlpha(name[0]) && gA_Locations.FindString(name) == -1;
}

bool IsClientLocationCreator(int client, int id)
{
	char clientName[MAX_NAME_LENGTH];
	Location loc;
	gA_Locations.GetArray(id, loc);
	GetClientName(client, clientName, sizeof(clientName));
	
	return StrEqual(clientName, loc.locationCreator);
} 

void GetLastPositionAtFullCrouchSpeed(int client, float origin[2])
{
	// m_vecLastPositionAtFullCrouchSpeed is right after m_flDuckSpeed.
	int baseOffset = FindSendPropInfo("CBasePlayer", "m_flDuckSpeed");
	origin[0] = GetEntDataFloat(client, baseOffset + 4);
	origin[1] = GetEntDataFloat(client, baseOffset + 8);
}

void SetLastPositionAtFullCrouchSpeed(int client, float origin[2])
{
	int baseOffset = FindSendPropInfo("CBasePlayer", "m_flDuckSpeed");
	SetEntDataFloat(client, baseOffset + 4, origin[0]);
	SetEntDataFloat(client, baseOffset + 8, origin[1]);
}

// ====[ PRIVATE ]====

static void PrintEndTimeString_SaveLoc(int client, int course, float time)
{
	if (course == 0)
	{
		switch (GOKZ_GetTimeType(client))
		{
			case TimeType_Nub:
			{
				GOKZ_PrintToChat(client, true, "%t", "Beat Map (NUB)", 
					client, 
					GOKZ_FormatTime(time), 
					gC_ModeNamesShort[GOKZ_GetCoreOption(client, Option_Mode)]);
			}
			case TimeType_Pro:
			{
				GOKZ_PrintToChat(client, true, "%t", "Beat Map (PRO)", 
					client, 
					GOKZ_FormatTime(time), 
					gC_ModeNamesShort[GOKZ_GetCoreOption(client, Option_Mode)]);
			}
		}
	}
	else
	{
		switch (GOKZ_GetTimeType(client))
		{
			case TimeType_Nub:
			{
				GOKZ_PrintToChat(client, true, "%t", "Beat Bonus (NUB)", 
					client, 
					GOKZ_GetCourse(client), 
					GOKZ_FormatTime(time), 
					gC_ModeNamesShort[GOKZ_GetCoreOption(client, Option_Mode)]);
			}
			case TimeType_Pro:
			{
				GOKZ_PrintToChat(client, true, "%t", "Beat Bonus (PRO)", 
					client, 
					GOKZ_GetCourse(client), 
					GOKZ_FormatTime(time), 
					gC_ModeNamesShort[GOKZ_GetCoreOption(client, Option_Mode)]);
			}
		}
	}
} 
