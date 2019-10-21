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

void OnLanding_JumpReporting(int client, int jumpType, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration, int block, float width, int overlap, int deadair, float deviation, float edge, int releaseW)
{
	int tier = GetDistanceTier(jumpType, GOKZ_GetCoreOption(client, Option_Mode), distance, offset);
	if (tier == DistanceTier_None)
	{
		return;
	}
	
	// Report the jumpstat to the client and their spectators
	DoJumpstatsReport(client, client, jumpType, tier, distance, offset, height, preSpeed, maxSpeed, strafes, sync, duration, block, width, overlap, deadair, deviation, edge, releaseW);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetObserverTarget(i) == client)
		{
			DoJumpstatsReport(i, client, jumpType, tier, distance, offset, height, preSpeed, maxSpeed, strafes, sync, duration, block, width, overlap, deadair, deviation, edge, releaseW);
		}
	}
}

void OnFailstat_FailstatReporting(int client, int jumpType, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration, int block, float width, int overlap, int deadair, float deviation, float edge, int releaseW)
{
	int tier = GetDistanceTier(jumpType, GOKZ_GetCoreOption(client, Option_Mode), distance, 0.0);
	if (tier == DistanceTier_None)
	{
		return;
	}
	
	// Report the jumpstat to the client and their spectators
	DoFailstatReport(client, client, jumpType, tier, distance, offset, height, preSpeed, maxSpeed, strafes, sync, duration, block, width, overlap, deadair, deviation, edge, releaseW);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetObserverTarget(i) == client)
		{
			DoFailstatReport(i, client, jumpType, tier, distance, offset, height, preSpeed, maxSpeed, strafes, sync, duration, block, width, overlap, deadair, deviation, edge, releaseW);
		}
	}
}



// =====[ PRIVATE ]=====

static void DoJumpstatsReport(int client, int jumper, int jumpType, int tier, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration, int block, float width, int overlap, int deadair, float deviation, float edge, int releaseW)
{
	if (GOKZ_JS_GetOption(client, JSOption_JumpstatsMaster) == JumpstatsMaster_Disabled)
	{
		return;
	}
	
	DoChatReport(client, jumper, jumpType, tier, distance, preSpeed, maxSpeed, strafes, sync, releaseW);
	DoConsoleReport(client, jumper, jumpType, tier, distance, offset, height, preSpeed, maxSpeed, strafes, sync, duration, block, width, overlap, deadair, deviation, edge, releaseW);
	PlayJumpstatSound(client, tier);
}

static void DoFailstatReport(int client, int jumper, int jumpType, int tier, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration, int block, float width, int overlap, int deadair, float deviation, float edge, int releaseW)
{
	if (GOKZ_JS_GetOption(client, JSOption_JumpstatsMaster) == JumpstatsMaster_Disabled
		|| GOKZ_JS_GetOption(client, JSOption_Failstats) == Failstats_Disabled)
	{
		return;
	}
	
	DoFailstatChatReport(client, jumper, jumpType, tier, distance, preSpeed, maxSpeed, strafes, sync, releaseW, edge, offset);
	DoFailstatConsoleReport(client, jumper, jumpType, tier, distance, offset, height, preSpeed, maxSpeed, strafes, sync, duration, block, width, overlap, deadair, deviation, edge, releaseW);
}



// CONSOLE REPORT

