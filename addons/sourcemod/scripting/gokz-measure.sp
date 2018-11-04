#include <sourcemod>

#include <sdktools>

#include <gokz/core>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>



public Plugin myinfo = 
{
	name = "GOKZ Measure", 
	author = "DanZay", 
	description = "Provides tools for measuring things", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATE_URL "http://updater.gokz.org/gokz-measure.txt"

int gI_BeamModel;

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
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}



// =====[ OTHER EVENTS ]=====

public void OnMapStart()
{
	gI_BeamModel = PrecacheModel("materials/sprites/bluelaser1.vmt", true);
} 