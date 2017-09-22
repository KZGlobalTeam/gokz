#include <sourcemod>

#include <sdktools>
#include <sdkhooks>

#include <gokz>

#include <movementapi>
#undef REQUIRE_PLUGIN
#include <gokz/core>
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Mode - Vanilla", 
	author = "DanZay", 
	description = "GOKZ Mode Module - Vanilla", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATE_URL "http://dzy.crabdance.com/updater/gokz-mode-vanilla.txt"

bool gB_GOKZCore;
ConVar gCV_ModeCVar[MODECVAR_COUNT];



// =========================  PLUGIN  ========================= //

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is only for CS:GO.");
	}
	
	RegPluginLibrary("gokz-mode-vanilla");
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVars();
}

public void OnPluginEnd()
{
	if (gB_GOKZCore)
	{
		GOKZ_SetModeLoaded(Mode_Vanilla, false);
	}
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("gokz-core"))
	{
		gB_GOKZCore = true;
		GOKZ_SetModeLoaded(Mode_Vanilla, true);
	}
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "gokz-core"))
	{
		gB_GOKZCore = true;
		GOKZ_SetModeLoaded(Mode_Vanilla, true);
	}
	else if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "gokz-core"))
	{
		gB_GOKZCore = false;
	}
}



// =========================  CLIENT  ========================= //

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PreThinkPost, SDKHook_OnClientPreThink_Post);
}

public void SDKHook_OnClientPreThink_Post(int client)
{
	if (!IsUsingMode(client))
	{
		return;
	}
	
	// Don't tweak convars if GOKZ isn't running
	if (gB_GOKZCore)
	{
		TweakConVars();
	}
}

public void Movement_OnStopTouchGround(int client, bool jumped)
{
	if (!IsUsingMode(client))
	{
		return;
	}
	
	KZPlayer player = new KZPlayer(client);
	if (gB_GOKZCore)
	{
		player.gokzHitPerf = Movement_GetHitPerf(client);
		player.gokzTakeoffSpeed = player.takeoffSpeed;
	}
}

public void Movement_OnChangeMoveType(int client, MoveType oldMoveType, MoveType newMoveType)
{
	if (!IsUsingMode(client))
	{
		return;
	}
	
	KZPlayer player = new KZPlayer(client);
	if (gB_GOKZCore && newMoveType == MOVETYPE_WALK)
	{
		player.gokzHitPerf = false;
		player.gokzTakeoffSpeed = player.takeoffSpeed;
	}
}

public void GOKZ_OnOptionChanged(int client, Option option, int newValue)
{
	// Make sure velocity modifier is reset to 1.0 when switching modes
	if (option == Option_Mode && newValue == Mode_Vanilla)
	{
		Movement_SetVelocityModifier(client, 1.0);
	}
}



// =========================  PRIVATE  ========================= //

static bool IsUsingMode(int client)
{
	// If GOKZ core isn't loaded, then apply mode at all times
	return !gB_GOKZCore || GOKZ_GetOption(client, Option_Mode) == Mode_Vanilla;
}


// CONVARS

static void CreateConVars()
{
	gCV_ModeCVar[ModeCVar_Accelerate] = FindConVar("sv_accelerate");
	gCV_ModeCVar[ModeCVar_Friction] = FindConVar("sv_friction");
	gCV_ModeCVar[ModeCVar_AirAccelerate] = FindConVar("sv_airaccelerate");
	gCV_ModeCVar[ModeCVar_LadderScaleSpeed] = FindConVar("sv_ladder_scale_speed");
	gCV_ModeCVar[ModeCVar_MaxVelocity] = FindConVar("sv_maxvelocity");
	gCV_ModeCVar[ModeCVar_Gravity] = FindConVar("sv_gravity");
	gCV_ModeCVar[ModeCVar_EnableBunnyhopping] = FindConVar("sv_enablebunnyhopping");
	gCV_ModeCVar[ModeCVar_AutoBunnyhopping] = FindConVar("sv_autobunnyhopping");
	gCV_ModeCVar[ModeCVar_StaminaMax] = FindConVar("sv_staminamax");
	gCV_ModeCVar[ModeCVar_StaminaLandCost] = FindConVar("sv_staminalandcost");
	gCV_ModeCVar[ModeCVar_StaminaJumpCost] = FindConVar("sv_staminajumpcost");
	gCV_ModeCVar[ModeCVar_StaminaRecoveryRate] = FindConVar("sv_staminarecoveryrate");
	gCV_ModeCVar[ModeCVar_MaxSpeed] = FindConVar("sv_maxspeed");
	gCV_ModeCVar[ModeCVar_WaterAccelerate] = FindConVar("sv_wateraccelerate");
	gCV_ModeCVar[ModeCVar_TimeBetweenDucks] = FindConVar("sv_timebetweenducks");
	gCV_ModeCVar[ModeCVar_AccelerateUseWeaponSpeed] = FindConVar("sv_accelerate_use_weapon_speed");
	
	// Remove these notify flags because these ConVars are being set constantly
	for (int i = 0; i < MODECVAR_COUNT; i++)
	{
		gCV_ModeCVar[i].Flags &= ~FCVAR_NOTIFY;
	}
}

static void TweakConVars()
{
	for (int i = 0; i < MODECVAR_COUNT; i++)
	{
		gCV_ModeCVar[i].RestoreDefault();
	}
} 