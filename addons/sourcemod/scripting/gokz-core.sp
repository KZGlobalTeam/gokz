#include <sourcemod>

#include <clientprefs>
#include <dhooks>
#include <sdktools>
#include <sdkhooks>

#include <autoexecconfig>
#include <colorvariables>
#include <cstrike>
#include <gokz>
#include <regex>

#include <movementapi>
#include <gokz/core>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#include <gokz/kzplayer>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Core", 
	author = "DanZay", 
	description = "Core plugin of the GOKZ plugin set", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATE_URL "http://updater.gokz.org/gokz-core.txt"

Handle gH_ThisPlugin;
Handle gH_DHooks_OnTeleport;

bool gB_OldOnGround[MAXPLAYERS + 1];
int gI_OldButtons[MAXPLAYERS + 1];

ConVar gCV_gokz_chat_prefix;
ConVar gCV_sv_full_alltalk;

#include "gokz-core/commands.sp"
#include "gokz-core/forwards.sp"
#include "gokz-core/natives.sp"
#include "gokz-core/modes.sp"
#include "gokz-core/misc.sp"
#include "gokz-core/options.sp"
#include "gokz-core/teleports.sp"

#include "gokz-core/map/buttons.sp"
#include "gokz-core/map/bhop_triggers.sp"
#include "gokz-core/map/prefix.sp"

#include "gokz-core/menus/mode_menu.sp"
#include "gokz-core/menus/options_menu.sp"

#include "gokz-core/timer/pause.sp"
#include "gokz-core/timer/timer.sp"
#include "gokz-core/timer/virtual_buttons.sp"



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("GOKZ only supports CS:GO servers.");
	}
	if (FloatAbs(1.0 / GetTickInterval() - TICK_RATE) > EPSILON)
	{
		SetFailState("GOKZ only supports 128 tickrate servers.");
	}
	
	gH_ThisPlugin = myself;
	
	CreateNatives();
	RegPluginLibrary("gokz-core");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("gokz-common.phrases");
	LoadTranslations("gokz-core.phrases");
	
	CreateGlobalForwards();
	CreateConVars();
	HookEvents();
	RegisterCommands();
	
	OnPluginStart_MapButtons();
	OnPluginStart_Options();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	OnAllPluginsLoaded_Modes();
	OnAllPluginsLoaded_OptionsMenu();
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			OnClientPutInServer(client);
		}
		if (AreClientCookiesCached(client))
		{
			OnClientCookiesCached(client);
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
	OnClientPutInServer_Timer(client);
	OnClientPutInServer_Pause(client);
	OnClientPutInServer_Teleports(client);
	OnClientPutInServer_JoinTeam(client);
	OnClientPutInServer_FirstSpawn(client);
	OnClientPutInServer_VirtualButtons(client);
	OnClientPutInServer_Options(client);
	OnClientPutInServer_ClanTag(client);
	HookClientEvents(client);
}

public void OnClientDisconnect(int client)
{
	OnClientDisconnect_Timer(client);
	OnClientDisconnect_ValidJump(client);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	OnPlayerRunCmdPost_Timer(client); // This should be first!
	OnPlayerRunCmdPost_VirtualButtons(client, buttons);
	OnPlayerRunCmdPost_ValidJump(client, cmdnum);
	UpdateOldVariables(client, buttons); // This should be last!
}

public Action OnClientCommandKeyValues(int client, KeyValues kv)
{
	// Block clan tag changes - Credit: GoD-Tony (https://forums.alliedmods.net/showpost.php?p=2337679&postcount=6)
	char cmd[16];
	if (kv.GetSectionName(cmd, sizeof(cmd)) && StrEqual(cmd, "ClanTagChanged", false))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void OnClientCookiesCached(int client)
{
	OnClientCookiesCached_Options(client);
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) // player_spawn post hook 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client))
	{
		OnPlayerSpawn_Modes(client);
		OnPlayerSpawn_Pause(client);
		OnPlayerSpawn_ValidJump(client);
		OnPlayerSpawn_FirstSpawn(client);
		OnPlayerSpawn_GodMode(client);
		OnPlayerSpawn_PlayerCollision(client);
	}
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) // player_death pre hook
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client))
	{
		OnPlayerDeath_Timer(client);
		OnPlayerDeath_ValidJump(client);
	}
	return Plugin_Continue;
}

public MRESReturn DHooks_OnTeleport(int client, Handle params)
{
	bool originTp = !DHookIsNullParam(params, 1); // Origin affected
	bool velocityTp = !DHookIsNullParam(params, 3); // Velocity affected
	OnTeleport_ValidJump(client, originTp, velocityTp);
	return MRES_Ignored;
}

