/*
	Track player's jump inputs and whether they hit perfect
	bunnyhops for a number of their recent bunnyhops.
*/



// =====[ PUBLIC ]=====

void PrintBhopCheckToChat(int client, int target)
{
	GOKZ_PrintToChat(client, true, 
		"{lime}%N {grey}[{lime}%d%%%% {grey}%t | {lime}%.2f {grey}%t]", 
		target, 
		RoundFloat(GOKZ_AC_GetPerfRatio(target, 20) * 100.0), 
		"Perfs", 
		GOKZ_AC_GetAverageJumpInputs(target, 20), 
		"Average");
	GOKZ_PrintToChat(client, false, 
		" {grey}%t - %s", 
		"Pattern", 
		GenerateScrollPattern(target, 20));
}

void PrintBhopCheckToConsole(int client, int target)
{
	PrintToConsole(client, 
		"%N [%d%% %t | %.2f %t]\n %t - %s", 
		target, 
		RoundFloat(GOKZ_AC_GetPerfRatio(target, 20) * 100.0), 
		"Perfs", 
		GOKZ_AC_GetAverageJumpInputs(target, 20), 
		"Average", 
		"Pattern", 
		GenerateScrollPattern(target, 20, false));
}

// Generate 'scroll pattern'
char[] GenerateScrollPattern(int client, int sampleSize = AC_MAX_BHOP_SAMPLES, bool colours = true)
{
	char report[512];
	int maxIndex = IntMin(gI_BhopCount[client], sampleSize);
	bool[] perfs = new bool[maxIndex];
	GOKZ_AC_GetHitPerf(client, perfs, maxIndex);
	int[] jumpInputs = new int[maxIndex];
	GOKZ_AC_GetJumpInputs(client, jumpInputs, maxIndex);
	
	for (int i = 0; i < maxIndex; i++)
	{
		if (colours)
		{
			Format(report, sizeof(report), "%s%s%d ", 
				report, 
				perfs[i] ? "{green}" : "{default}", 
				jumpInputs[i]);
		}
		else
		{
			Format(report, sizeof(report), "%s%d%s ", 
				report, 
				jumpInputs[i], 
				perfs[i] ? "*" : "");
		}
	}
	
	TrimString(report);
	
	return report;
}

// Generate 'scroll pattern' report showing pre and post inputs instead
char[] GenerateScrollPatternEx(int client, int sampleSize = AC_MAX_BHOP_SAMPLES)
{
	char report[512];
	int maxIndex = IntMin(gI_BhopCount[client], sampleSize);
	bool[] perfs = new bool[maxIndex];
	GOKZ_AC_GetHitPerf(client, perfs, maxIndex);
	int[] jumpInputs = new int[maxIndex];
	GOKZ_AC_GetJumpInputs(client, jumpInputs, maxIndex);
	int[] preJumpInputs = new int[maxIndex];
	GOKZ_AC_GetPreJumpInputs(client, preJumpInputs, maxIndex);
	int[] postJumpInputs = new int[maxIndex];
	GOKZ_AC_GetPostJumpInputs(client, postJumpInputs, maxIndex);
	
	for (int i = 0; i < maxIndex; i++)
	{
		Format(report, sizeof(report), "%s(%d%s%d)", 
			report, 
			preJumpInputs[i], 
			perfs[i] ? "*" : " ", 
			postJumpInputs[i]);
	}
	
	TrimString(report);
	
	return report;
}



// =====[ EVENTS ]=====

void OnClientPutInServer_BhopTracking(int client)
{
	ResetBhopStats(client);
}

void OnPlayerRunCmdPost_BhopTracking(int client, int cmdnum)
{
	if (!IsPlayerAlive(client) || IsFakeClient(client))
	{
		return;
	}
	
	int nextIndex = NextIndex(gI_BhopIndex[client], AC_MAX_BHOP_SAMPLES);
	
	// If bhop was last tick, then record the pre bhop inputs.
	// Require two times the button sample size since the last
	// takeoff to avoid pre and post bhop input overlap.
	if (HitBhop(client, cmdnum) && cmdnum >= gI_BhopLastTakeoffCmdnum[client] + AC_MAX_BUTTON_SAMPLES * 2)
	{
		gB_BhopHitPerf[client][nextIndex] = Movement_GetHitPerf(client);
		gI_BhopPreJumpInputs[client][nextIndex] = CountJumpInputs(client);
		gI_BhopLastRecordedBhopCmdnum[client] = cmdnum;
		gB_BhopPostJumpInputsPending[client] = true;
	}
	
	// Record post bhop inputs once enough ticks have passed
	if (gB_BhopPostJumpInputsPending[client] && cmdnum == gI_BhopLastRecordedBhopCmdnum[client] + AC_MAX_BUTTON_SAMPLES)
	{
		gI_BhopPostJumpInputs[client][nextIndex] = CountJumpInputs(client);
		gB_BhopPostJumpInputsPending[client] = false;
		gI_BhopIndex[client] = nextIndex;
		gI_BhopCount[client]++;
		CheckForBhopMacro(client);
	}
	
	// Record buttons AFTER checking for bhop
	RecordButtons(client, gI_OldButtons[client]);
	
	// Record last jump takeoff time
	if (JustJumped(client, cmdnum))
	{
		gI_BhopLastTakeoffCmdnum[client] = cmdnum;
	}
}



// =====[ PRIVATE ]=====

