#include <sourcemod>

#include <gokz/core>
#include <gokz/racing>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Racing", 
	author = "DanZay", 
	description = "Lets players race against each other", 
	version = GOKZ_VERSION, 
	url = GOKZ_SOURCE_URL
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-racing.txt"

#include "gokz-racing/announce.sp"
#include "gokz-racing/api.sp"
#include "gokz-racing/commands.sp"
#include "gokz-racing/duel_menu.sp"
#include "gokz-racing/race.sp"
#include "gokz-racing/race_menu.sp"
#include "gokz-racing/racer.sp"



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNatives();
	RegPluginLibrary("gokz-racing");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-common.phrases");
	LoadTranslations("gokz-racing.phrases");
	
	CreateGlobalForwards();
	RegisterCommands();
	
	OnPluginStart_Race();
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



// =====[ CLIENT EVENTS ]=====

public void OnClientPutInServer(int client)
{
	OnClientPutInServer_Racer(client);
}

public void OnClientDisconnect(int client)
{
	OnClientDisconnect_Racer(client);
}

public Action GOKZ_OnTimerStart(int client, int course)
{
	Action action = OnTimerStart_Racer(client, course);
	if (action != Plugin_Continue)
	{
		return action;
	}
	
	return Plugin_Continue;
}

public void GOKZ_OnTimerStart_Post(int client, int course)
{
	OnTimerStart_Post_Racer(client);
}

public void GOKZ_OnTimerEnd_Post(int client, int course, float time, int teleportsUsed)
{
	FinishRacer(client, course);
}

public Action GOKZ_OnMakeCheckpoint(int client)
{
	Action action = OnMakeCheckpoint_Racer(client);
	if (action != Plugin_Continue)
	{
		return action;
	}
	
	return Plugin_Continue;
}

public void GOKZ_OnMakeCheckpoint_Post(int client)
{
	OnMakeCheckpoint_Post_Racer(client);
}

public Action GOKZ_OnUndoTeleport(int client)
{
	Action action = OnUndoTeleport_Racer(client);
	if (action != Plugin_Continue)
	{
		return action;
	}
	
	return Plugin_Continue;
}

public void GOKZ_RC_OnFinish(int client, int raceID, int place)
{
	OnFinish_Announce(client, raceID, place);
	OnFinish_Race(raceID);
}

public void GOKZ_RC_OnSurrender(int client, int raceID)
{
	OnSurrender_Announce(client, raceID);
}

public void GOKZ_RC_OnRequestReceived(int client, int raceID)
{
	OnRequestReceived_Announce(client, raceID);
}

public void GOKZ_RC_OnRequestAccepted(int client, int raceID)
{
	OnRequestAccepted_Announce(client, raceID);
	OnRequestAccepted_Race(raceID);
}

public void GOKZ_RC_OnRequestDeclined(int client, int raceID, bool timeout)
{
	OnRequestDeclined_Announce(client, raceID, timeout);
	OnRequestDeclined_Race(raceID);
}



// =====[ OTHER EVENTS ]=====

public void GOKZ_RC_OnRaceStarted(int raceID)
{
	OnRaceStarted_Announce(raceID);
}

public void GOKZ_RC_OnRaceAborted(int raceID)
{
	OnRaceAborted_Announce(raceID);
} 