static void DoConsoleReport(int client, int jumper, int jumpType, int tier, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration, int block, float width, int overlap, int deadair, float deviation, float edge, int releaseW)
{
	int minConsoleTier = GOKZ_JS_GetOption(client, JSOption_MinConsoleTier);
	if (minConsoleTier == 0 || minConsoleTier > tier) // 0 means disabled
	{
		return;
	}
	
	if(block < JS_MIN_LAJ_BLOCK_DISTANCE || (jumpType != JumpType_LadderJump && block < JS_MIN_BLOCK_DISTANCE))
	{
		if (jumpType == JumpType_Bhop || 
			jumpType == JumpType_MultiBhop || 
			jumpType == JumpType_Ladderhop || 
			jumpType == JumpType_WeirdJump)
		{
			PrintToConsole(client, "%t", "Console Hop Report", 
				jumper, 
				distance, 
				gC_JumpTypes[jumpType], 
				gC_ModeNamesShort[GOKZ_GetCoreOption(jumper, Option_Mode)],
				strafes, strafes == 1 ? "Strafe" : "Strafes", 
				sync, "Sync", 
				RoundToPowerOfTen(preSpeed, -2), "Pre", 
				RoundToPowerOfTen(maxSpeed, -2), "Max",
				overlap, "Overlap",
				deadair, "Dead Air",
				width / strafes, "Avg. Width",
				height, "Height", 
				duration, "Airtime",
				offset, "Offset");
		}
		else
		{
			PrintToConsole(client, "%t", "Console Jump Report", 
				jumper, 
				distance, 
				gC_JumpTypes[jumpType], 
				gC_ModeNamesShort[GOKZ_GetCoreOption(jumper, Option_Mode)],
				strafes, strafes == 1 ? "Strafe" : "Strafes", 
				sync, "Sync", 
				RoundToPowerOfTen(preSpeed, -2), "Pre", 
				RoundToPowerOfTen(maxSpeed, -2), "Max",
				releaseW, "W Release",
				overlap, "Overlap",
				deadair, "Dead Air",
				width / strafes, "Avg. Width",
				height, "Height", 
				duration, "Airtime",
				offset, "Offset");
		}
	}
	else
	{
		// Sourcepawn has a function argument limit of 32, so we have to split that up.
		PrintToConsole(client, "%t", "Console Block Jump Header", 
			jumper, 
			distance, 
			gC_JumpTypes[jumpType]);
		if (jumpType == JumpType_Bhop || 
			jumpType == JumpType_MultiBhop || 
			jumpType == JumpType_Ladderhop || 
			jumpType == JumpType_WeirdJump)
		{
			PrintToConsole(client, "%t", "Console Block Hop Report", 
				gC_ModeNamesShort[GOKZ_GetCoreOption(jumper, Option_Mode)],
				block, "Block", 
				edge, "Edge",
				strafes, strafes == 1 ? "Strafe" : "Strafes", 
				sync, "Sync", 
				RoundToPowerOfTen(preSpeed, -2), "Pre", 
				RoundToPowerOfTen(maxSpeed, -2), "Max",
				overlap, "Overlap",
				deadair, "Dead Air",
				deviation, "Deviation",
				width / strafes, "Avg. Width",
				height, "Height",
				duration, "Airtime");
		}
		else
		{
			PrintToConsole(client, "%t", "Console Block Jump Report", 
				gC_ModeNamesShort[GOKZ_GetCoreOption(jumper, Option_Mode)],
				block, "Block", 
				edge, "Edge",
				strafes, strafes == 1 ? "Strafe" : "Strafes", 
				sync, "Sync", 
				RoundToPowerOfTen(preSpeed, -2), "Pre", 
				RoundToPowerOfTen(maxSpeed, -2), "Max",  
				releaseW, "W Release",
				overlap, "Overlap",
				deadair, "Dead Air",
				deviation, "Deviation",
				width / strafes, "Avg. Width",
				height, "Height",
				duration, "Airtime",
				offset);
		}
	}
	
	PrintToConsole(client, "  #.  %12t%12t%12t%12t%12t%9t%t", "Sync (Table)", "Gain (Table)", "Loss (Table)", "Airtime (Table)", "Width (Table)", "Overlap (Table)", "Dead Air (Table)");
	if (GetStrafeAirtime(jumper, 0) > 0.001)
	{
		PrintToConsole(client, "  0.  ----        -----       -----       %3.0f%%        -----       --       --", GetStrafeAirtime(jumper, 0));
	}
	for (int strafe = 1; strafe <= strafes && strafe < JS_MAX_TRACKED_STRAFES; strafe++)
	{
		PrintToConsole(client, 
			" %2d.  %3.0f%%      %5.2f    %5.2f     %3.0f%%      %5.1f°     %2d     %2d", 
			strafe, 
			GetStrafeSync(jumper, strafe), 
			GetStrafeGain(jumper, strafe), 
			GetStrafeLoss(jumper, strafe), 
			GetStrafeAirtime(jumper, strafe),
			GetStrafeWidth(jumper, strafe),
			GetStrafeOverlap(jumper, strafe),
			GetStrafeDeadair(jumper, strafe));
	}
	PrintToConsole(client, ""); // New line
}

