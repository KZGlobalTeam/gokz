#include <sourcemod>

#include <dhooks>
#include <sdkhooks>
#include <sdktools>

#include <gokz/core>
#include <gokz/jumpstats>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <gokz/localdb>
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
	url = GOKZ_SOURCE_URL
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-jumpstats.txt"

// This must be global because it's both used by jump tracking and validating.
bool gB_SpeedJustModifiedExternally[MAXPLAYERS + 1];

#include "gokz-jumpstats/api.sp"
#include "gokz-jumpstats/commands.sp"
#include "gokz-jumpstats/distance_tiers.sp"
#include "gokz-jumpstats/jump_reporting.sp"
#include "gokz-jumpstats/jump_tracking.sp"
#include "gokz-jumpstats/jump_validating.sp"
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
	
	LoadBroadcastTiers();
	CreateGlobalForwards();
	RegisterCommands();
	
	OnPluginStart_JumpTracking();
	OnPluginStart_JumpValidating();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
	
	TopMenu topMenu;
	if (LibraryExists("gokz-core") && ((topMenu = GOKZ_GetOptionsTopMenu()) != null))
	{
		GOKZ_OnOptionsMenuReady(topMenu);
	}
	
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
		Updater_AddPlugin(UPDATER_URL);
	}
}



// =====[ CLIENT EVENTS ]=====

public void OnClientPutInServer(int client)
{
	HookClientEvents(client);
	OnClientPutInServer_Options(client);
	OnClientPutInServer_JumpTracking(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	OnPlayerRunCmd_JumpTracking(client, buttons, tickcount);
	return Plugin_Continue;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	OnPlayerRunCmdPost_JumpTracking(client);
}

public void Movement_OnStartTouchGround(int client)
{
	OnStartTouchGround_JumpTracking(client);
}

public void GOKZ_OnJumpInvalidated(int client)
{
	OnJumpInvalidated_JumpTracking(client);
}

public void GOKZ_OnJumpValidated(int client, bool jumped, bool ladderJump, bool jumpbug)
{
	OnJumpValidated_JumpTracking(client, jumped, ladderJump, jumpbug);
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	OnOptionChanged_JumpTracking(client, option);
	OnOptionChanged_Options(client, option, newValue);
}

public void GOKZ_JS_OnLanding(Jump jump)
{
	OnLanding_JumpReporting(jump);
}

public void GOKZ_JS_OnFailstat(Jump jump)
{
	OnFailstat_FailstatReporting(jump);
}

public void GOKZ_JS_OnJumpstatAlways(Jump jump)
{
	OnJumpstatAlways_JumpstatAlwaysReporting(jump);
}

public void GOKZ_JS_OnFailstatAlways(Jump jump)
{
	OnFailstatAlways_FailstatAlwaysReporting(jump);
}

public void SDKHook_StartTouch_Callback(int client, int touched) // SDKHook_StartTouchPost
{
	OnStartTouch_JumpTracking(client, touched);
}

public void SDKHook_Touch_CallBack(int client, int touched)
{
	OnTouch_JumpTracking(client);
}

public void SDKHook_EndTouch_Callback(int client, int touched) // SDKHook_EndTouchPost
{
	OnEndTouch_JumpTracking(client, touched);
}

public void GOKZ_OnTeleport(int client)
{
	OnTeleport_FailstatAlways(client);
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
	OnOptionsMenuReady_Options();
	OnOptionsMenuReady_OptionsMenu(topMenu);
}

public void GOKZ_OnSlap(int client)
{
	InvalidateJumpstat(client);
}



// =====[ PRIVATE ]=====

static void HookClientEvents(int client)
{
	SDKHook(client, SDKHook_StartTouchPost, SDKHook_StartTouch_Callback);
	SDKHook(client, SDKHook_TouchPost, SDKHook_Touch_CallBack);
	SDKHook(client, SDKHook_EndTouchPost, SDKHook_EndTouch_Callback);
}
