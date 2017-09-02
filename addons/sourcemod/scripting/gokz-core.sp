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
#undef REQUIRE_PLUGIN
#include <basecomm>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Core", 
	author = "DanZay", 
	description = "GOKZ Core Plugin", 
	version = "0.14.0", 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

bool gB_LateLoad;
bool gB_BaseComm;
Handle gH_DHooks_OnTeleport;
bool gB_ClientIsSetUp[MAXPLAYERS + 1];
float gF_OldOrigin[MAXPLAYERS + 1][3];
bool gB_OldDucking[MAXPLAYERS + 1];
int gI_OldTickCount[MAXPLAYERS + 1];

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
	CreateNatives();
	RegPluginLibrary("gokz-core");
	gB_LateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is only for CS:GO.");
	}
	
	LoadTranslations("common.phrases");
	LoadTranslations("gokz-core.phrases");
	
	CreateRegexes();
	CreateMenus();
	CreateGlobalForwards();
	CreateHooks();
	CreateConVars();
	CreateCommands();
	CreateCommandListeners();
	
	AutoExecConfig(true, "gokz-core", "sourcemod/gokz");
	
	if (gB_LateLoad)
	{
		OnLateLoad();
	}
}

void OnLateLoad()
{
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

public void OnAllPluginsLoaded()
{
	gB_BaseComm = LibraryExists("basecomm");
	if (GetLoadedModeCount() <= 0)
	{
		SetFailState("At least one GOKZ mode plugin is required.");
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "basecomm"))
	{
		gB_BaseComm = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "basecomm"))
	{
		gB_BaseComm = false;
	}
}



// =========================  CLIENT  ========================= //

public void OnClientPutInServer(int client)
{
	SetupClientOptions(client);
	SetupClientTimer(client);
	SetupClientPause(client);
	SetupClientBhopTriggers(client);
	SetupClientHidePlayers(client);
	SetupClientTeleports(client);
	PrintConnectMessage(client);
	DHookEntity(gH_DHooks_OnTeleport, true, client);
}

public void OnClientPostAdminCheck(int client)
{
	gB_ClientIsSetUp[client] = true;
	Call_GOKZ_OnClientSetup(client);
}

public void OnPlayerDisconnect(Event event, const char[] name, bool dontBroadcast) // player_disconnect hook
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client))
	{
		return;
	}
	PrintDisconnectMessage(client, event);
	OnPlayerDisconnect_Timer(client);
	OnPlayerDisconnect_ValidJump(client);
	gB_ClientIsSetUp[client] = false;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs) {
	if (OnClientSayCommand_ChatProcessing(client, sArgs) == Plugin_Handled)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) // player_spawn hook
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	OnPlayerSpawn_Modes(client);
	OnPlayerSpawn_Pause(client);
	OnPlayerSpawn_ValidJump(client);
	UpdateCSGOHUD(client);
	UpdateHideWeapon(client);
	UpdatePistol(client);
	UpdatePlayerModel(client);
	UpdateGodMode(client);
	UpdatePlayerCollision(client);
	UpdateTPMenu(client);
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) // player_death hook
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	OnPlayerDeath_Timer(client);
	OnPlayerDeath_ValidJump(client);
}

public Action OnPlayerJoinTeam(Event event, const char[] name, bool dontBroadcast) // player_team hook
{
	SetEventBroadcast(event, true); // Block join team messages
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	OnPlayerRunCmd_Timer(client);
	OnPlayerRunCmd_TPMenu(client);
	OnPlayerRunCmd_InfoPanel(client, cmdnum);
	OnPlayerRunCmd_SpeedText(client, cmdnum);
	OnPlayerRunCmd_TimerText(client, cmdnum);
	OnPlayerRunCmd_JumpBeam(client);
	UpdateOldVariables(client, tickcount);
	return Plugin_Continue;
}

