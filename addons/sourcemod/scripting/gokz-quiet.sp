#include <sourcemod>

#include <cstrike>
#include <sdkhooks>

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
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-quiet.txt"

TopMenu gTM_Options;
TopMenuObject gTMO_CatGeneral;
TopMenuObject gTMO_ItemsQuiet[QTOPTION_COUNT];



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-quiet");
	return APLRes_Success;
}

public void OnPluginStart()
{
	AddNormalSoundHook(Hook_NormalSound);
	AddTempEntHook("Shotgun Shot", Hook_ShotgunShot);

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

	if (GOKZ_GetOption(client, gC_QTOptionNames[QTOption_MapSounds]) == MapSounds_Disabled)
	{
		SetEntProp(client, Prop_Data, "soundscapeIndex", 0);
	}
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



// =====[ HIDE PLAYERS ]=====

void OnJoinTeam_HidePlayers(int client, int team)
{
	// Make sure client is only ever hooked once
	SDKUnhook(client, SDKHook_SetTransmit, OnSetTransmitClient);
	
	if (team == CS_TEAM_T || team == CS_TEAM_CT)
	{
		SDKHook(client, SDKHook_SetTransmit, OnSetTransmitClient);
	}
}

public Action OnSetTransmitClient(int entity, int client)
{
	if (GOKZ_GetOption(client, gC_QTOptionNames[QTOption_ShowPlayers]) == ShowPlayers_Disabled
		 && entity != client
		 && entity != GetObserverTarget(client))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Hook_NormalSound(int clients[MAXPLAYERS], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags, char soundEntry[PLATFORM_MAX_PATH], int& seed)
{
	if (entity > MAXPLAYERS)
	{
		return Plugin_Continue;
	}

	int numNewClients = 0;
	for (int i = 0; i < numClients; i++)
	{
		int client = clients[i];
		if (GOKZ_GetOption(client, gC_QTOptionNames[QTOption_ShowPlayers]) == ShowPlayers_Enabled
			|| entity == client
			|| entity == GetObserverTarget(client))
		{
			clients[numNewClients] = client;
			numNewClients++;
		}
	}
	
	if (numNewClients != numClients) 
	{
		numClients = numNewClients;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public Action Hook_ShotgunShot(const char[] te_name, const int[] players, int numClients, float delay)
{
	int newClients[MAXPLAYERS], newTotal = 0;
	for (int i = 0; i < numClients; i++)
	{
		int client = players[i];
		if (GOKZ_GetOption(client, gC_QTOptionNames[QTOption_ShowPlayers]) == ShowPlayers_Enabled
			 || TE_ReadNum("m_iPlayer") + 1 == GetObserverTarget(client))
		{
			newClients[newTotal] = client;
			newTotal++;
		}
	}

	// Noone wants the sound
	if (newTotal == 0)
	{
		return Plugin_Stop;
	}

	// Nothing's changed, let the engine handle it.
	if (newTotal == numClients)
	{
		return Plugin_Continue;
	}

	float origin[3];
	TE_ReadVector("m_vecOrigin", origin);

	float angles[2];
	angles[0] = TE_ReadFloat("m_vecAngles[0]");
	angles[1] = TE_ReadFloat("m_vecAngles[1]");

	int weapon = TE_ReadNum("m_weapon");
	int mode = TE_ReadNum("m_iMode");
	int seed = TE_ReadNum("m_iSeed");
	int player = TE_ReadNum("m_iPlayer");
	float inaccuracy = TE_ReadFloat("m_fInaccuracy");
	float recoilIndex = TE_ReadFloat("m_flRecoilIndex");
	float spread = TE_ReadFloat("m_fSpread");
	int itemIdx = TE_ReadNum("m_nItemDefIndex");
	int soundType = TE_ReadNum("m_iSoundType");

	TE_Start("Shotgun Shot");
	TE_WriteVector("m_vecOrigin", origin);
	TE_WriteFloat("m_vecAngles[0]", angles[0]);
	TE_WriteFloat("m_vecAngles[1]", angles[1]);
	TE_WriteNum("m_weapon", weapon);
	TE_WriteNum("m_iMode", mode);
	TE_WriteNum("m_iSeed", seed);
	TE_WriteNum("m_iPlayer", player);
	TE_WriteFloat("m_fInaccuracy", inaccuracy);
	TE_WriteFloat("m_flRecoilIndex", recoilIndex);
	TE_WriteFloat("m_fSpread", spread);
	TE_WriteNum("m_nItemDefIndex", itemIdx);
	TE_WriteNum("m_iSoundType", soundType);

	// Send the TE and stop the engine from processing its own.
	TE_Send(newClients, newTotal, delay);
	return Plugin_Stop;
}



// =====[ STOP SOUNDS ]=====

void StopSounds(int client)
{
	ClientCommand(client, "snd_playsounds Music.StopAllExceptMusic");
	GOKZ_PrintToChat(client, true, "%t", "Stopped Sounds");
}



// =====[ OPTIONS ]=====

void OnOptionsMenuReady_Options()
{
	RegisterOptions();
}

void OnOptionChanged_Options(int client, QTOption option, any newValue)
{
	PrintOptionChangeMessage(client, option, newValue);
}

void PrintOptionChangeMessage(int client, QTOption option, any newValue)
{
	switch (option)
	{
		case QTOption_ShowPlayers:
		{
			switch (newValue)
			{
				case ShowPlayers_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Show Players - Disable");
				}
				case ShowPlayers_Enabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Show Players - Enable");
				}
			}
		}
		case QTOption_MapSounds:
		{
			switch (newValue)
			{
				case MapSounds_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Map Sounds - Disable");
				}
				case MapSounds_Enabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Map Sounds - Enable");
				}
			}
		}
	}
}

