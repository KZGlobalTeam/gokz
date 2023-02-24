#include <sourcemod>

#include <cstrike>
#include <sdkhooks>
#include <dhooks>

#include <gokz/core>
#include <gokz/quiet>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo =
{
	name = "GOKZ Quiet",
	author = "DanZay",
	description = "Provides options for a quieter KZ experience",
	version = GOKZ_VERSION,
	url = GOKZ_SOURCE_URL
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-quiet.txt"


#include "gokz-quiet/ambient.sp"
#include "gokz-quiet/soundscape.sp"
#include "gokz-quiet/hideplayers.sp"
#include "gokz-quiet/falldamage.sp"
#include "gokz-quiet/gokz-sounds.sp"
#include "gokz-quiet/options.sp"

// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-quiet");
	return APLRes_Success;
}

public void OnPluginStart()
{
	OnPluginStart_HidePlayers();
	OnPluginStart_FallDamage();
	OnPluginStart_Ambient();

	LoadTranslations("gokz-common.phrases");
	LoadTranslations("gokz-quiet.phrases");

	RegisterCommands();
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

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			GOKZ_OnJoinTeam(client, GetClientTeam(client));
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

public void GOKZ_OnJoinTeam(int client, int team)
{
	OnJoinTeam_HidePlayers(client, team);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (!IsValidClient(client))
	{
		return;
	}
	
	OnPlayerRunCmdPost_Soundscape(client);
}


// =====[ OTHER EVENTS ]=====

public void GOKZ_OnOptionsMenuReady(TopMenu topMenu)
{
	OnOptionsMenuReady_Options();
	OnOptionsMenuReady_OptionsMenu(topMenu);
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	any qtOption;
	if (GOKZ_QT_IsQTOption(option, qtOption))
	{
		OnOptionChanged_Options(client, qtOption, newValue);
	}
}

public void GOKZ_OnOptionsMenuCreated(TopMenu topMenu)
{
	OnOptionsMenuCreated_OptionsMenu(topMenu);
}

// =====[ STOP SOUNDS ]=====

void StopSounds(int client)
{
	ClientCommand(client, "snd_playsounds Music.StopAllExceptMusic");
	GOKZ_PrintToChat(client, true, "%t", "Stopped Sounds");
}


// =====[ COMMANDS ]=====

void RegisterCommands()
{
	RegConsoleCmd("sm_hide", CommandToggleShowPlayers, "[KZ] Toggle the visibility of other players.");
	RegConsoleCmd("sm_stopsound", CommandStopSound, "[KZ] Stop all sounds e.g. map soundscapes (music).");
}

public Action CommandStopSound(int client, int args)
{
	StopSounds(client);
	return Plugin_Handled;
}