public MRESReturn DHooks_OnTeleport(int client, Handle params)
{
	bool origin = !DHookIsNullParam(params, 1); // Origin affected
	bool velocity = !DHookIsNullParam(params, 3); // Velocity affected
	OnTeleport_ValidJump(client, origin, velocity);
	return MRES_Ignored;
}



// =========================  MOVEMENTAPI  ========================= //

public void Movement_OnButtonPress(int client, int button)
{
	OnButtonPress_VirtualButtons(client, button);
}

public void Movement_OnChangeMoveType(int client, MoveType oldMoveType, MoveType newMoveType)
{
	OnChangeMoveType_Timer(client, newMoveType);
	OnChangeMoveType_Pause(client, newMoveType);
	OnChangeMoveType_ValidJump(client, oldMoveType, newMoveType);
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
	UpdateTPMenu(client);
}

public void GOKZ_OnTimerEnd_Post(int client, int course, float time, int teleportsUsed)
{
	OnTimerEnd_SlayOnEnd(client);
}

public void GOKZ_OnMakeCheckpoint_Post(int client)
{
	UpdateTPMenu(client);
}

public void GOKZ_OnTeleportToCheckpoint_Post(int client)
{
	UpdateTPMenu(client);
}

public void GOKZ_OnPrevCheckpoint_Post(int client)
{
	UpdateTPMenu(client);
}

public void GOKZ_OnNextCheckpoint_Post(int client)
{
	UpdateTPMenu(client);
}

public void GOKZ_OnTeleportToStart_Post(int client, bool customPos)
{
	OnTeleportToStart_Timer(client, customPos);
	UpdateTPMenu(client);
}

public void GOKZ_OnUndoTeleport_Post(int client)
{
	UpdateTPMenu(client);
}

public void GOKZ_OnOptionChanged(int client, Option option, int newValue)
{
	OnOptionChanged_Timer(client, option);
	OnOptionChanged_TPMenu(client, option);
	OnOptionChanged_HideWeapon(client, option);
	OnOptionChanged_Pistol(client, option);
}



// =========================  OTHER  ========================= //

public void OnMapStart()
{
	OnMapStart_Measure();
	OnMapStart_PlayerModel();
	OnMapStart_KZConfig();
	OnMapStart_Prefix();
	OnMapStart_JumpBeam();
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	return Plugin_Handled; // Stop round from ever ending
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) // round_start hook
{
	OnRoundStart_Timer();
	OnRoundStart_ForceAllTalk();
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



// =========================  PRIVATE  ========================= //

static void CreateRegexes()
{
	CreateRegexesMapButtons();
}

static void CreateMenus()
{
	CreateMenusMeasure();
	CreateMenusMode();
	CreateMenusOptions();
	CreateMenusPistol();
	CreateMenusTP();
}

static void CreateHooks()
{
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);
	HookEvent("round_start", OnRoundStart, EventHookMode_Pre);
	HookEvent("player_team", OnPlayerJoinTeam, EventHookMode_Pre);
	AddNormalSoundHook(view_as<NormalSHook>(OnNormalSound));
	
	// Setup DHooks OnTeleport
	Handle gameData = LoadGameConfigFile("sdktools.games");
	int offset = GameConfGetOffset(gameData, "Teleport");
	gameData.Close();
	gH_DHooks_OnTeleport = DHookCreate(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, DHooks_OnTeleport);
	DHookAddParam(gH_DHooks_OnTeleport, HookParamType_VectorPtr);
	DHookAddParam(gH_DHooks_OnTeleport, HookParamType_ObjectPtr);
	DHookAddParam(gH_DHooks_OnTeleport, HookParamType_VectorPtr);
	DHookAddParam(gH_DHooks_OnTeleport, HookParamType_Bool);
}

static void UpdateOldVariables(int client, int tickcount)
{
	if (IsPlayerAlive(client))
	{
		Movement_GetOrigin(client, gF_OldOrigin[client]);
		gB_OldDucking[client] = Movement_GetDucking(client);
		gI_OldTickCount[client] = tickcount;
	}
} 