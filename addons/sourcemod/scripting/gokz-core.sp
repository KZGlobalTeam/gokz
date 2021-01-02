#include <sourcemod>

#include <clientprefs>
#include <cstrike>
#include <dhooks>
#include <regex>
#include <sdkhooks>
#include <sdktools>

#include <gokz/core>
#include <movementapi>

#include <autoexecconfig>
#include <sourcemod-colors>

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

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-core.txt"

Handle gH_ThisPlugin;
Handle gH_DHooks_OnTeleport;

int gI_CmdNum[MAXPLAYERS + 1];
bool gB_OldOnGround[MAXPLAYERS + 1];
int gI_OldButtons[MAXPLAYERS + 1];
int gI_TeleportCmdNum[MAXPLAYERS + 1];
bool gB_OriginTeleported[MAXPLAYERS + 1];
bool gB_VelocityTeleported[MAXPLAYERS + 1];
bool gB_LateLoad;

ConVar gCV_gokz_chat_prefix;
ConVar gCV_sv_full_alltalk;

#include "gokz-core/commands.sp"
#include "gokz-core/forwards.sp"
#include "gokz-core/natives.sp"
#include "gokz-core/modes.sp"
#include "gokz-core/misc.sp"
#include "gokz-core/options.sp"
#include "gokz-core/teleports.sp"
#include "gokz-core/triggerfix.sp"

#include "gokz-core/map/buttons.sp"
#include "gokz-core/map/bhop_triggers.sp"
#include "gokz-core/map/prefix.sp"
#include "gokz-core/map/starts.sp"
#include "gokz-core/map/zones.sp"
#include "gokz-core/map/end.sp"

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
	
	gH_ThisPlugin = myself;
	gB_LateLoad = late;
	
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
	OnPluginStart_MapStarts();
	OnPluginStart_MapEnd();
	OnPluginStart_MapZones();
	OnPluginStart_Options();
	OnPluginStart_Triggerfix();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
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
		Updater_AddPlugin(UPDATER_URL);
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
	OnClientPutInServer_BhopTriggers(client);
	OnClientPutInServer_Triggerfix(client);
	OnClientPutInServer_Noclip(client);
	HookClientEvents(client);
}

public void OnClientDisconnect(int client)
{
	OnClientDisconnect_Timer(client);
	OnClientDisconnect_ValidJump(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	gI_CmdNum[client] = cmdnum;
	return Plugin_Continue;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (!IsValidClient(client))
	{
		return;
	}
	
	OnPlayerRunCmdPost_VirtualButtons(client, buttons, cmdnum); // Emulate buttons first
	OnPlayerRunCmdPost_Timer(client); // This should be first after emulating buttons
	OnPlayerRunCmdPost_ValidJump(client);
	UpdateTrackingVariables(client, cmdnum, buttons); // This should be last
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
	gB_OriginTeleported[client] = !DHookIsNullParam(params, 1); // Origin affected
	gB_VelocityTeleported[client] = !DHookIsNullParam(params, 3); // Velocity affected
	OnTeleport_ValidJump(client);
	OnTeleport_DelayVirtualButtons(client);
	return MRES_Ignored;
}

public void Movement_OnChangeMovetype(int client, MoveType oldMovetype, MoveType newMovetype)
{
	OnChangeMovetype_Timer(client, newMovetype);
	OnChangeMovetype_Pause(client, newMovetype);
	OnChangeMovetype_ValidJump(client, oldMovetype, newMovetype);
	OnChangeMovetype_MapBhopTriggers(client, newMovetype);
}

public void Movement_OnStartTouchGround(int client)
{
	OnStartTouchGround_MapZones(client);
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

public void GOKZ_OnTeleportToStart_Post(int client)
{
	OnTeleportToStart_Timer(client);
}

public void GOKZ_OnCountedTeleport_Post(int client)
{
	OnCountedTeleport_VirtualButtons(client);
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
}

public void GOKZ_OnJoinTeam(int client, int team)
{
	OnJoinTeam_Pause(client, team);
}



// =====[ OTHER EVENTS ]=====

public void OnMapStart()
{
	OnMapStart_KZConfig();
	OnMapStart_Options();
	OnMapStart_Prefix();
	OnMapStart_CourseRegister();
	OnMapStart_MapStarts();
	OnMapStart_MapEnd();
	OnMapStart_VirtualButtons();
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
	OnEntityCreated_Triggerfix(entity, classname);
}

public void OnEntitySpawned(int entity)
{
	OnEntitySpawned_MapBhopTriggers(entity);
	OnEntitySpawned_MapButtons(entity);
	OnEntitySpawned_MapStarts(entity);
	OnEntitySpawned_MapEnd(entity);
	OnEntitySpawned_MapZones(entity);
}

public void OnClientConnected(int client)
{
	OnClientConnected_Triggerfix(client);
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
	
	gCV_gokz_chat_prefix = AutoExecConfig_CreateConVar("gokz_chat_prefix", "{green}KZ {grey}| ", "Chat prefix used for GOKZ messages.");
	
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
	
	GameData gameData = new GameData("sdktools.games");
	int offset;
	
	// Setup DHooks OnTeleport for players
	offset = gameData.GetOffset("Teleport");
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

static void UpdateTrackingVariables(int client, int cmdnum, int buttons)
{
	if (IsPlayerAlive(client))
	{
		gB_OldOnGround[client] = Movement_GetOnGround(client);
	}
	
	gI_OldButtons[client] = buttons;
	
	if (gB_OriginTeleported[client] || gB_VelocityTeleported[client])
	{
		gI_TeleportCmdNum[client] = cmdnum;
	}
	gB_OriginTeleported[client] = false;
	gB_VelocityTeleported[client] = false;
} 