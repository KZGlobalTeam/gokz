#include <sourcemod>

#include <sdkhooks>
#include <gokz/core>
#include <gokz/hud>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <gokz/racing>
#include <gokz/replays>
#include <updater>

#include <gokz/kzplayer>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ HUD", 
	author = "DanZay", 
	description = "Provides HUD and UI features", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-hud.txt"

bool gB_GOKZRacing;
bool gB_GOKZReplays;
bool gB_MenuShowing[MAXPLAYERS + 1];
bool gB_JBTakeoff[MAXPLAYERS + 1];
bool gB_FastUpdateRate[MAXPLAYERS + 1];
int gI_DynamicMenu[MAXPLAYERS + 1];

#include "gokz-hud/commands.sp"
#include "gokz-hud/hide_weapon.sp"
#include "gokz-hud/info_panel.sp"
#include "gokz-hud/menu.sp"
#include "gokz-hud/options.sp"
#include "gokz-hud/options_menu.sp"
#include "gokz-hud/racing_text.sp"
#include "gokz-hud/speed_text.sp"
#include "gokz-hud/timer_text.sp"
#include "gokz-hud/tp_menu.sp"
#include "gokz-hud/natives.sp"

// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-hud");
	CreateNatives();
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-common.phrases");
	LoadTranslations("gokz-hud.phrases");
	
	HookEvents();
	RegisterCommands();
	
	OnPluginStart_RacingText();
	OnPluginStart_SpeedText();
	OnPluginStart_TimerText();
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
	
	gB_GOKZRacing = LibraryExists("gokz-racing");
	gB_GOKZReplays = LibraryExists("gokz-replays");
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
	
	gB_GOKZRacing = gB_GOKZRacing || StrEqual(name, "gokz-racing");
	gB_GOKZReplays = gB_GOKZReplays || StrEqual(name, "gokz-replays");
}

public void OnLibraryRemoved(const char[] name)
{
	gB_GOKZRacing = gB_GOKZRacing && !StrEqual(name, "gokz-racing");
	gB_GOKZReplays = gB_GOKZReplays && !StrEqual(name, "gokz-replays");
}



// =====[ CLIENT EVENTS ]=====

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PostThinkPost, OnPlayerPostThinkPost);
}

public void OnPlayerPostThinkPost(int client)
{
	KZPlayer player = KZPlayer(client);
	gB_JBTakeoff[client] = (gB_JBTakeoff[client] && !player.OnGround && !player.OnLadder && !player.Noclipping) || Movement_GetJumpbugged(client);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (!IsValidClient(client))
	{
		return;
	}
	
	HUDInfo info;
	KZPlayer player = KZPlayer(client);
	KZPlayer targetPlayer = KZPlayer(player.ObserverTarget);
	
	// Bots don't need to have their HUD drawn
	if (player.Fake) 
	{
		return;
	}

	if (player.Alive)
	{
		SetHUDInfo(player, info, cmdnum);
	}
	else if (targetPlayer.ID != -1 && !targetPlayer.Fake)
	{
		SetHUDInfo(targetPlayer, info, cmdnum);
	}
	else if (targetPlayer.ID != -1 && gB_GOKZReplays)
	{
		GOKZ_RP_GetPlaybackInfo(targetPlayer.ID, info);
	}
	else
	{
		return;
	}

	if (!IsValidClient(info.ID))
	{
		return;
	}
	
	OnPlayerRunCmdPost_InfoPanel(client, cmdnum, info);
	OnPlayerRunCmdPost_RacingText(client, cmdnum);
	OnPlayerRunCmdPost_SpeedText(client, cmdnum, info);
	OnPlayerRunCmdPost_TimerText(client, cmdnum, info);
	OnPlayerRunCmdPost_TPMenu(client, cmdnum, info);
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) // player_spawn post hook 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client))
	{
		OnPlayerSpawn_HideWeapon(client);
		OnPlayerSpawn_Menu(client);
	}
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) // player_death pre hook
{
	event.BroadcastDisabled = true; // Block death notices
	return Plugin_Continue;
}

public void GOKZ_OnJoinTeam(int client, int team)
{
	OnJoinTeam_Menu(client);
}

