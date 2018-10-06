#include <sourcemod>

#include <colorvariables>
#include <gokz>

#include <movementapi>
#include <gokz/core>
#include <gokz/antimacro>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <gokz/localdb>
#include <sourcebanspp>
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Anti-Macro", 
	author = "DanZay", 
	description = "GOKZ Macrodox Module", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATE_URL "http://updater.gokz.org/gokz-antimacro.txt"

#define BUTTON_SAMPLES 40
#define BHOP_GROUND_TICKS 4
#define BHOP_SAMPLES 30
#define LOG_PATH "logs/gokz-antimacro.log"

bool gB_GOKZLocalDB;
bool gB_SourceBansPP;
bool gB_SourceBans;

int gI_ButtonCount[MAXPLAYERS + 1];
int gI_ButtonsIndex[MAXPLAYERS + 1];
int gI_Buttons[MAXPLAYERS + 1][BUTTON_SAMPLES];
int gI_OldButtons[MAXPLAYERS + 1];

int gI_BhopCount[MAXPLAYERS + 1];
int gI_BhopIndex[MAXPLAYERS + 1];
int gI_BhopLastTakeoffCmdnum[MAXPLAYERS + 1];
int gI_BhopLastRecordedBhopCmdnum[MAXPLAYERS + 1];
bool gB_BhopHitPerf[MAXPLAYERS + 1][BHOP_SAMPLES];
int gI_BhopPreJumpInputs[MAXPLAYERS + 1][BHOP_SAMPLES];
int gI_BhopPostJumpInputs[MAXPLAYERS + 1][BHOP_SAMPLES];
bool gB_BhopPostJumpInputsPending[MAXPLAYERS + 1];

#include "gokz-antimacro/api.sp"
#include "gokz-antimacro/bhoptracking.sp"
#include "gokz-antimacro/commands.sp"
#include "gokz-antimacro/convars.sp"



// =========================  PLUGIN  ========================= //

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNatives();
	RegPluginLibrary("gokz-antimacro");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("gokz-core.phrases");
	LoadTranslations("gokz-antimacro.phrases");
	
	CreateGlobalForwards();
	CreateConVars();
	CreateCommands();
	
	AutoExecConfig(true, "gokz-antimacro", "sourcemod/gokz");
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
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	else if (StrEqual(name, "gokz-localdb"))
	{
		gB_GOKZLocalDB = true;
	}
	else if (StrEqual(name, "sourcebans++"))
	{
		gB_SourceBansPP = true;
	}
	else if (StrEqual(name, "sourcebans"))
	{
		gB_SourceBans = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "gokz-localdb"))
	{
		gB_GOKZLocalDB = false;
	}
	else if (StrEqual(name, "sourcebans++"))
	{
		gB_SourceBansPP = false;
	}
	else if (StrEqual(name, "sourcebans"))
	{
		gB_SourceBans = false;
	}
}



// =========================  CLIENT  ========================= //

public void OnClientPutInServer(int client)
{
	OnClientPutInServer_BhopTracking(client);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	OnPlayerRunCmd_BhopTracking(client, cmdnum);
	gI_OldButtons[client] = buttons;
}

public void GOKZ_OnFirstSpawn(int client)
{
	GOKZ_PrintToChat(client, false, "%t", "Antimacro Warning");
}

public void GOKZ_AM_OnPlayerSuspected(int client, AMReason reason, const char[] notes, const char[] stats)
{
	LogSuspicion(client, reason, notes, stats);
}



// =========================  PUBLIC  ========================= //

void SuspectPlayer(int client, AMReason reason, const char[] notes, const char[] stats)
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



// =========================  PRIVATE  ========================= //

static void LogSuspicion(int client, AMReason reason, const char[] notes, const char[] stats)
{
	char logPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, logPath, sizeof(logPath), LOG_PATH);
	
	switch (reason)
	{
		case AMReason_BhopHack:LogToFileEx(logPath, "%L was suspected of bhop hacking. Notes - %s, Stats - %s", client, notes, stats);
		case AMReason_BhopMacro:LogToFileEx(logPath, "%L was suspected of bhop macroing. Notes - %s, Stats - %s", client, notes, stats);
	}
}

static void BanSuspect(int client, AMReason reason)
{
	switch (reason)
	{
		case AMReason_BhopHack:
		{
			AutoBanClient(client, "gokz-antimacro - Bhop hacking", "You have been banned for using a bhop hack");
		}
		case AMReason_BhopMacro:
		{
			AutoBanClient(client, "gokz-antimacro - Bhop macroing", "You have been banned for using a bhop macro");
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
		BanClient(client, gCV_gokz_autoban_duration.IntValue, BANFLAG_AUTO, reason, kickMessage, "gokz-antimacro", 0);
	}
} 