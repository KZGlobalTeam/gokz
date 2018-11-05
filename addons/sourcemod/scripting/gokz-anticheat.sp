#include <sourcemod>

#include <colorvariables>
#include <gokz>

#include <movementapi>
#include <gokz/core>
#include <gokz/anticheat>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <gokz/localdb>
#include <sourcebanspp>
#include <updater>

#include <gokz/kzplayer>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Anti-Cheat", 
	author = "DanZay", 
	description = "Detects basic player movement cheats", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATE_URL "http://updater.gokz.org/gokz-anticheat.txt"

bool gB_GOKZLocalDB;
bool gB_SourceBansPP;
bool gB_SourceBans;

int gI_ButtonCount[MAXPLAYERS + 1];
int gI_ButtonsIndex[MAXPLAYERS + 1];
int gI_Buttons[MAXPLAYERS + 1][AC_MAX_BUTTON_SAMPLES];
int gI_OldButtons[MAXPLAYERS + 1];

int gI_BhopCount[MAXPLAYERS + 1];
int gI_BhopIndex[MAXPLAYERS + 1];
int gI_BhopLastTakeoffCmdnum[MAXPLAYERS + 1];
int gI_BhopLastRecordedBhopCmdnum[MAXPLAYERS + 1];
bool gB_BhopHitPerf[MAXPLAYERS + 1][AC_MAX_BHOP_SAMPLES];
int gI_BhopPreJumpInputs[MAXPLAYERS + 1][AC_MAX_BHOP_SAMPLES];
int gI_BhopPostJumpInputs[MAXPLAYERS + 1][AC_MAX_BHOP_SAMPLES];
bool gB_BhopPostJumpInputsPending[MAXPLAYERS + 1];

ConVar gCV_gokz_autoban;
ConVar gCV_gokz_autoban_duration;

#include "gokz-anticheat/api.sp"
#include "gokz-anticheat/bhop_tracking.sp"
#include "gokz-anticheat/commands.sp"



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNatives();
	RegPluginLibrary("gokz-anticheat");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("gokz-common.phrases");
	LoadTranslations("gokz-anticheat.phrases");
	
	CreateConVars();
	CreateGlobalForwards();
	RegisterCommands();
	
	AutoExecConfig(true, "gokz-anticheat", "sourcemod/gokz");
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	gB_GOKZLocalDB = LibraryExists("gokz-localdb");
	gB_SourceBansPP = LibraryExists("sourcebans++");
	gB_SourceBans = LibraryExists("sourcebans");
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			OnClientPutInServer(client);
		}
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	gB_GOKZLocalDB = gB_GOKZLocalDB || StrEqual(name, "gokz-localdb");
	gB_SourceBansPP = gB_SourceBansPP || StrEqual(name, "sourcebans++");
	gB_SourceBans = gB_SourceBans || StrEqual(name, "sourcebans");
}

public void OnLibraryRemoved(const char[] name)
{
	gB_GOKZLocalDB = gB_GOKZLocalDB && !StrEqual(name, "gokz-localdb");
	gB_SourceBansPP = gB_SourceBansPP && !StrEqual(name, "sourcebans++");
	gB_SourceBans = gB_SourceBans && !StrEqual(name, "sourcebans");
}



// =====[ CLIENT EVENTS ]=====

public void OnClientPutInServer(int client)
{
	OnClientPutInServer_BhopTracking(client);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	OnPlayerRunCmdPost_BhopTracking(client, cmdnum);
	gI_OldButtons[client] = buttons;
}

public void GOKZ_OnFirstSpawn(int client)
{
	GOKZ_PrintToChat(client, false, "%t", "Anti-Cheat Warning");
}

public void GOKZ_AM_OnPlayerSuspected(int client, ACReason reason, const char[] notes, const char[] stats)
{
	LogSuspicion(client, reason, notes, stats);
}



// =====[ PUBLIC ]=====

void SuspectPlayer(int client, ACReason reason, const char[] notes, const char[] stats)
{
	Call_OnPlayerSuspected(client, reason, notes, stats);
	
	if (gB_GOKZLocalDB)
	{
		GOKZ_DB_SetCheater(client, true);
	}
	
	if (gCV_gokz_autoban.BoolValue)
	{
		BanSuspect(client, reason);
	}
}



// =====[ PRIVATE ]=====

static void CreateConVars()
{
	gCV_gokz_autoban = CreateConVar("gokz_autoban", "1", "Whether to autoban players when they are suspected of cheating.", _, true, 0.0, true, 1.0);
	gCV_gokz_autoban_duration = CreateConVar("gokz_autoban_duration", "0", "Duration of anticheat autobans in minutes (0 for permanent).", _, true, 0.0);
}

static void LogSuspicion(int client, ACReason reason, const char[] notes, const char[] stats)
{
	char logPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, logPath, sizeof(logPath), AC_LOG_PATH);
	
	switch (reason)
	{
		case ACReason_BhopHack:LogToFileEx(logPath, "%L was suspected of bhop hacking. Notes - %s, Stats - %s", client, notes, stats);
		case ACReason_BhopMacro:LogToFileEx(logPath, "%L was suspected of bhop macroing. Notes - %s, Stats - %s", client, notes, stats);
	}
}

static void BanSuspect(int client, ACReason reason)
{
	switch (reason)
	{
		case ACReason_BhopHack:
		{
			AutoBanClient(client, "gokz-anticheat - Bhop hacking", "You have been banned for using a bhop hack");
		}
		case ACReason_BhopMacro:
		{
			AutoBanClient(client, "gokz-anticheat - Bhop macroing", "You have been banned for using a bhop macro");
		}
	}
}

static void AutoBanClient(int client, const char[] reason, const char[] kickMessage)
{
	if (gB_SourceBansPP)
	{
		SBPP_BanPlayer(0, client, gCV_gokz_autoban_duration.IntValue, reason);
	}
	else if (gB_SourceBans)
	{
		SBBanPlayer(0, client, gCV_gokz_autoban_duration.IntValue, reason);
	}
	else
	{
		BanClient(client, gCV_gokz_autoban_duration.IntValue, BANFLAG_AUTO, reason, kickMessage, "gokz-anticheat", 0);
	}
} 