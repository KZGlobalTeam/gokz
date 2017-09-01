/*
	Jump Reporting
	
	Jumpstat chat and console reports.
*/



#define SOUNDS_CFG_PATH "cfg/sourcemod/gokz/gokz-jumpstats-sounds.cfg"

static char tierColours[DISTANCETIER_COUNT][] =  { "{grey}", "{blue}", "{green}", "{darkred}", "{gold}" };



// =========================  LISTENERS  ========================= //

void OnLanding_JumpReporting(int client, int jumpType, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration)
{
	if (jumpType != JumpType_Invalid)
	{
		DoConsoleReport(client, jumpType, distance, offset, height, preSpeed, maxSpeed, strafes, sync, duration);
	}
	
	int tier = GetDistanceTier(jumpType, GOKZ_GetOption(client, Option_Mode), distance, offset);
	if (tier != DistanceTier_None)
	{
		DoChatReport(client, jumpType, distance, height, preSpeed, maxSpeed, strafes, sync, tier);
		PlayJumpstatSound(client, tier);
	}
}

void OnMapStart_JumpReporting()
{
	if (!LoadSounds())
	{
		SetFailState("Invalid or missing %s", SOUNDS_CFG_PATH);
	}
}



// =========================  CONSOLE REPORT  ========================= //

static void DoConsoleReport(int client, int jumpType, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration)
{
	PrintToConsole(client, 
		"You did: %s (%s). Here's your stats report.\n\tDistance:\t%f\n\tOffset:\t\t%f\n\tHeight:\t\t%f\n\tAirtime:\t%f\n\tStrafes:\t%d\n\tPre Speed:\t%f\n\tMax Speed:\t%f\n\tSync:\t\t%f%%\n", 
		gC_JumpTypes[jumpType], 
		gC_JumpTypesShort[jumpType], 
		distance, 
		offset, 
		height, 
		duration, 
		strafes, 
		preSpeed, 
		maxSpeed, 
		sync);
}



// =========================  CHAT REPORT  ========================= //

static void DoChatReport(int client, int jumpType, float distance, float height, float preSpeed, float maxSpeed, int strafes, float sync, int tier)
{
	GOKZ_PrintToChat(client, true, 
		"%s%s{grey}: %s%s {grey}[%s {grey}| %s {grey}| %s {grey}| %s {grey}| %s{grey}]", 
		tierColours[tier], 
		gC_JumpTypesShort[jumpType], 
		tierColours[tier], 
		GetDistanceString(distance), 
		GetStrafesString(strafes), 
		GetPreSpeedString(client, preSpeed), 
		GetMaxSpeedString(maxSpeed), 
		GetHeightString(height), 
		GetSyncString(sync));
}

static char[] GetDistanceString(float distance)
{
	char distanceString[128];
	FormatEx(distanceString, sizeof(distanceString), "%.2f units", distance);
	return distanceString;
}

static char[] GetStrafesString(int strafes)
{
	char strafesString[32];
	if (strafes == 1)
	{
		strafesString = "{lime}1{grey} Strafe";
	}
	else
	{
		FormatEx(strafesString, sizeof(strafesString), "{lime}%d{grey} Strafes", strafes);
	}
	return strafesString;
}

static char[] GetPreSpeedString(int client, float preSpeed)
{
	char preSpeedString[32];
	if (GOKZ_GetHitPerf(client))
	{
		FormatEx(preSpeedString, sizeof(preSpeedString), "{green}%.0f{grey} Pre", preSpeed);
	}
	else
	{
		FormatEx(preSpeedString, sizeof(preSpeedString), "{lime}%.0f{grey} Pre", preSpeed);
	}
	return preSpeedString;
}

static char[] GetMaxSpeedString(float maxSpeed)
{
	char maxSpeedString[32];
	FormatEx(maxSpeedString, sizeof(maxSpeedString), "{lime}%.0f{grey} Max", maxSpeed);
	return maxSpeedString;
}

static char[] GetHeightString(float height)
{
	char heightString[32];
	FormatEx(heightString, sizeof(heightString), "{lime}%.0f{grey} Height", height);
	return heightString;
}

static char[] GetSyncString(float sync)
{
	char syncString[32];
	FormatEx(syncString, sizeof(syncString), "{lime}%.0f%%%%{grey} Sync", sync);
	return syncString;
}



// =========================  SOUNDS  ========================= //

static char sounds[DISTANCETIER_COUNT][256];

void PlayJumpstatSound(int client, int tier)
{
	if (tier <= DistanceTier_Meh || tier >= DISTANCETIER_COUNT)
	{
		return; // No sound available for specified tier
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
	
	delete kv;
	return true;
} 