public void Movement_OnChangeMoveType(int client, MoveType oldMoveType, MoveType newMoveType)
{
	OnChangeMoveType_Timer(client, newMoveType);
	OnChangeMoveType_Pause(client, newMoveType);
	OnChangeMoveType_ValidJump(client, oldMoveType, newMoveType);
	OnChangeMoveType_MapBhopTriggers(client, newMoveType);
}

public void Movement_OnStartTouchGround(int client)
{
	OnStartTouchGround_MapBhopTriggers(client);
}

public void Movement_OnStopTouchGround(int client, bool jumped)
{
	OnStopTouchGround_ValidJump(client, jumped);
}

public void GOKZ_OnTimerStart_Post(int client, int course)
{
	OnTimerStart_JoinTeam(client);
	OnTimerStart_Pause(client);
	OnTimerStart_Teleports(client);
}

public void GOKZ_OnTeleportToStart_Post(int client, bool customPos)
{
	OnTeleportToStart_Timer(client, customPos);
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	Option coreOption;
	if (!GOKZ_IsCoreOption(option, coreOption))
	{
		return;
	}
	
	OnOptionChanged_Options(client, coreOption, newValue);
	OnOptionChanged_Timer(client, coreOption);
	OnOptionChanged_Mode(client, coreOption);
	OnOptionChanged_ClanTag(client, coreOption);
}

public void GOKZ_OnJoinTeam(int client, int team)
{
	OnJoinTeam_Pause(client, team);
}



// =====[ OTHER EVENTS ]=====

public void OnMapStart()
{
	OnMapStart_KZConfig();
	OnMapStart_Prefix();
	OnMapStart_Options();
}

public void OnConfigsExecuted()
{
	OnConfigsExecuted_TimeLimit();
	OnConfigsExecuted_OptionsMenu();
}

public Action OnNormalSound(int[] clients, int &numClients, char[] sample, int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char[] soundEntry, int &seed)
{
	if (OnNormalSound_StopSounds(entity) == Plugin_Handled)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
}

public void OnEntitySpawned(int entity)
{
	OnEntitySpawned_MapButtons(entity);
	OnEntitySpawned_MapBhopTriggers(entity);
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) // round_start post no copy hook
{
	OnRoundStart_Timer();
	OnRoundStart_ForceAllTalk();
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	return Plugin_Handled;
}

public void GOKZ_OnModeUnloaded(int mode)
{
	OnModeUnloaded_Options(mode);
}

public void GOKZ_OnOptionsMenuCreated(TopMenu topMenu)
{
	OnOptionsMenuCreated_OptionsMenu();
}

public void GOKZ_OnOptionsMenuReady(TopMenu topMenu)
{
	OnOptionsMenuReady_OptionsMenu();
}



// =====[ PRIVATE ]=====

static void CreateConVars()
{
	AutoExecConfig_SetFile("gokz-core", "sourcemod/gokz");
	AutoExecConfig_SetCreateFile(true);
	
	gCV_gokz_chat_prefix = AutoExecConfig_CreateConVar("gokz_chat_prefix", "{grey}[{green}KZ{grey}] ", "Chat prefix used for GOKZ messages.");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	gCV_sv_full_alltalk = FindConVar("sv_full_alltalk");
	
	// Remove unwanted flags from constantly changed mode convars - replication is done manually in mode plugins
	for (int i = 0; i < MODECVAR_COUNT; i++)
	{
		FindConVar(gC_ModeCVars[i]).Flags &= ~FCVAR_NOTIFY;
		FindConVar(gC_ModeCVars[i]).Flags &= ~FCVAR_REPLICATED;
	}
}

static void HookEvents()
{
	AddCommandsListeners();
	
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	AddNormalSoundHook(view_as<NormalSHook>(OnNormalSound));
	
	Handle gameData = LoadGameConfigFile("sdktools.games");
	int offset;
	
	// Setup DHooks OnTeleport for players
	offset = GameConfGetOffset(gameData, "Teleport");
	gH_DHooks_OnTeleport = DHookCreate(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, DHooks_OnTeleport);
	DHookAddParam(gH_DHooks_OnTeleport, HookParamType_VectorPtr);
	DHookAddParam(gH_DHooks_OnTeleport, HookParamType_ObjectPtr);
	DHookAddParam(gH_DHooks_OnTeleport, HookParamType_VectorPtr);
	DHookAddParam(gH_DHooks_OnTeleport, HookParamType_Bool);
	
	delete gameData;
}

static void HookClientEvents(int client)
{
	DHookEntity(gH_DHooks_OnTeleport, true, client);
}

static void UpdateOldVariables(int client, int buttons)
{
	if (IsPlayerAlive(client))
	{
		gB_OldOnGround[client] = Movement_GetOnGround(client);
	}
	gI_OldButtons[client] = buttons;
} 