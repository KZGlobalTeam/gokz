#include <sourcemod>

#include <sdktools>

#include <gokz/core>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required
#pragma semicolon 1

/*
	Lets players measure the distance between two points.
	Credits to DaFox (https://forums.alliedmods.net/showthread.php?t=88830?t=88830)
*/


public Plugin myinfo = 
{
	name = "GOKZ Measure", 
	author = "DanZay", 
	description = "Provides tools for measuring things", 
	version = GOKZ_VERSION, 
	url = GOKZ_SOURCE_URL
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-measure.txt"
#define MEASURE_MIN_DIST 0.01
int gI_BeamModel;
bool gB_Measuring[MAXPLAYERS + 1];
bool gB_MeasurePosSet[MAXPLAYERS + 1][2];
float gF_MeasurePos[MAXPLAYERS + 1][2][3];
float gF_MeasureNormal[MAXPLAYERS + 1][2][3];
Handle gH_P2PRed[MAXPLAYERS + 1];
Handle gH_P2PGreen[MAXPLAYERS + 1];

#include "gokz-measure/measurer.sp"
#include "gokz-measure/commands.sp"
#include "gokz-measure/measure_menu.sp"


// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-measure");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-measure.phrases");
	
	RegisterCommands();
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



// =====[ OTHER EVENTS ]=====

public void OnMapStart()
{
	gI_BeamModel = PrecacheModel("materials/sprites/laserbeam.vmt", true);
} 