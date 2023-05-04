/*
	Hide sounds and effects from other players.
*/

void OnPluginStart_HidePlayers()
{
	AddNormalSoundHook(Hook_NormalSound);
	AddTempEntHook("Shotgun Shot", Hook_ShotgunShot);
	AddTempEntHook("EffectDispatch", Hook_EffectDispatch);
	HookUserMessage(GetUserMessageId("WeaponSound"), Hook_WeaponSound, true);

	// Lateload support
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			OnJoinTeam_HidePlayers(client, GetClientTeam(client));
		}
	}
}

void OnJoinTeam_HidePlayers(int client, int team)
{
	// Make sure client is only ever hooked once
	SDKUnhook(client, SDKHook_SetTransmit, OnSetTransmitClient);
	
	if (team == CS_TEAM_T || team == CS_TEAM_CT)
	{
		SDKHook(client, SDKHook_SetTransmit, OnSetTransmitClient);
	}
}

Action CommandToggleShowPlayers(int client, int args)
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

// =====[ PRIVATE ]=====

// Hide most of the other players' actions. This function is expensive.
static Action OnSetTransmitClient(int entity, int client)
{
	if (GOKZ_GetOption(client, gC_QTOptionNames[QTOption_ShowPlayers]) == ShowPlayers_Disabled
		 && entity != client
		 && entity != GetObserverTarget(client))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

// Hide reload sounds. Required if other players were visible at one point during the gameplay.
static Action Hook_WeaponSound(UserMsg msg_id, Protobuf msg, const int[] players, int playersNum, bool reliable, bool init)
{
	int newClients[MAXPLAYERS], newTotal = 0;
	int entidx = msg.ReadInt("entidx");
	for (int i = 0; i < playersNum; i++)
	{
		int client = players[i];
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

static void RequestFrame_WeaponSound(DataPack dp)
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

// Hide various sounds that don't get blocked by SetTransmit hook.
static Action Hook_NormalSound(int clients[MAXPLAYERS], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags, char soundEntry[PLATFORM_MAX_PATH], int& seed)
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

// Hide firing sounds.
static Action Hook_ShotgunShot(const char[] te_name, const int[] players, int numClients, float delay)
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

// Hide knife and blood effect caused by other players.
static Action Hook_EffectDispatch(const char[] te_name, const int[] players, int numClients, float delay)
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
