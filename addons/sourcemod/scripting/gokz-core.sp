#include <sourcemod>

#include <dhooks>
#include <sdktools>
#include <sdkhooks>

#include <colorvariables>
#include <cstrike>
#include <gokz>
#include <regex>

#include <movementapi>
#include <gokz/core>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Core", 
	author = "DanZay", 
	description = "GOKZ Core Plugin", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATE_URL "http://updater.gokz.org/gokz-core.txt"

Handle g_ThisPlugin;
Handle gH_DHooks_OnTeleport;
bool gB_ClientIsSetUp[MAXPLAYERS + 1];
float gF_OldOrigin[MAXPLAYERS + 1][3];
bool gB_OldDucking[MAXPLAYERS + 1];
bool gB_OldOnGround[MAXPLAYERS + 1];
int gI_OldButtons[MAXPLAYERS + 1];

#include "gokz-core/commands.sp"
#include "gokz-core/convars.sp"
#include "gokz-core/forwards.sp"
#include "gokz-core/natives.sp"
#include "gokz-core/modes.sp"
#include "gokz-core/misc.sp"
#include "gokz-core/options.sp"
#include "gokz-core/teleports.sp"

#include "gokz-core/hud/hide_csgo_hud.sp"
#include "gokz-core/hud/info_panel.sp"
#include "gokz-core/hud/speed_text.sp"
#include "gokz-core/hud/timer_text.sp"

#include "gokz-core/map/buttons.sp"
#include "gokz-core/map/bhop_triggers.sp"
#include "gokz-core/map/prefix.sp"

#include "gokz-core/menus/goto.sp"
#include "gokz-core/menus/measure.sp"
#include "gokz-core/menus/mode.sp"
#include "gokz-core/menus/options.sp"
#include "gokz-core/menus/pistol.sp"
#include "gokz-core/menus/tp.sp"

#include "gokz-core/timer/pause.sp"
#include "gokz-core/timer/timer.sp"
#include "gokz-core/timer/virtual_buttons.sp"



// =========================  PLUGIN  ========================= //

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is only for CS:GO.");
	}
	if (RoundFloat(1 / GetTickInterval()) != 128)
	{
		SetFailState("This plugin is only for 128 tickrate.");
	}
	
	g_ThisPlugin = myself;
	CreateNatives();
	RegPluginLibrary("gokz-core");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("gokz-core.phrases");
	
	CreateGlobalForwards();
	CreateRegexes();
	CreateHooks();
	CreateConVars();
	CreateCommands();
	CreateCommandListeners();
	CreateHudSynchronizers();
	
	AutoExecConfig(true, "gokz-core", "sourcemod/gokz");
}

public void OnAllPluginsLoaded()
{
	OnAllPluginsLoaded_Modes();
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	// Handle late loading here now that all the modes have been loaded
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			OnClientPutInServer(client);
			if (IsClientAuthorized(client))
			{
				OnClientPostAdminCheck(client);
			}
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



// =========================  CLIENT  ========================= //

public void OnClientPutInServer(int client)
{
	SetupClientOptions(client);
	SetupClientTimer(client);
	SetupClientPause(client);
	SetupClientHidePlayers(client);
	SetupClientTeleports(client);
	SetupClientJoinTeam(client);
	SetupClientFirstSpawn(client);
	SetupClientVirtualButtons(client);
	PrintConnectMessage(client);
	DHookEntity(gH_DHooks_OnTeleport, true, client);
}

public void OnClientPostAdminCheck(int client)
{
	UpdateClanTag(client);
	gB_ClientIsSetUp[client] = true;
	Call_GOKZ_OnClientSetup(client);
}

public void OnClientDisconnect(int client)
{
	OnClientDisconnect_Timer(client);
	OnClientDisconnect_ValidJump(client);
	gB_ClientIsSetUp[client] = false;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	OnPlayerRunCmd_Timer(client); // This should be first!
	OnPlayerRunCmd_VirtualButtons(client, buttons);
	OnPlayerRunCmd_TPMenu(client);
	OnPlayerRunCmd_InfoPanel(client, cmdnum);
	OnPlayerRunCmd_SpeedText(client, cmdnum);
	OnPlayerRunCmd_TimerText(client, cmdnum);
	OnPlayerRunCmd_ValidJump(client, cmdnum);
	OnPlayerRunCmd_JumpBeam(client);
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

public Action OnPlayerDisconnect(Event event, const char[] name, bool dontBroadcast) // player_disconnect pre hook
{
	event.BroadcastDisabled = true; // Block disconnection messages
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client))
	{
		PrintDisconnectMessage(client, event);
	}
	return Plugin_Continue;
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
		UpdateCSGOHUD(client);
		UpdateHideWeapon(client);
		UpdatePistol(client);
		UpdatePlayerModel(client);
		UpdateGodMode(client);
		UpdatePlayerCollision(client);
		UpdateTPMenu(client);
	}
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) // player_death pre hook
{
	event.BroadcastDisabled = true; // Block death notices
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client))
	{
		OnPlayerDeath_Timer(client);
		OnPlayerDeath_ValidJump(client);
	}
	return Plugin_Continue;
}

