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
	
	GOKZ_EmitSoundToClient(client, sounds[tier], _, "Jumpstats");
}



// =====[ EVENTS ]=====

void OnMapStart_JumpReporting()
{
	if (!LoadSounds())
	{
		SetFailState("Failed to load file: \"%s\".", JS_CFG_SOUNDS);
	}
}

void OnLanding_JumpReporting(Jump jump)
{
	int minTier;
	int tier = GetDistanceTier(jump.type, GOKZ_GetCoreOption(jump.jumper, Option_Mode), jump.distance, jump.offset);
	if (tier == DistanceTier_None)
	{
		return;
	}
	
	// Report the jumpstat to the client and their spectators
	DoJumpstatsReport(jump.jumper, jump, tier);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && client != jump.jumper)
		{
			if (GetObserverTarget(client) == jump.jumper)
			{
				DoJumpstatsReport(client, jump, tier);
			}
			else 
			{
				minTier = GOKZ_JS_GetOption(client, JSOption_MinChatBroadcastTier);
				if (minTier != 0 && tier >= minTier)
				{
					GOKZ_PrintToChat(client, true, "%t", "Broadcast Jumpstat Chat Report",
						gC_DistanceTierChatColours[tier],
						jump.jumper,
						jump.distance,
						gC_JumpTypes[jump.originalType]);
					DoConsoleReport(client, false, jump, tier, "Console Jump Header");
				}
				
				minTier = GOKZ_JS_GetOption(client, JSOption_MinSoundBroadcastTier);
				if (minTier != 0 && tier >= minTier)
				{
					PlayJumpstatSound(client, tier);
				}
			}
		}
	}
}

void OnFailstat_FailstatReporting(Jump jump)
{
	int tier = GetDistanceTier(jump.type, GOKZ_GetCoreOption(jump.jumper, Option_Mode), jump.distance);
	if (tier == DistanceTier_None)
	{
		return;
	}
	
	// Report the failstat to the client and their spectators
	DoFailstatReport(jump.jumper, jump, tier);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && GetObserverTarget(client) == jump.jumper)
		{
			DoFailstatReport(client, jump, tier);
		}
	}
}

void OnJumpstatAlways_JumpstatAlwaysReporting(Jump jump)
{
	DoJumpstatAlwaysReport(jump.jumper, jump);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && GetObserverTarget(client) == jump.jumper)
		{
			DoJumpstatAlwaysReport(client, jump);
		}
	}
}


void OnFailstatAlways_FailstatAlwaysReporting(Jump jump)
{
	DoFailstatAlwaysReport(jump.jumper, jump);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && GetObserverTarget(client) == jump.jumper)
		{
			DoFailstatAlwaysReport(client, jump);
		}
	}
}



// =====[ PRIVATE ]=====

static void DoJumpstatsReport(int client, Jump jump, int tier)
{
	if (GOKZ_JS_GetOption(client, JSOption_JumpstatsMaster) == JSToggleOption_Disabled)
	{
		return;
	}
	
	DoChatReport(client, false, jump, tier);
	DoConsoleReport(client, false, jump, tier, "Console Jump Header");
	PlayJumpstatSound(client, tier);
}

static void DoFailstatReport(int client, Jump jump, int tier)
{
	if (GOKZ_JS_GetOption(client, JSOption_JumpstatsMaster) == JSToggleOption_Disabled)
	{
		return;
	}
	
	DoChatReport(client, true, jump, tier);
	DoConsoleReport(client, true, jump, tier, "Console Failstat Header");
}

static void DoJumpstatAlwaysReport(int client, Jump jump)
{
	if (GOKZ_JS_GetOption(client, JSOption_JumpstatsMaster) == JSToggleOption_Disabled ||
		GOKZ_JS_GetOption(client, JSOption_JumpstatsAlways) == JSToggleOption_Disabled)
	{
		return;
	}
	
	DoChatReport(client, false, jump, 1);
	DoConsoleReport(client, false, jump, 1, "Console Jump Header");
}

