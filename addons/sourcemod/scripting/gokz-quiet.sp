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
	url = GOKZ_SOURCE_URL
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-quiet.txt"

// Search for "coopcementplant.missionselect_blank" id with sv_soundscape_printdebuginfo.
#define BLANK_SOUNDSCAPEINDEX 482
#define EFFECT_IMPACT 8
#define EFFECT_KNIFESLASH 2

TopMenu gTM_Options;
TopMenuObject gTMO_CatGeneral;
TopMenuObject gTMO_ItemsQuiet[QTOPTION_COUNT];

int gI_CurrentSoundscapeIndex[MAXPLAYERS + 1] = {BLANK_SOUNDSCAPEINDEX, ...};

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
	AddTempEntHook("EffectDispatch", Hook_EffectDispatch);
	HookUserMessage(GetUserMessageId("WeaponSound"), Hook_WeaponSound, true);

	LoadTranslations("gokz-common.phrases");
	LoadTranslations("gokz-quiet.phrases");

	RegisterCommands();

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			OnJoinTeam_HidePlayers(client, GetClientTeam(client));
		}
	}
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

	int soundscapeIndex = GetEntProp(client, Prop_Data, "soundscapeIndex");
	if (GOKZ_GetOption(client, gC_QTOptionNames[QTOption_MapSounds]) == MapSounds_Disabled)
	{
		if (soundscapeIndex != BLANK_SOUNDSCAPEINDEX)
		{
			gI_CurrentSoundscapeIndex[client] = soundscapeIndex;
		}
		SetEntProp(client, Prop_Data, "soundscapeIndex", BLANK_SOUNDSCAPEINDEX);
	}
	else
	{
		gI_CurrentSoundscapeIndex[client] = soundscapeIndex;
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

public Action Hook_WeaponSound(UserMsg msg_id, Protobuf msg, const int[] players, int playersNum, bool reliable, bool init)
{
	int newClients[MAXPLAYERS], newTotal = 0;
	int entidx = msg.ReadInt("entidx");
	for (int i = 0; i < playersNum; i++)
	{
		int client = players[i];
		if (!IsValidClient(client))
		{
			continue;
		}
		if (GOKZ_GetOption(client, gC_QTOptionNames[QTOption_ShowPlayers]) == ShowPlayers_Enabled
			|| entidx == client
			|| entidx == GetObserverTarget(client))
		{
			newClients[newTotal] = client;
			newTotal++;
		}
	}

	// Nothing's changed, let the engine handle it.
	if (newTotal == playersNum)
	{
		return Plugin_Continue;
	}

	// No one to send to so it doesn't matter if we block or not. We block just to end the function early.
	if (newTotal == 0)
	{
		return Plugin_Handled;
	}
	// Only way to modify the recipient list is to RequestFrame and create our own user message.
	char path[PLATFORM_MAX_PATH];
	msg.ReadString("sound", path, sizeof(path));
	int flags = USERMSG_BLOCKHOOKS;
	if (reliable)
	{
		flags |= USERMSG_RELIABLE;
	}
	if (init)
	{
		flags |= USERMSG_INITMSG;
	}

	DataPack dp = new DataPack();
	dp.WriteCell(msg_id);
	dp.WriteCell(newTotal);
	dp.WriteCellArray(newClients, newTotal);
	dp.WriteCell(flags);
	dp.WriteCell(entidx);
	dp.WriteFloat(msg.ReadFloat("origin_x"));
	dp.WriteFloat(msg.ReadFloat("origin_y"));
	dp.WriteFloat(msg.ReadFloat("origin_z"));
	dp.WriteString(path);
	dp.WriteFloat(msg.ReadFloat("timestamp"));

	RequestFrame(RequestFrame_WeaponSound, dp);
	return Plugin_Handled;
}

public void RequestFrame_WeaponSound(DataPack dp)
{
	dp.Reset();

	UserMsg msg_id = dp.ReadCell();
	int newTotal = dp.ReadCell();
	int newClients[MAXPLAYERS];
	dp.ReadCellArray(newClients, newTotal);
	int flags = dp.ReadCell();

	Protobuf newMsg = view_as<Protobuf>(StartMessageEx(msg_id, newClients, newTotal, flags));

	newMsg.SetInt("entidx", dp.ReadCell());
	newMsg.SetFloat("origin_x", dp.ReadFloat());
	newMsg.SetFloat("origin_y", dp.ReadFloat());
	newMsg.SetFloat("origin_z", dp.ReadFloat());
	char path[PLATFORM_MAX_PATH];
	dp.ReadString(path, sizeof(path));
	newMsg.SetString("sound", path);
	newMsg.SetFloat("timestamp", dp.ReadFloat());

	EndMessage();

	delete dp;
}

public Action Hook_NormalSound(int clients[MAXPLAYERS], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags, char soundEntry[PLATFORM_MAX_PATH], int& seed)
{
	if (StrContains(sample, "Player.EquipArmor") != -1 || StrContains(sample, "BaseCombatCharacter.AmmoPickup") != -1)
	{
		// When the sound is emitted, the owner of these entities are not set yet.
		// Hence we cannot do the entity parent stuff below.
		// In that case, we just straight up block armor and ammo pickup sounds.
		return Plugin_Stop;
	}
	int ent = entity;
	while (ent > MAXPLAYERS)
	{
		// Block some gun and knife sounds by trying to find its parent entity.
		ent = GetEntPropEnt(ent, Prop_Send, "moveparent");
		if (ent < MAXPLAYERS)
		{
			break;
		}
		else if (ent == -1)
		{
			return Plugin_Continue;
		}
	}
	int numNewClients = 0;
	for (int i = 0; i < numClients; i++)
	{
		int client = clients[i];
		if (GOKZ_GetOption(client, gC_QTOptionNames[QTOption_ShowPlayers]) == ShowPlayers_Enabled
			|| ent == client
			|| ent == GetObserverTarget(client))
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

public Action Hook_EffectDispatch(const char[] te_name, const int[] players, int numClients, float delay)
{
	// Block bullet impact effects.
	int effIndex = TE_ReadNum("m_iEffectName");
	if (effIndex != EFFECT_IMPACT && effIndex != EFFECT_KNIFESLASH)
	{
		return Plugin_Continue;
	}
	int newClients[MAXPLAYERS], newTotal = 0;
	for (int i = 0; i < numClients; i++)
	{
		int client = players[i];
		if (GOKZ_GetOption(client, gC_QTOptionNames[QTOption_ShowPlayers]) == ShowPlayers_Enabled)
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
	float origin[3], start[3];
	origin[0] = TE_ReadFloat("m_vOrigin.x");
	origin[1] = TE_ReadFloat("m_vOrigin.y");
	origin[2] = TE_ReadFloat("m_vOrigin.z");
	start[0] = TE_ReadFloat("m_vStart.x");
	start[1] = TE_ReadFloat("m_vStart.y");
	start[2] = TE_ReadFloat("m_vStart.z");
	int flags = TE_ReadNum("m_fFlags");
	float scale = TE_ReadFloat("m_flScale");
	int surfaceProp = TE_ReadNum("m_nSurfaceProp");
	int damageType = TE_ReadNum("m_nDamageType");
	int entindex = TE_ReadNum("entindex");
	int positionsAreRelativeToEntity = TE_ReadNum("m_bPositionsAreRelativeToEntity");

	TE_Start("EffectDispatch");
	TE_WriteNum("m_iEffectName", effIndex);
	TE_WriteFloatArray("m_vOrigin.x", origin, 3);
	TE_WriteFloatArray("m_vStart.x", start, 3);
	TE_WriteFloat("m_flScale", scale);
	TE_WriteNum("m_nSurfaceProp", surfaceProp);
	TE_WriteNum("m_nDamageType", damageType);
	TE_WriteNum("entindex", entindex);
	TE_WriteNum("m_bPositionsAreRelativeToEntity", positionsAreRelativeToEntity);
	TE_WriteNum("m_fFlags", flags);

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
	if (option == QTOption_MapSounds && newValue == MapSounds_Enabled)
	{
		if (gI_CurrentSoundscapeIndex[client] != BLANK_SOUNDSCAPEINDEX)
		{
			SetEntProp(client, Prop_Data, "soundscapeIndex", gI_CurrentSoundscapeIndex[client]);
		}
	}
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