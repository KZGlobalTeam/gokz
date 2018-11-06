#include <sourcemod>

#include <sdkhooks>
#include <sdktools>

#include <gokz>

#include <movementapi>
#include <gokz/core>
#include <gokz/jumpstats>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#include <gokz/kzplayer>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Jumpstats", 
	author = "DanZay", 
	description = "Tracks and outputs movement statistics", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATE_URL "http://updater.gokz.org/gokz-jumpstats.txt"

#include "gokz-jumpstats/api.sp"
#include "gokz-jumpstats/distance_tiers.sp"
#include "gokz-jumpstats/jump_reporting.sp"
#include "gokz-jumpstats/jump_tracking.sp"
#include "gokz-jumpstats/options.sp"
#include "gokz-jumpstats/options_menu.sp"



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNatives();
	RegPluginLibrary("gokz-jumpstats");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-common.phrases");
	LoadTranslations("gokz-jumpstats.phrases");
	
	CreateGlobalForwards();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	OnAllPluginsLoaded_Options();
	OnAllPluginsLoaded_OptionsMenu();
	
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
}



// =====[ CLIENT EVENTS ]=====

public void OnClientPutInServer(int client)
{
	HookClientEvents(client);
	OnClientPutInServer_Options(client);
	OnClientPutInServer_JumpTracking(client);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	OnPlayerRunCmdPost_JumpTracking(client, cmdnum);
}

public void Movement_OnStartTouchGround(int client)
{
	OnStartTouchGround_JumpTracking(client);
}

public void Movement_OnPlayerJump(int client, bool jumpbug)
{
	OnPlayerJump_JumpTracking(client, jumpbug);
}

public void GOKZ_OnJumpValidated(int client, bool jumped, bool ladderJump)
{
	OnJumpValidated_JumpTracking(client, jumped, ladderJump);
}

public void GOKZ_OnJumpInvalidated(int client)
{
	OnJumpInvalidated_JumpTracking(client);
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	OnOptionChanged_JumpTracking(client, option);
	OnOptionChanged_Options(client, option, newValue);
}

public void GOKZ_JS_OnLanding(int client, int jumpType, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration)
{
	OnLanding_JumpReporting(client, jumpType, distance, offset, height, preSpeed, maxSpeed, strafes, sync, duration);
}

public void SDKHook_StartTouch_Callback(int client, int touched) // SDKHook_StartTouchPost
{
	OnStartTouch_JumpTracking(client);
}

public void SDKHook_EndTouch_Callback(int client, int touched) // SDKHook_EndTouchPost
{
	OnEndTouch_JumpTracking(client);
}



// =====[ OTHER EVENTS ]=====

public void OnMapStart()
{
	OnMapStart_JumpReporting();
	OnMapStart_DistanceTiers();
}

public void GOKZ_OnOptionsMenuCreated(TopMenu topMenu)
{
	OnOptionsMenuCreated_OptionsMenu(topMenu);
}

public void GOKZ_OnOptionsMenuReady(TopMenu topMenu)
{
	OnOptionsMenuReady_OptionsMenu(topMenu);
}



// =====[ PRIVATE ]=====

static void HookClientEvents(int client)
{
	SDKHook(client, SDKHook_StartTouchPost, SDKHook_StartTouch_Callback);
	SDKHook(client, SDKHook_EndTouchPost, SDKHook_EndTouch_Callback);
} 