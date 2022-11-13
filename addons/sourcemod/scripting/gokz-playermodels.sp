#include <sourcemod>

#include <cstrike>
#include <sdktools>

#include <gokz/core>

#include <autoexecconfig>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Player Models", 
	author = "DanZay", 
	description = "Sets player's model upon spawning", 
	version = GOKZ_VERSION, 
	url = GOKZ_SOURCE_URL
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-playermodels.txt"
#define PLAYER_MODEL_T "models/player/tm_leet_varianta.mdl"
#define PLAYER_MODEL_CT "models/player/ctm_idf_variantc.mdl"
#define PLAYER_MODEL_T_BOT "models/player/custom_player/legacy/tm_leet_varianta.mdl"
#define PLAYER_MODEL_CT_BOT "models/player/custom_player/legacy/ctm_idf_variantc.mdl"
ConVar gCV_gokz_player_models_alpha;
ConVar gCV_sv_disable_immunity_alpha;



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-playermodels");
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVars();
	HookEvents();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
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

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) // player_spawn post hook 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client))
	{
		// Can't use a timer here because it's not precise enough. We want exactly 2 ticks of delay!
		// 2 ticks is the minimum amount of time after which gloves will work.
		// The reason we need precision is because SetEntityModel momentarily resets the
		// player hull to standing (or something along those lines), so when a player
		// spawns/gets reset to a crouch tunnel where there's a trigger less than 18 units from the top
		// of the ducked player hull, then they touch that trigger! SetEntityModel interferes with the
		// fix for that (JoinTeam in gokz-core/misc calls TeleportPlayer in gokz.inc, which fixes that bug).
		RequestFrame(RequestFrame_UpdatePlayerModel, GetClientUserId(client));
	}
}



// =====[ OTHER EVENTS ]=====

public void OnMapStart()
{
	PrecachePlayerModels();
}



// =====[ GENERAL ]=====

void HookEvents()
{
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}



// =====[ CONVARS ]=====

void CreateConVars()
{
	AutoExecConfig_SetFile("gokz-playermodels", "sourcemod/gokz");
	AutoExecConfig_SetCreateFile(true);
	
	gCV_gokz_player_models_alpha = AutoExecConfig_CreateConVar("gokz_player_models_alpha", "65", "Amount of alpha (transparency) to set player models to.", _, true, 0.0, true, 255.0);
	gCV_gokz_player_models_alpha.AddChangeHook(OnConVarChanged);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	gCV_sv_disable_immunity_alpha = FindConVar("sv_disable_immunity_alpha");
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == gCV_gokz_player_models_alpha)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				UpdatePlayerModelAlpha(client);
			}
		}
	}
}



// =====[ PLAYER MODELS ]=====

public void RequestFrame_UpdatePlayerModel(int userid)
{
	RequestFrame(RequestFrame_UpdatePlayerModel2, userid);
}

public void RequestFrame_UpdatePlayerModel2(int userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client) || !IsPlayerAlive(client))
	{
		return;
	}
	// Bots are unaffected by the bobbing animation caused by the new models.
	switch (GetClientTeam(client))
	{
		case CS_TEAM_T:
		{
			if (IsFakeClient(client))
			{
				SetEntityModel(client, PLAYER_MODEL_T_BOT);
			}
			else
			{
				SetEntityModel(client, PLAYER_MODEL_T);
			}
		}
		case CS_TEAM_CT:
		{
			if (IsFakeClient(client))
			{
				SetEntityModel(client, PLAYER_MODEL_CT_BOT);
			}
			else
			{
				SetEntityModel(client, PLAYER_MODEL_CT);
			}
		}
	}
	
	UpdatePlayerModelAlpha(client);
}

void UpdatePlayerModelAlpha(int client)
{
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, _, _, _, gCV_gokz_player_models_alpha.IntValue);
}

void PrecachePlayerModels()
{
	gCV_sv_disable_immunity_alpha.IntValue = 1; // Ensures player transparency works	
	
	PrecacheModel(PLAYER_MODEL_T, true);
	PrecacheModel(PLAYER_MODEL_CT, true);
	PrecacheModel(PLAYER_MODEL_T_BOT, true);
	PrecacheModel(PLAYER_MODEL_CT_BOT, true);
} 