public Action OnPlayerJoinTeam(Event event, const char[] name, bool dontBroadcast) // player_team pre hook
{
	event.BroadcastDisabled = true; // Block join team messages
	return Plugin_Continue;
}

public MRESReturn DHooks_OnTeleport(int client, Handle params)
{
	bool originTp = !DHookIsNullParam(params, 1); // Origin affected
	bool velocityTp = !DHookIsNullParam(params, 3); // Velocity affected
	OnTeleport_ValidJump(client, originTp, velocityTp);
	return MRES_Ignored;
}



// =========================  MOVEMENTAPI  ========================= //

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



// =========================  GOKZ  ========================= //

public void GOKZ_OnTimerStart_Post(int client, int course)
{
	OnTimerStart_JoinTeam(client);
	OnTimerStart_Pause(client);
	OnTimerStart_Teleports(client);
	OnTimerStart_TimerText(client);
	OnTimerStart_TPMenu(client);
}

public void GOKZ_OnTimerEnd_Post(int client, int course, float time, int teleportsUsed)
{
	OnTimerEnd_SlayOnEnd(client);
	OnTimerEnd_TimerText(client);
}

public void GOKZ_OnTimerStopped(int client)
{
	OnTimerStopped_TimerText(client);
}

public void GOKZ_OnMakeCheckpoint_Post(int client)
{
	OnMakeCheckpoint_TPMenu(client);
}

public void GOKZ_OnCountedTeleport_Post(int client)
{
	OnCountedTeleport_TPMenu(client);
}

public void GOKZ_OnTeleportToStart_Post(int client, bool customPos)
{
	OnTeleportToStart_Timer(client, customPos);
}

public void GOKZ_OnOptionChanged(int client, Option option, int newValue)
{
	OnOptionChanged_Timer(client, option);
	OnOptionChanged_Mode(client, option);
	OnOptionChanged_TPMenu(client, option);
	OnOptionChanged_HideWeapon(client, option);
	OnOptionChanged_Pistol(client, option);
	OnOptionChanged_ClanTag(client, option);
	OnOptionChanged_SpeedText(client, option);
	OnOptionChanged_TimerText(client, option);
}

public void GOKZ_OnJoinTeam(int client, int team)
{
	OnJoinTeam_Pause(client, team);
	OnJoinTeam_TPMenu(client);
}

public void GOKZ_OnModeUnloaded(int mode)
{
	OnModeUnloaded_Options(mode);
}



// =========================  OTHER  ========================= //

public void OnMapStart()
{
	PrecacheModels();
	OnMapStart_KZConfig();
	OnMapStart_Prefix();
	OnMapStart_Options();
}

public void OnConfigsExecuted()
{
	OnConfigsExecuted_TimeLimit();
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



// =========================  PRIVATE  ========================= //

static void CreateRegexes()
{
	CreateRegexesMapButtons();
}

static void CreateHooks()
{
	HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_team", OnPlayerJoinTeam, EventHookMode_Pre);
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
	
	gameData.Close();
}

static void CreateHudSynchronizers()
{
	CreateHudSynchronizerSpeedText();
	CreateHudSynchronizerTimerText();
}

static void UpdateOldVariables(int client, int buttons)
{
	if (IsPlayerAlive(client))
	{
		Movement_GetOrigin(client, gF_OldOrigin[client]);
		gB_OldDucking[client] = Movement_GetDucking(client);
		gB_OldOnGround[client] = Movement_GetOnGround(client);
	}
	gI_OldButtons[client] = buttons;
}

static void PrecacheModels()
{
	PrecacheJumpBeamModels();
	PrecachePlayerModels();
	PrecacheMeasureModels();
} 