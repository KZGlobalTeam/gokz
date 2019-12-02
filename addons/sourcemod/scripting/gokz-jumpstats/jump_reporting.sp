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
	int tier = GetDistanceTier(jumpType, GOKZ_GetCoreOption(client, Option_Mode), distance);
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
	if (GOKZ_JS_GetOption(client, JSOption_JumpstatsMaster) == JSToggleOption_Disabled)
	{
		return;
	}
	
	DoChatReport(client, false, jumpType, tier, distance, offset, height, preSpeed, maxSpeed, strafes, sync, block, width, overlap, deadair, deviation, edge, releaseW);
	DoConsoleReport(client, jumper, jumpType, tier, distance, offset, height, preSpeed, maxSpeed, strafes, sync, duration, block, width, overlap, deadair, deviation, edge, releaseW);
	PlayJumpstatSound(client, tier);
}

static void DoFailstatReport(int client, int jumper, int jumpType, int tier, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration, int block, float width, int overlap, int deadair, float deviation, float edge, int releaseW)
{
	if (GOKZ_JS_GetOption(client, JSOption_JumpstatsMaster) == JSToggleOption_Disabled)
	{
		return;
	}
	
	DoChatReport(client, true, jumpType, tier, distance, offset, height, preSpeed, maxSpeed, strafes, sync, block, width, overlap, deadair, deviation, edge, releaseW);
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
	
	if (block == 0)
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
		// SourcePawn has a function argument limit of 32, so we have to split that up.
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
		PrintToConsole(client, "  0.  ----      -----     -----     %3.0f%%      -----     --     --", GetStrafeAirtime(jumper, 0));
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
	if (minConsoleTier == 0 || minConsoleTier > tier // 0 means disabled
		 || GOKZ_JS_GetOption(client, JSOption_FailstatsConsole) == JSToggleOption_Disabled)
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

static void DoChatReport(int client, bool isFailstat, int jumpType, int tier, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, int block, float width, int overlap, int deadair, float deviation, float edge, int releaseW)
{
	int minChatTier = GOKZ_JS_GetOption(client, JSOption_MinChatTier);
	if (minChatTier == 0 || minChatTier > tier) // 0 means disabled
	{
		return;
	}
	
	char typePostfix[3], color[16], blockStats[32], extBlockStats[32], 
	releaseWStats[32], edgeOffset[32], offsetEdge[32];
	
	if (isFailstat)
	{
		if (GOKZ_JS_GetOption(client, JSOption_FailstatsChat) == JSToggleOption_Disabled)
		{
			return;
		}
		strcopy(typePostfix, sizeof(typePostfix), "-F");
		strcopy(color, sizeof(color), "{grey}");
	}
	else
	{
		strcopy(color, sizeof(color), gC_DistanceTierChatColours[tier]);
	}
	
	if (block > 0)
	{
		if (jumpType != JumpType_LadderJump)
		{
			FormatEx(edgeOffset, sizeof(edgeOffset), " | %s", GetEdgeString(client, edge));
		}
		FormatEx(blockStats, sizeof(blockStats), " | %s", GetEdgeString(client, edge));
		FormatEx(extBlockStats, sizeof(extBlockStats), " | %s", GetDeviationString(client, deviation));
	}
	
	if (jumpType == JumpType_LongJump
		 || jumpType == JumpType_LadderJump)
	{
		FormatEx(releaseWStats, sizeof(releaseWStats), " | %s", GetWReleaseString(client, releaseW));
	}
	
	if (jumpType == JumpType_LadderJump)
	{
		FormatEx(edgeOffset, sizeof(edgeOffset), " | %s", GetLadderOffsetString(client, offset));
		FormatEx(offsetEdge, sizeof(offsetEdge), " | %s", GetEdgeString(client, edge));
	}
	else
	{
		FormatEx(offsetEdge, sizeof(offsetEdge), " | %s", GetOffsetString(client, offset));
	}
	
	GOKZ_PrintToChat(client, true, 
		"%s%s%s{grey}: %s%.1f{grey} | %s | %s%s%s", 
		color, 
		gC_JumpTypesShort[jumpType], 
		typePostfix, 
		color, 
		distance, 
		GetStrafesSyncString(client, strafes, sync), 
		GetSpeedString(client, preSpeed, maxSpeed), 
		edgeOffset, 
		releaseWStats);
	
	if (GOKZ_JS_GetOption(client, JSOption_ExtendedChatReport) == JSToggleOption_Enabled)
	{
		GOKZ_PrintToChat(client, false, 
			"%s | %s%s%s | %s | %s", 
			GetOverlapString(client, overlap), 
			GetDeadairString(client, deadair), 
			offsetEdge, 
			extBlockStats, 
			GetWidthString(client, width, strafes), 
			GetHeightString(client, height));
	}
}

static char[] GetStrafesSyncString(int client, int strafes, float sync)
{
	char strafesString[64];
	FormatEx(strafesString, sizeof(strafesString), 
		"{lime}%d{grey} %T ({lime}%.0f%%%%{grey})", 
		strafes, "Strafes", client, sync);
	return strafesString;
}

static char[] GetSpeedString(int client, float preSpeed, float maxSpeed)
{
	char speedString[64];
	FormatEx(speedString, sizeof(speedString), 
		"{lime}%.0f{grey} / {lime}%.0f{grey} %T", 
		preSpeed, maxSpeed, "Speed", client);
	return speedString;
}

static char[] GetWReleaseString(int client, int releaseW)
{
	char releaseWString[32];
	if (releaseW == 0)
	{
		FormatEx(releaseWString, sizeof(releaseWString), 
			"{green}✓{grey} %T", 
			"W Release", client);
	}
	else if (releaseW > 0)
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
		"{lime}%.1f{grey} %T", 
		edge, "Edge", client);
	return resultString;
}

static char[] GetOffsetString(int client, float offset)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), 
		"{lime}%.1f{grey} %T", 
		offset, "Offset", client);
	return resultString;
}

static char[] GetLadderOffsetString(int client, float offset)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), 
		"{lime}%.1f{grey} %T", 
		offset, "Ladder Offset", client);
	return resultString;
}

static char[] GetDeviationString(int client, float deviation)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), 
		"{lime}%.1f{grey} %T", 
		deviation, "Deviation", client);
	return resultString;
}

static char[] GetOverlapString(int client, int overlap)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), 
		"{lime}%d{grey} %T", 
		overlap, "Overlap", client);
	return resultString;
}

static char[] GetDeadairString(int client, int deadair)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), 
		"{lime}%d{grey} %T", 
		deadair, "Dead Air", client);
	return resultString;
}

static char[] GetWidthString(int client, float width, int strafes)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), 
		"{lime}%.1f°{grey} %T", 
		width / strafes, "Width", client);
	return resultString;
}

static char[] GetHeightString(int client, float height)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), 
		"{lime}%.1f{grey} %T", 
		height, "Height", client);
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
