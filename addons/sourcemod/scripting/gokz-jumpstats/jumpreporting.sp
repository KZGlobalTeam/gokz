/*
	Jump Reporting
	
	Jumpstat chat and console reports.
*/



#define SOUNDS_CFG_PATH "cfg/sourcemod/gokz/gokz-jumpstats-sounds.cfg"

static char tierColours[DISTANCETIER_COUNT][] =  { "{grey}", "{grey}", "{blue}", "{green}", "{darkred}", "{gold}" };
static char sounds[DISTANCETIER_COUNT][256];



// =========================  LISTENERS  ========================= //

void OnLanding_JumpReporting(int client, int jumpType, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration)
{
	int tier = GetDistanceTier(jumpType, GOKZ_GetOption(client, Option_Mode), distance, offset);
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

void OnMapStart_JumpReporting()
{
	if (!LoadSounds())
	{
		SetFailState("Invalid or missing %s", SOUNDS_CFG_PATH);
	}
}



// =========================  PRIVATE  ========================= //

static void DoJumpstatsReport(int client, int jumper, int jumpType, int tier, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration)
{
	if (GOKZ_JS_GetOption(client, JSOption_JumpstatsMaster) == JumpstatsMaster_Disabled)
	{
		return;
	}
	
	DoChatReport(client, jumper, jumpType, tier, distance, height, preSpeed, maxSpeed, strafes, sync);
	DoConsoleReport(client, jumper, jumpType, tier, distance, offset, height, preSpeed, maxSpeed, strafes, sync, duration);
	PlayJumpstatSound(client, tier);
}



// CONSOLE REPORT

static void DoConsoleReport(int client, int jumper, int jumpType, int tier, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration)
{
	if (GOKZ_JS_GetOption(client, JSOption_MinConsoleTier) > tier)
	{
		return;
	}
	
	PrintToConsole(client, "%t", "Console Jump Report", 
		jumper, 
		distance, 
		gC_JumpTypes[jumpType], 
		gC_ModeNames[GOKZ_GetOption(jumper, Option_Mode)], 
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
	for (int strafe = 1; strafe <= strafes && strafe < MAX_TRACKED_STRAFES; strafe++)
	{
		PrintToConsole(client, 
			" %2d. %3d%%        %-11.3f %-11.3f %3d%%", 
			strafe, 
			RoundFloat(GetStrafeSync(jumper, strafe)), 
			GetStrafeGain(jumper, strafe), 
			GetStrafeLoss(jumper, strafe), 
			RoundFloat(GetStrafeAirtime(jumper, strafe)));
	}
	PrintToConsole(client, ""); // New line
}



// CHAT REPORT

static void DoChatReport(int client, int jumper, int jumpType, int tier, float distance, float height, float preSpeed, float maxSpeed, int strafes, float sync)
{
	if (GOKZ_JS_GetOption(client, JSOption_MinChatTier) > tier)
	{
		return;
	}
	
	GOKZ_PrintToChat(client, true, 
		"%s%s{grey}: %s%s {grey}[%s {grey}| %s {grey}| %s {grey}| %s {grey}| %s{grey}]", 
		tierColours[tier], 
		gC_JumpTypesShort[jumpType], 
		tierColours[tier], 
		GetDistanceString(client, distance), 
		GetStrafesString(client, strafes), 
		GetPreSpeedString(client, jumper, preSpeed), 
		GetMaxSpeedString(client, maxSpeed), 
		GetHeightString(client, height), 
		GetSyncString(client, sync));
}

static char[] GetDistanceString(int client, float distance)
{
	char distanceString[128];
	FormatEx(distanceString, sizeof(distanceString), "%.2f %T", distance, "units", client);
	return distanceString;
}

static char[] GetStrafesString(int client, int strafes)
{
	char strafesString[32];
	FormatEx(strafesString, sizeof(strafesString), "{lime}%d{grey} %T", strafes, strafes == 1 ? "Strafe" : "Strafes", client);
	return strafesString;
}

static char[] GetPreSpeedString(int client, int jumper, float preSpeed)
{
	char preSpeedString[32];
	if (GOKZ_GetHitPerf(jumper))
	{
		FormatEx(preSpeedString, sizeof(preSpeedString), "{green}%.0f{grey} %T", preSpeed, "Pre", client);
	}
	else
	{
		FormatEx(preSpeedString, sizeof(preSpeedString), "{lime}%.0f{grey} Pre", preSpeed, "Pre", client);
	}
	return preSpeedString;
}

static char[] GetMaxSpeedString(int client, float maxSpeed)
{
	char maxSpeedString[32];
	FormatEx(maxSpeedString, sizeof(maxSpeedString), "{lime}%.0f{grey} %T", maxSpeed, "Max", client);
	return maxSpeedString;
}

static char[] GetHeightString(int client, float height)
{
	char heightString[32];
	FormatEx(heightString, sizeof(heightString), "{lime}%.0f{grey} %T", height, "Height", client);
	return heightString;
}

static char[] GetSyncString(int client, float sync)
{
	char syncString[32];
	FormatEx(syncString, sizeof(syncString), "{lime}%.0f%%%%{grey} %T", sync, "Sync", client);
	return syncString;
}



// SOUNDS

void PlayJumpstatSound(int client, int tier)
{
	if (tier <= DistanceTier_Meh || GOKZ_JS_GetOption(client, JSOption_MinSoundTier) > tier)
	{
		return;
	}
	
	EmitSoundToClientAny(client, sounds[tier]);
}

static bool LoadSounds()
{
	KeyValues kv = new KeyValues("sounds");
	if (!kv.ImportFromFile(SOUNDS_CFG_PATH))
	{
		return false;
	}
	
	char downloadPath[256];
	for (int tier = DistanceTier_Impressive; tier < DISTANCETIER_COUNT; tier++)
	{
		kv.GetString(gC_KeysDistanceTier[tier], sounds[tier], sizeof(sounds[]));
		FormatEx(downloadPath, sizeof(downloadPath), "sound/%s", sounds[tier]);
		AddFileToDownloadsTable(downloadPath);
		PrecacheSoundAny(sounds[tier]);
	}
	
	kv.Close();
	return true;
} 