static void DoFailstatConsoleReport(int client, int jumper, int jumpType, int tier, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration, int block, float width, int overlap, int deadair, float deviation, float edge, int releaseW)
{
	int minConsoleTier = GOKZ_JS_GetOption(client, JSOption_MinConsoleTier);
	if (minConsoleTier == 0 || minConsoleTier > tier) // 0 means disabled
	{
		return;
	}
	
	// Sourcepawn has a function argument limit of 32, so we have to split that up.
	PrintToConsole(client, "%t", "Console Failstat Header", 
		jumper, 
		distance, 
		gC_JumpTypes[jumpType]);
	if (jumpType == JumpType_Bhop || 
		jumpType == JumpType_MultiBhop || 
		jumpType == JumpType_Ladderhop || 
		jumpType == JumpType_WeirdJump)
	{
		PrintToConsole(client, "%t", "Console Block Hop Report", 
			gC_ModeNamesShort[GOKZ_GetCoreOption(jumper, Option_Mode)],
			block, "Block", 
			edge, "Edge",
			strafes, strafes == 1 ? "Strafe" : "Strafes", 
			sync, "Sync", 
			RoundToPowerOfTen(preSpeed, -2), "Pre", 
			RoundToPowerOfTen(maxSpeed, -2), "Max", 
			overlap, "Overlap",
			deadair, "Dead Air",
			deviation, "Deviation",
			width / strafes, "Avg. Width",
			height, "Height",
			duration, "Airtime");
	}
	else
	{
		PrintToConsole(client, "%t", "Console Block Jump Report", 
			gC_ModeNamesShort[GOKZ_GetCoreOption(jumper, Option_Mode)],
			block, "Block", 
			edge, jumpType == JumpType_LadderJump ? "Offset" : "Edge",
			strafes, strafes == 1 ? "Strafe" : "Strafes", 
			sync, "Sync", 
			RoundToPowerOfTen(preSpeed, -2), "Pre", 
			RoundToPowerOfTen(maxSpeed, -2), "Max", 
			releaseW, "W Release",
			overlap, "Overlap",
			deadair, "Dead Air",
			deviation, "Deviation",
			width / strafes, "Avg. Width",
			height, "Height",
			duration, "Airtime",
			offset);
	}
	PrintToConsole(client, "  #.  %12t%12t%12t%12t%12t%9t%t", "Sync (Table)", "Gain (Table)", "Loss (Table)", "Airtime (Table)", "Width (Table)", "Overlap (Table)", "Dead Air (Table)");
	if (GetStrafeAirtime(jumper, 0) > 0.001)
	{
		PrintToConsole(client, "  0.  ----        -----       -----       %3.0f%%        -----       --       --", GetStrafeAirtime(jumper, 0));
	}
	for (int strafe = 1; strafe <= strafes && strafe < JS_MAX_TRACKED_STRAFES; strafe++)
	{
		PrintToConsole(client, 
			" %2d.  %3.0f%%      %5.2f    %5.2f     %3.0f%%      %5.1f°     %2d     %2d", 
			strafe, 
			GetStrafeSync(jumper, strafe), 
			GetStrafeGain(jumper, strafe), 
			GetStrafeLoss(jumper, strafe), 
			GetStrafeAirtime(jumper, strafe),
			FloatAbs(GetStrafeWidth(jumper, strafe)),
			GetStrafeOverlap(jumper, strafe),
			GetStrafeDeadair(jumper, strafe));
	}
	PrintToConsole(client, ""); // New line
}



// CHAT REPORT