public void GOKZ_OnTimerStart_Post(int client, int course)
{
	OnTimerStart_Menu(client);
}

public void GOKZ_OnTimerEnd_Post(int client, int course, float time, int teleportsUsed)
{
	OnTimerEnd_TimerText(client);
	OnTimerEnd_Menu(client);
}

public void GOKZ_OnTimerStopped(int client)
{
	OnTimerStopped_TimerText(client);
	OnTimerStopped_Menu(client);
}

public void GOKZ_OnPause_Post(int client)
{
	OnPause_Menu(client);
}

public void GOKZ_OnResume_Post(int client)
{
	OnResume_Menu(client);
}

public void GOKZ_OnMakeCheckpoint_Post(int client)
{
	OnMakeCheckpoint_Menu(client);
}

public void GOKZ_OnCountedTeleport_Post(int client)
{
	OnCountedTeleport_Menu(client);
}

public void GOKZ_OnStartPositionSet_Post(int client, StartPositionType type, const float origin[3], const float angles[3])
{
	OnStartPositionSet_Menu(client);
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	any hudOption;
	if (GOKZ_HUD_IsHUDOption(option, hudOption))
	{
		OnOptionChanged_SpeedText(client, hudOption);
		OnOptionChanged_TimerText(client, hudOption);
		OnOptionChanged_Menu(client, hudOption);
		OnOptionChanged_HideWeapon(client, hudOption);
		OnOptionChanged_Options(client, hudOption, newValue);
		if (hudOption == HUDOption_UpdateRate)
		{
			gB_FastUpdateRate[client] = GOKZ_HUD_GetOption(client, HUDOption_UpdateRate) == UpdateRate_Fast;
		}
		else if (hudOption == HUDOption_DynamicMenu)
		{
			gI_DynamicMenu[client] = GOKZ_HUD_GetOption(client, HUDOption_DynamicMenu);
		}
	}
}

public void GOKZ_OnOptionsLoaded(int client)
{
	gB_FastUpdateRate[client] = GOKZ_HUD_GetOption(client, HUDOption_UpdateRate) == UpdateRate_Fast;
	gI_DynamicMenu[client] = GOKZ_HUD_GetOption(client, HUDOption_DynamicMenu);
}

// =====[ OTHER EVENTS ]=====

public void GOKZ_OnOptionsMenuCreated(TopMenu topMenu)
{
	OnOptionsMenuCreated_OptionsMenu(topMenu);
}

public void GOKZ_OnOptionsMenuReady(TopMenu topMenu)
{
	OnOptionsMenuReady_Options();
	OnOptionsMenuReady_OptionsMenu(topMenu);
}

public void GOKZ_RC_OnRaceInfoChanged(int raceID, RaceInfo prop, int oldValue, int newValue)
{
	OnRaceInfoChanged_RacingText(raceID, prop, newValue);
}



// =====[ PRIVATE ]=====

static void HookEvents()
{
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
}

static void SetHUDInfo(KZPlayer player, HUDInfo info, int cmdnum)
{
	info.TimerRunning = player.TimerRunning;
	info.TimeType = player.TimeType;
	info.Time = player.Time;
	info.Paused = player.Paused;
	info.OnGround = player.OnGround;
	info.OnLadder = player.OnLadder;
	info.Noclipping = player.Noclipping;
	info.Ducking = Movement_GetDucking(player.ID);
	info.HitBhop = (Movement_GetJumped(player.ID) && Movement_GetTakeoffCmdNum(player.ID) == cmdnum) && Movement_GetTakeoffCmdNum(player.ID) - Movement_GetLandingCmdNum(player.ID) <= HUD_MAX_BHOP_GROUND_TICKS;
	info.Speed = player.Speed;
	info.ID = player.ID;
	info.Jumped = player.Jumped;
	info.HitPerf = player.GOKZHitPerf;
	info.HitJB = gB_JBTakeoff[info.ID];
	info.TakeoffSpeed = player.GOKZTakeoffSpeed;
	info.IsTakeoff = Movement_GetTakeoffCmdNum(player.ID) == cmdnum;
	info.Buttons = player.Buttons;
}