static void DoFailstatAlwaysReport(int client, Jump jump)
{
	if (GOKZ_JS_GetOption(client, JSOption_JumpstatsMaster) == JSToggleOption_Disabled ||
		GOKZ_JS_GetOption(client, JSOption_JumpstatsAlways) == JSToggleOption_Disabled)
	{
		return;
	}
	
	DoChatReport(client, true, jump, 1);
	DoConsoleReport(client, true, jump, 1, "Console Failstat Header");
}




// CONSOLE REPORT

static void DoConsoleReport(int client, bool isFailstat, Jump jump, int tier, char[] header)
{
	int minConsoleTier = GOKZ_JS_GetOption(client, JSOption_MinConsoleTier);
	if ((minConsoleTier == 0 || minConsoleTier > tier) && GOKZ_JS_GetOption(client, JSOption_JumpstatsAlways) == JSToggleOption_Disabled
		|| isFailstat && GOKZ_JS_GetOption(client, JSOption_FailstatsConsole) == JSToggleOption_Disabled)
	{
		return;
	}
	
	char releaseWString[32], blockString[32], edgeString[32], deviationString[32], missString[32];
	
	if (jump.originalType == JumpType_LongJump ||
		jump.originalType == JumpType_LadderJump ||
		jump.originalType == JumpType_WeirdJump ||
		jump.originalType == JumpType_LowpreWeirdJump)
	{
		FormatEx(releaseWString, sizeof(releaseWString), " %s", GetIntConsoleString(client, "W Release", jump.releaseW));
	}
	else if (jump.crouchRelease < 20 && jump.crouchRelease > -20)
	{
		FormatEx(releaseWString, sizeof(releaseWString), " %s", GetIntConsoleString(client, "Crouch Release", jump.crouchRelease));
	}
	
	if (jump.miss > 0.0)
	{
		FormatEx(missString, sizeof(missString), " %s", GetFloatConsoleString2(client, "Miss", jump.miss));
	}
	
	if (jump.block > 0)
	{
		FormatEx(blockString, sizeof(blockString), " %s", GetIntConsoleString(client, "Block", jump.block));
		FormatEx(deviationString, sizeof(deviationString), " %s", GetFloatConsoleString1(client, "Deviation", jump.deviation));
	}
	
	if (jump.edge > 0.0 || (jump.block > 0 && jump.edge == 0.0))
	{
		FormatEx(edgeString, sizeof(edgeString), " %s", GetFloatConsoleString2(client, "Edge", jump.edge));
	}
	
	PrintToConsole(client, "%t", header, jump.jumper, jump.distance, gC_JumpTypes[jump.originalType]);
	
	PrintToConsole(client, "%s%s%s%s %s %s %s %s%s %s %s%s %s %s %s %s %s",
		gC_ModeNamesShort[GOKZ_GetCoreOption(jump.jumper, Option_Mode)],
		blockString,
		edgeString,
		missString,
		GetIntConsoleString(client, jump.strafes == 1 ? "Strafe" : "Strafes", jump.strafes),
		GetSyncConsoleString(client, jump.sync),
		GetFloatConsoleString2(client, "Pre", jump.preSpeed),
		GetFloatConsoleString2(client, "Max", jump.maxSpeed),
		releaseWString,
		GetIntConsoleString(client, "Overlap", jump.overlap),
		GetIntConsoleString(client, "Dead Air", jump.deadair),
		deviationString,
		GetWidthConsoleString(client, jump.width, jump.strafes),
		GetFloatConsoleString1(client, "Height", jump.height),
		GetIntConsoleString(client, "Airtime", jump.duration),
		GetFloatConsoleString1(client, "Offset", jump.offset),
		GetIntConsoleString(client, "Crouch Ticks", jump.crouchTicks));
	
	PrintToConsole(client, "  #.  %12t%12t%12t%12t%12t%9t%t", "Sync (Table)", "Gain (Table)", "Loss (Table)", "Airtime (Table)", "Width (Table)", "Overlap (Table)", "Dead Air (Table)");
	if (jump.strafes_ticks[0] > 0)
	{
		PrintToConsole(client, "  0.  ----      -----     -----     %3.0f%%      -----     --     --", GetStrafeAirtime(jump, 0));
	}
	for (int strafe = 1; strafe <= jump.strafes && strafe < JS_MAX_TRACKED_STRAFES; strafe++)
	{
		PrintToConsole(client,
			" %2d.  %3.0f%%      %5.2f     %5.2f     %3.0f%%      %5.1f°    %2d     %2d", 
			strafe, 
			GetStrafeSync(jump, strafe),
			jump.strafes_gain[strafe],
			jump.strafes_loss[strafe],
			GetStrafeAirtime(jump, strafe),
			FloatAbs(jump.strafes_width[strafe]),
			jump.strafes_overlap[strafe],
			jump.strafes_deadair[strafe]);
	}
	PrintToConsole(client, ""); // New line
}

