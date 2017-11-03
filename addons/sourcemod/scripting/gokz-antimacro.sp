#include <sourcemod>

#include <colorvariables>
#include <gokz>

#include <movementapi>
#include <gokz/core>
#include <gokz/antimacro>
#undef REQUIRE_PLUGIN
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

#define UPDATE_URL "http://updater.gokz.global/gokz-antimacro.txt"

#define BUTTON_SAMPLES 50
#define BHOP_GROUND_TICKS 4
#define BHOP_SAMPLES 20
#define LOG_PATH "logs/gokz-antimacro.log"

int gI_ButtonCount[MAXPLAYERS + 1];
int gI_ButtonsIndex[MAXPLAYERS + 1];
int gI_Buttons[MAXPLAYERS + 1][BUTTON_SAMPLES];
int gI_OldButtons[MAXPLAYERS + 1];

int gI_BhopCount[MAXPLAYERS + 1];
int gI_BhopIndex[MAXPLAYERS + 1];
int gI_BhopLastCmdnum[MAXPLAYERS + 1];
bool gB_BhopHitPerf[MAXPLAYERS + 1][BHOP_SAMPLES];
int gI_BhopPreJumpInputs[MAXPLAYERS + 1][BHOP_SAMPLES];
int gI_BhopPostJumpInputs[MAXPLAYERS + 1][BHOP_SAMPLES];

#include "gokz-antimacro/api.sp"
#include "gokz-antimacro/bhoptracking.sp"
#include "gokz-antimacro/commands.sp"



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
	CreateCommands();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}



// =========================  CLIENT  ========================= //

public void OnClientPutInServer(int client)
{
	OnClientPutInServer_BhopTracking(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	OnPlayerRunCmd_BhopTracking(client, cmdnum);
	gI_OldButtons[client] = buttons;
	return Plugin_Continue;
}

public void GOKZ_AM_OnPlayerSuspected(int client, AMReason reason, const char[] details)
{
	char logPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, logPath, sizeof(logPath), LOG_PATH);
	
	switch (reason)
	{
		case AMReason_BhopCheat:LogToFileEx(logPath, "%L was suspected of bhop cheating. Details: %s", client, details);
		case AMReason_BhopMacro:LogToFileEx(logPath, "%L was suspected of bhop macroing. Details: %s", client, details);
	}
} 