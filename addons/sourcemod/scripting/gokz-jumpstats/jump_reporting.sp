/*
	Chat and console reports for jumpstats.
*/



static char sounds[DISTANCETIER_COUNT][256];



// =====[ PUBLIC ]=====

void PlayJumpstatSound(int client, int tier)
{
	int soundOption = GOKZ_JS_GetOption(client, JSOption_MinSoundTier);
	if (tier <= DistanceTier_Meh || soundOption == DistanceTier_None || soundOption > tier)
	{
		return;
	}
	
	EmitSoundToClient(client, sounds[tier]);
}



// =====[ EVENTS ]=====

void OnMapStart_JumpReporting()
{
	if (!LoadSounds())
	{
		SetFailState("Failed to load file: \"%s\".", JS_CFG_SOUNDS);
	}
}

void OnLanding_JumpReporting(int client, int jumpType, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration)
{
	int tier = GetDistanceTier(jumpType, GOKZ_GetCoreOption(client, Option_Mode), distance, offset);
	if (tier == DistanceTier_None)
	{
		return;
	}
	
	// Report the jumpstat to the client and their spectators
	DoJumpstatsReport(client, client, jumpType, tier, distance, offset, height, preSpeed, maxSpeed, strafes, sync, duration);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetObserverTarget(i) == client)
		{
			DoJumpstatsReport(i, client, jumpType, tier, distance, offset, height, preSpeed, maxSpeed, strafes, sync, duration);
		}
	}
}



// =====[ PRIVATE ]=====

static void DoJumpstatsReport(int client, int jumper, int jumpType, int tier, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration)
{
	if (GOKZ_JS_GetOption(client, JSOption_JumpstatsMaster) == JumpstatsMaster_Disabled)
	{
		return;
	}
	
	DoChatReport(client, jumper, jumpType, tier, distance, preSpeed, maxSpeed, strafes, sync);
	DoConsoleReport(client, jumper, jumpType, tier, distance, offset, height, preSpeed, maxSpeed, strafes, sync, duration);
	PlayJumpstatSound(client, tier);
}



// CONSOLE REPORT

static void DoConsoleReport(int client, int jumper, int jumpType, int tier, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration)
{
	int minConsoleTier = GOKZ_JS_GetOption(client, JSOption_MinConsoleTier);
	if (minConsoleTier == 0 || minConsoleTier > tier) // 0 means disabled
	{
		return;
	}
	
	PrintToConsole(client, "%t", "Console Jump Report", 
		jumper, 
		distance, 
		gC_JumpTypes[jumpType], 
		gC_ModeNames[GOKZ_GetCoreOption(jumper, Option_Mode)], 
		offset, "Offset", 
		height, "Height", 
		RoundFloat(preSpeed), "Pre", 
		RoundFloat(maxSpeed), "Max", 
		strafes, strafes == 1 ? "Strafe" : "Strafes", 
		sync, "Sync", 
		duration, "Airtime");
	PrintToConsole(client, "  #. %12t%12t%12t%t", "Sync (Table)", "Gain (Table)", "Loss (Table)", "Airtime (Table)");
	if (GetStrafeAirtime(jumper, 0) > 0.001)
	{
		PrintToConsole(client, "  0. -           -           -           %3d%%", RoundFloat(GetStrafeAirtime(jumper, 0)));
	}
	for (int strafe = 1; strafe <= strafes && strafe < JS_MAX_TRACKED_STRAFES; strafe++)
	{
		PrintToConsole(client, 
			" %2d. %3.0f%%        %-11.3f %-11.3f %3d%%", 
			strafe, 
			GetStrafeSync(jumper, strafe), 
			GetStrafeGain(jumper, strafe), 
			GetStrafeLoss(jumper, strafe), 
			RoundFloat(GetStrafeAirtime(jumper, strafe)));
	}
	PrintToConsole(client, ""); // New line
}



// CHAT REPORT

static void DoChatReport(int client, int jumper, int jumpType, int tier, float distance, float preSpeed, float maxSpeed, int strafes, float sync)
{
	int minChatTier = GOKZ_JS_GetOption(client, JSOption_MinChatTier);
	if (minChatTier == 0 || minChatTier > tier) // 0 means disabled
	{
		return;
	}
	
	GOKZ_PrintToChat(client, true, 
		"%s%s{grey}: %s%.1f {grey}[%s {grey}| %s {grey}| %s {grey}| %s{grey}]", 
		gC_DistanceTierChatColours[tier], 
		gC_JumpTypesShort[jumpType], 
		gC_DistanceTierChatColours[tier], 
		distance, 
		GetStrafesString(client, strafes), 
		GetPreSpeedString(client, jumper, preSpeed), 
		GetMaxSpeedString(client, maxSpeed), 
		GetSyncString(client, sync));
}

static char[] GetStrafesString(int client, int strafes)
{
	char strafesString[32];
	FormatEx(strafesString, sizeof(strafesString), 
		"{lime}%d{grey} %T", 
		strafes, 
		strafes == 1 ? "Strafe" : "Strafes", client);
	return strafesString;
}

static char[] GetPreSpeedString(int client, int jumper, float preSpeed)
{
	char preSpeedString[32];
	FormatEx(preSpeedString, sizeof(preSpeedString), 
		"%s%d{grey} %T", 
		GOKZ_GetHitPerf(jumper) ? "{green}" : "{lime}", 
		RoundFloat(preSpeed), 
		"Pre", client);
	return preSpeedString;
}

static char[] GetMaxSpeedString(int client, float maxSpeed)
{
	char maxSpeedString[32];
	FormatEx(maxSpeedString, sizeof(maxSpeedString), 
		"{lime}%d{grey} %T", 
		RoundFloat(maxSpeed), 
		"Max", client);
	return maxSpeedString;
}

static char[] GetSyncString(int client, float sync)
{
	char syncString[32];
	FormatEx(syncString, sizeof(syncString), 
		"{lime}%.0f%%%%{grey} %T", 
		sync, 
		"Sync", client);
	return syncString;
}



// SOUNDS

static bool LoadSounds()
{
	KeyValues kv = new KeyValues("sounds");
	if (!kv.ImportFromFile(JS_CFG_SOUNDS))
	{
		return false;
	}
	
	char downloadPath[256];
	for (int tier = DistanceTier_Impressive; tier < DISTANCETIER_COUNT; tier++)
	{
		kv.GetString(gC_DistanceTierKeys[tier], sounds[tier], sizeof(sounds[]));
		FormatEx(downloadPath, sizeof(downloadPath), "sound/%s", sounds[tier]);
		AddFileToDownloadsTable(downloadPath);
		PrecacheSound(sounds[tier]);
	}
	
	delete kv;
	return true;
} 