static void CheckForBhopMacro(int client)
{
	if (GOKZ_AC_GetPerfCount(client, 19) == 19)
	{
		SuspectPlayer(client, ACReason_BhopHack, "High perf ratio", GenerateBhopBanStats(client, 19));
	}
	else if (GOKZ_AC_GetPerfCount(client, 30) >= 28)
	{
		SuspectPlayer(client, ACReason_BhopHack, "High perf ratio", GenerateBhopBanStats(client, 30));
	}
	else if (GOKZ_AC_GetPerfCount(client, 20) >= 16 && GOKZ_AC_GetAverageJumpInputs(client, 20) <= 2.0 + EPSILON)
	{
		SuspectPlayer(client, ACReason_BhopHack, "1's or 2's scroll pattern", GenerateBhopBanStats(client, 20));
	}
	else if (gI_BhopCount[client] >= 20 && GOKZ_AC_GetPerfCount(client, 20) >= 8
		 && GOKZ_AC_GetAverageJumpInputs(client, 20) >= 19.0 - EPSILON)
	{
		SuspectPlayer(client, ACReason_BhopMacro, "High scroll pattern", GenerateBhopBanStats(client, 20));
	}
	else if (GOKZ_AC_GetPerfCount(client, 30) >= 10 && CheckForRepeatingJumpInputsCount(client, 25, 30) >= 14)
	{
		SuspectPlayer(client, ACReason_BhopMacro, "Repeating scroll pattern", GenerateBhopBanStats(client, 30));
	}
}

static char[] GenerateBhopBanStats(int client, int sampleSize)
{
	char stats[512];
	FormatEx(stats, sizeof(stats), 
		"Perfs: %d/%d, Average: %.2f, Scroll pattern: %s", 
		GOKZ_AC_GetPerfCount(client, sampleSize), 
		IntMin(gI_BhopCount[client], sampleSize), 
		GOKZ_AC_GetAverageJumpInputs(client, sampleSize), 
		GenerateScrollPatternEx(client, sampleSize));
	return stats;
}

/**
 * Returns -1, or the repeating input count if there if there is 
 * an input count that repeats for more than the provided ratio.
 *
 * @param client		Client index.
 * @param threshold		Minimum frequency to be considered 'repeating'.
 * @param sampleSize	Maximum recent bhop samples to include in calculation.
 * @return				The repeating input, or else -1.
 */
static int CheckForRepeatingJumpInputsCount(int client, int threshold, int sampleSize = AC_MAX_BHOP_SAMPLES)
{
	int maxIndex = IntMin(gI_BhopCount[client], sampleSize);
	int[] jumpInputs = new int[maxIndex];
	GOKZ_AC_GetJumpInputs(client, jumpInputs, maxIndex);
	int maxJumpInputs = AC_MAX_BUTTON_SAMPLES + 1;
	int[] jumpInputsFrequency = new int[maxJumpInputs];
	
	// Count up all the in jump patterns
	for (int i = 0; i < maxIndex; i++)
	{
		jumpInputsFrequency[jumpInputs[i]]++;
	}
	
	// Returns i if the given number of the sample size has the same jump input count
	for (int i = 1; i < maxJumpInputs; i++)
	{
		if (jumpInputsFrequency[i] >= threshold)
		{
			return i;
		}
	}
	
	return -1; // -1 if no repeating jump input found
}

// Reset the tracked bhop stats of the client
static void ResetBhopStats(int client)
{
	gI_ButtonCount[client] = 0;
	gI_ButtonsIndex[client] = 0;
	gI_OldButtons[client] = 0;
	gI_BhopCount[client] = 0;
	gI_BhopIndex[client] = 0;
	gI_BhopLastTakeoffCmdnum[client] = 0;
	gI_BhopLastRecordedBhopCmdnum[client] = 0;
	gB_BhopPostJumpInputsPending[client] = false;
}

// Returns true if ther was a jump last tick and was within a number of ticks after landing
static bool HitBhop(int client, int cmdnum)
{
	return JustJumped(client, cmdnum) && Movement_GetTakeoffCmdNum(client) - Movement_GetLandingCmdNum(client) <= AC_MAX_BHOP_GROUND_TICKS;
}

static bool JustJumped(int client, int cmdnum)
{
	return Movement_GetJumped(client) && Movement_GetTakeoffCmdNum(client) == cmdnum - 1;
}

// Records current button inputs
static int RecordButtons(int client, int buttons)
{
	gI_ButtonsIndex[client] = NextIndex(gI_ButtonsIndex[client], AC_MAX_BUTTON_SAMPLES);
	gI_Buttons[client][gI_ButtonsIndex[client]] = buttons;
	gI_ButtonCount[client]++;
}

// Counts the number of times buttons went from !IN_JUMP to IN_JUMP
static int CountJumpInputs(int client, int sampleSize = AC_MAX_BUTTON_SAMPLES)
{
	int[] recentButtons = new int[sampleSize];
	SortByRecent(gI_Buttons[client], AC_MAX_BUTTON_SAMPLES, recentButtons, sampleSize, gI_ButtonsIndex[client]);
	int maxIndex = IntMin(gI_ButtonCount[client], sampleSize);
	int jumps = 0;
	
	for (int i = 0; i < maxIndex - 1; i++)
	{
		// If buttons went from !IN_JUMP to IN_JUMP
		if (!(recentButtons[i + 1] & IN_JUMP) && recentButtons[i] & IN_JUMP)
		{
			jumps++;
		}
	}
	return jumps;
} 