void RegisterOptions()
{
	for (QTOption option; option < QTOPTION_COUNT; option++)
	{
		GOKZ_RegisterOption(gC_QTOptionNames[option], gC_QTOptionDescriptions[option], 
			OptionType_Int, gI_QTOptionDefaultValues[option], 0, gI_QTOptionCounts[option] - 1);
	}
}



// =====[ OPTIONS MENU ]=====

void OnOptionsMenuReady_OptionsMenu(TopMenu topMenu)
{
	if (gTM_Options == topMenu)
	{
		return;
	}
	
	gTM_Options = topMenu;
	gTMO_CatGeneral = gTM_Options.FindCategory(GENERAL_OPTION_CATEGORY);
	
	// Add gokz-quiet option items	
	for (int option = 0; option < view_as<int>(QTOPTION_COUNT); option++)
	{
		gTMO_ItemsQuiet[option] = gTM_Options.AddItem(gC_QTOptionNames[option], TopMenuHandler_QT, gTMO_CatGeneral);
	}
}


public void TopMenuHandler_QT(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	QTOption option = QTOPTION_INVALID;
	for (int i = 0; i < view_as<int>(QTOPTION_COUNT); i++)
	{
		if (topobj_id == gTMO_ItemsQuiet[i])
		{
			option = view_as<QTOption>(i);
			break;
		}
	}
	
	if (option == QTOPTION_INVALID)
	{
		return;
	}
	
	if (action == TopMenuAction_DisplayOption)
	{
		switch (option)
		{
			case QTOption_ShowPlayers:
			{
				FormatToggleableOptionDisplay(param, QTOption_ShowPlayers, buffer, maxlength);
			}
			case QTOption_MapSounds:
			{
				FormatToggleableOptionDisplay(param, QTOption_MapSounds, buffer, maxlength);
			}
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		GOKZ_CycleOption(param, gC_QTOptionNames[option]);
		gTM_Options.Display(param, TopMenuPosition_LastCategory);
	}
}

void FormatToggleableOptionDisplay(int client, QTOption option, char[] buffer, int maxlength)
{
	if (GOKZ_GetOption(client, gC_QTOptionNames[option]) == MapSounds_Disabled)
	{
		FormatEx(buffer, maxlength, "%T - %T", 
			gC_QTOptionPhrases[option], client, 
			"Options Menu - Disabled", client);
	}
	else
	{
		FormatEx(buffer, maxlength, "%T - %T", 
			gC_QTOptionPhrases[option], client, 
			"Options Menu - Enabled", client);
	}
}



// =====[ COMMANDS ]=====

void RegisterCommands()
{
	RegConsoleCmd("sm_hide", CommandToggleShowPlayers, "[KZ] Toggle the visibility of other players.");
	RegConsoleCmd("sm_stopsound", CommandStopSound, "[KZ] Stop all sounds e.g. map soundscapes (music).");
}

public Action CommandToggleShowPlayers(int client, int args)
{
	if (GOKZ_GetOption(client, gC_QTOptionNames[QTOption_ShowPlayers]) == ShowPlayers_Disabled)
	{
		GOKZ_SetOption(client, gC_QTOptionNames[QTOption_ShowPlayers], ShowPlayers_Enabled);
	}
	else
	{
		GOKZ_SetOption(client, gC_QTOptionNames[QTOption_ShowPlayers], ShowPlayers_Disabled);
	}
	return Plugin_Handled;
}

public Action CommandStopSound(int client, int args)
{
	StopSounds(client);
	return Plugin_Handled;
} 