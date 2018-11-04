#include <sourcemod>

#include <gokz/core>
#include <gokz/hud>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#include <gokz/kzplayer>



public Plugin myinfo = 
{
	name = "GOKZ HUD", 
	author = "DanZay", 
	description = "Provides HUD and UI features", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATE_URL "http://updater.gokz.org/gokz-hud.txt"

#include "gokz-hud/commands.sp"
#include "gokz-hud/hide_hud.sp"
#include "gokz-hud/hide_weapon.sp"
#include "gokz-hud/info_panel.sp"
#include "gokz-hud/options.sp"
#include "gokz-hud/options_menu.sp"
#include "gokz-hud/speed_text.sp"
#include "gokz-hud/timer_text.sp"
#include "gokz-hud/tp_menu.sp"



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-hud");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-common.phrases");
	LoadTranslations("gokz-hud.phrases");
	
	HookEvents();
	RegisterCommands();
	
	OnPluginStart_SpeedText();
	OnPluginStart_TimerText();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	OnAllPluginsLoaded_Options();
	OnAllPluginsLoaded_OptionsMenu();
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}



// =====[ CLIENT EVENTS ]=====

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	OnPlayerRunCmdPost_InfoPanel(client, cmdnum);
	OnPlayerRunCmdPost_SpeedText(client, cmdnum);
	OnPlayerRunCmdPost_TimerText(client, cmdnum);
	OnPlayerRunCmdPost_TPMenu(client);
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) // player_spawn post hook 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client))
	{
		OnPlayerSpawn_HideHUD(client);
		OnPlayerSpawn_HideWeapon(client);
		OnPlayerSpawn_TPMenu(client);
	}
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) // player_death pre hook
{
	event.BroadcastDisabled = true; // Block death notices
}

public void GOKZ_OnJoinTeam(int client, int team)
{
	OnJoinTeam_TPMenu(client);
}

public void GOKZ_OnTimerStart_Post(int client, int course)
{
	OnTimerStart_TimerText(client);
	OnTimerStart_TPMenu(client);
}

public void GOKZ_OnTimerEnd_Post(int client, int course, float time, int teleportsUsed)
{
	OnTimerEnd_TimerText(client);
}

public void GOKZ_OnTimerStopped(int client)
{
	OnTimerStopped_TimerText(client);
}

public void GOKZ_OnPause_Post(int client)
{
	OnPause_TPMenu(client);
}

public void GOKZ_OnResume_Post(int client)
{
	OnResume_TPMenu(client);
}

public void GOKZ_OnMakeCheckpoint_Post(int client)
{
	OnMakeCheckpoint_TPMenu(client);
}

public void GOKZ_OnCountedTeleport_Post(int client)
{
	OnCountedTeleport_TPMenu(client);
}

public void GOKZ_OnCustomStartPositionSet_Post(int client, const float position[3], const float angles[3])
{
	OnCustomStartPositionSet_TPMenu(client);
}

public void GOKZ_OnCustomStartPositionCleared_Post(int client)
{
	OnCustomStartPositionCleared_TPMenu(client);
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	any hudOption;
	if (GOKZ_HUD_IsHUDOption(option, hudOption))
	{
		OnOptionChanged_SpeedText(client, hudOption);
		OnOptionChanged_TimerText(client, hudOption);
		OnOptionChanged_TPMenu(client, hudOption);
		OnOptionChanged_HideWeapon(client, hudOption);
		OnOptionChanged_Options(client, hudOption, newValue);
	}
}



// =====[ OTHER EVENTS ]=====

public void OnMapStart()
{
	OnMapStart_Options();
}

public void GOKZ_OnOptionsMenuCreated(TopMenu topMenu)
{
	OnOptionsMenuCreated_OptionsMenu(topMenu);
}

public void GOKZ_OnOptionsMenuReady(TopMenu topMenu)
{
	OnOptionsMenuReady_OptionsMenu(topMenu);
}



// =====[ PRIVATE ]=====

static void HookEvents()
{
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
} 