static char[] GetSyncConsoleString(int client, float sync)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), "| %.0f%% %T", sync, "Sync", client);
	return resultString;
}

static char[] GetWidthConsoleString(int client, float width, int strafes)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), "| %.1f° %T", GetAverageStrafeWidth(strafes, width), "Width", client);
	return resultString;
}

// I couldn't really merge those together
static char[] GetFloatConsoleString1(int client, const char[] stat, float value)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), "| %.1f %T", value, stat, client);
	return resultString;
}

static char[] GetFloatConsoleString2(int client, const char[] stat, float value)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), "| %.2f %T", value, stat, client);
	return resultString;
}

static char[] GetIntConsoleString(int client, const char[] stat, int value)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), "| %d %T", value, stat, client);
	return resultString;
}



// CHAT REPORT

static void DoChatReport(int client, bool isFailstat, Jump jump, int tier)
{
	int minChatTier = GOKZ_JS_GetOption(client, JSOption_MinChatTier);
	if ((minChatTier == 0 || minChatTier > tier) // 0 means disabled
		 && GOKZ_JS_GetOption(client, JSOption_JumpstatsAlways) == JSToggleOption_Disabled)
	{
		return;
	}
	
	char typePostfix[3], color[16], blockStats[32], extBlockStats[32];
	char releaseStats[32], edgeOffset[64], offsetEdge[32], missString[32];
	
	if (isFailstat)
	{
		if (GOKZ_JS_GetOption(client, JSOption_FailstatsChat) == JSToggleOption_Disabled
			&& GOKZ_JS_GetOption(client, JSOption_JumpstatsAlways) == JSToggleOption_Disabled)
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
	
	if (jump.block > 0)
	{
		FormatEx(blockStats, sizeof(blockStats), " | %s", GetFloatChatString(client, "Edge", jump.edge));
		FormatEx(extBlockStats, sizeof(extBlockStats), " | %s", GetFloatChatString(client, "Deviation", jump.deviation));
	}
	
	if (jump.miss > 0.0)
	{
		FormatEx(missString, sizeof(missString), " | %s", GetFloatChatString(client, "Miss", jump.miss));
	}
	
	if (jump.edge > 0.0 || (jump.block > 0 && jump.edge == 0.0))
	{
		if (jump.originalType == JumpType_LadderJump)
		{
			FormatEx(offsetEdge, sizeof(offsetEdge), " | %s", GetFloatChatString(client, "Edge", jump.edge));
		}
		else
		{
			FormatEx(edgeOffset, sizeof(edgeOffset), " | %s", GetFloatChatString(client, "Edge", jump.edge));
		}
	}
	
	if (jump.originalType == JumpType_LongJump ||
		jump.originalType == JumpType_LadderJump ||
		jump.originalType == JumpType_WeirdJump)
	{
		if (jump.releaseW >= 20 || jump.releaseW <= -20)
		{
			FormatEx(releaseStats, sizeof(releaseStats), " | {red}✗ {grey}W", GetReleaseChatString(client, "W Release", jump.releaseW));
		}
		else
		{
			FormatEx(releaseStats, sizeof(releaseStats), " | %s", GetReleaseChatString(client, "W Release", jump.releaseW));
		}
	}
	else if (jump.crouchRelease < 20 && jump.crouchRelease > -20)
	{
		FormatEx(releaseStats, sizeof(releaseStats), " | %s", GetReleaseChatString(client, "Crouch Release", jump.crouchRelease));
	}
	
	if (jump.originalType == JumpType_LadderJump)
	{
		FormatEx(edgeOffset, sizeof(edgeOffset), " | %s", GetFloatChatString(client, "Offset Short", jump.offset));
	}
	else
	{
		FormatEx(offsetEdge, sizeof(offsetEdge), " | %s", GetFloatChatString(client, "Offset", jump.offset));
	}
	
	GOKZ_PrintToChat(client, true, 
		"%s%s%s{grey}: %s%.1f{grey} | %s | %s%s%s", 
		color, 
		gC_JumpTypesShort[jump.originalType], 
		typePostfix, 
		color, 
		jump.distance, 
		GetStrafesSyncChatString(client, jump.strafes, jump.sync), 
		GetSpeedChatString(client, jump.preSpeed, jump.maxSpeed), 
		edgeOffset, 
		releaseStats);
	
	if (GOKZ_JS_GetOption(client, JSOption_ExtendedChatReport) == JSToggleOption_Enabled)
	{
		GOKZ_PrintToChat(client, false, 
			"%s | %s%s%s | %s | %s%s", 
			GetIntChatString(client, "Overlap", jump.overlap), 
			GetIntChatString(client, "Dead Air", jump.deadair), 
			offsetEdge, 
			extBlockStats, 
			GetWidthChatString(client, jump.width, jump.strafes), 
			GetFloatChatString(client, "Height", jump.height),
			missString);
	}
}

static char[] GetStrafesSyncChatString(int client, int strafes, float sync)
{
	char resultString[64];
	FormatEx(resultString, sizeof(resultString), 
		"{lime}%d{grey} %T ({lime}%.0f%%%%{grey})", 
		strafes, "Strafes", client, sync);
	return resultString;
}

static char[] GetSpeedChatString(int client, float preSpeed, float maxSpeed)
{
	char resultString[64];
	FormatEx(resultString, sizeof(resultString), 
		"{lime}%.0f{grey} / {lime}%.0f{grey} %T", 
		preSpeed, maxSpeed, "Speed", client);
	return resultString;
}

static char[] GetReleaseChatString(int client, char[] releaseType, int release)
{
	char resultString[32];
	if (release == 0)
	{
		FormatEx(resultString, sizeof(resultString), 
			"{green}✓{grey} %T", 
			releaseType, client);
	}
	else if (release > 0)
	{
		FormatEx(resultString, sizeof(resultString), 
			"{red}+%d{grey} %T", 
			release, 
			releaseType, client);
	}
	else
	{
		FormatEx(resultString, sizeof(resultString), 
			"{blue}%d{grey} %T", 
			release, 
			releaseType, client);
	}
	return resultString;
}

static char[] GetWidthChatString(int client, float width, int strafes)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), 
		"{lime}%.1f°{grey} %T", 
		GetAverageStrafeWidth(strafes, width), "Width", client);
	return resultString;
}

static float GetAverageStrafeWidth(int strafes, float totalWidth)
{
	if (strafes == 0)
	{
		return 0.0;
	}
	
	return totalWidth / strafes;
}

static char[] GetFloatChatString(int client, const char[] stat, float value)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), 
		"{lime}%.1f{grey} %T", 
		value, stat, client);
	return resultString;
}

static char[] GetIntChatString(int client, const char[] stat, int value)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), 
		"{lime}%d{grey} %T", 
		value, stat, client);
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