static void DoChatReport(int client, int jumper, int jumpType, int tier, float distance, float preSpeed, float maxSpeed, int strafes, float sync, int releaseW)
{
	int minChatTier = GOKZ_JS_GetOption(client, JSOption_MinChatTier);
	if (minChatTier == 0 || minChatTier > tier) // 0 means disabled
	{
		return;
	}
	
	if (jumpType == JumpType_LongJump
		|| jumpType == JumpType_LadderJump)
	{
		GOKZ_PrintToChat(client, true, 
			"%s%s{grey}: %s%.1f {grey}[%s {grey}| %s {grey}| %s {grey}| %s {grey}| %s{grey}]", 
			gC_DistanceTierChatColours[tier], 
			gC_JumpTypesShort[jumpType], 
			gC_DistanceTierChatColours[tier], 
			distance, 
			GetStrafesString(client, strafes), 
			GetPreSpeedString(client, jumper, preSpeed), 
			GetMaxSpeedString(client, maxSpeed), 
			GetSyncString(client, sync),
			GetWReleaseString(client, releaseW));
	}
	else if (jumpType == JumpType_Bhop || 
		jumpType == JumpType_MultiBhop || 
		jumpType == JumpType_Ladderhop || 
		jumpType == JumpType_WeirdJump)
	{
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
}

static void DoFailstatChatReport(int client, int jumper, int jumpType, int tier, float distance, float preSpeed, float maxSpeed, int strafes, float sync, int releaseW, float edge, float offset)
{
	int minChatTier = GOKZ_JS_GetOption(client, JSOption_MinChatTier);
	if (minChatTier == 0 || minChatTier > tier // 0 means disabled
		|| GOKZ_JS_GetOption(client, JSOption_Failstats) != Failstats_ConsoleChat)
	{
		return;
	}
	
	if (jumpType == JumpType_LongJump)
	{
		GOKZ_PrintToChat(client, true, 
			"%s %s: %.1f [%s {grey}| %s {grey}| %s {grey}| %s {grey}| %s {grey}| %s{grey}]", 
			"Failed",
			gC_JumpTypesShort[jumpType], 
			distance, 
			GetStrafesString(client, strafes), 
			GetPreSpeedString(client, jumper, preSpeed), 
			GetMaxSpeedString(client, maxSpeed), 
			GetSyncString(client, sync),
			GetWReleaseString(client, releaseW),
			GetEdgeString(client, edge));
	}
	else if (jumpType == JumpType_LadderJump)
	{
		GOKZ_PrintToChat(client, true, 
			"%s %s: %.1f [%s {grey}| %s {grey}| %s {grey}| %s {grey}| %s {grey}| %s{grey}]", 
			"Failed",
			gC_JumpTypesShort[jumpType], 
			distance, 
			GetStrafesString(client, strafes), 
			GetPreSpeedString(client, jumper, preSpeed), 
			GetMaxSpeedString(client, maxSpeed), 
			GetSyncString(client, sync),
			GetWReleaseString(client, releaseW),
			GetOffsetString(client, offset));
	}
	else if (jumpType == JumpType_Bhop || 
		jumpType == JumpType_MultiBhop || 
		jumpType == JumpType_Ladderhop || 
		jumpType == JumpType_WeirdJump)
	{
		GOKZ_PrintToChat(client, true, 
			"%s %s: %.1f [%s {grey}| %s {grey}| %s {grey}| %s {grey}| %s{grey}]", 
			"Failed",
			gC_JumpTypesShort[jumpType], 
			distance, 
			GetStrafesString(client, strafes), 
			GetPreSpeedString(client, jumper, preSpeed), 
			GetMaxSpeedString(client, maxSpeed), 
			GetSyncString(client, sync),
			GetEdgeString(client, edge));
	}
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
		"%s%.0f{grey} %T", 
		GOKZ_GetHitPerf(jumper) ? "{green}" : "{lime}", 
		RoundToPowerOfTen(preSpeed, -2), 
		"Pre", client);
	return preSpeedString;
}

static char[] GetMaxSpeedString(int client, float maxSpeed)
{
	char maxSpeedString[32];
	FormatEx(maxSpeedString, sizeof(maxSpeedString), 
		"{lime}%.0f{grey} %T", 
		RoundToPowerOfTen(maxSpeed, -2), 
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

static char[] GetWReleaseString(int client, int releaseW)
{
	char releaseWString[32];
	if(releaseW == 0)
	{
		FormatEx(releaseWString, sizeof(releaseWString), 
			"{green}✓{grey} %T", 
			"W Release", client);
	}
	else if(releaseW > 0)
	{
		FormatEx(releaseWString, sizeof(releaseWString), 
			"{red}+%d{grey} %T", 
			releaseW, 
			"W Release", client);
	}
	else
	{
		FormatEx(releaseWString, sizeof(releaseWString), 
			"{blue}%d{grey} %T", 
			releaseW, 
			"W Release", client);
	}
	return releaseWString;
}

static char[] GetEdgeString(int client, float edge)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), 
		"{lime}%.2f{grey} %T", 
		edge, "Edge", client);
	return resultString;
}

static char[] GetOffsetString(int client, float offset)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), 
		"{lime}%.2f{grey} %T", 
		offset, "Offset", client);
	return resultString;
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
		PrecacheSound(sounds[tier], true);
	}
	
	delete kv;
	return true;
} 
