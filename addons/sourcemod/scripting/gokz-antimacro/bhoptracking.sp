/*
	Bhop Tracking
	
	Track player's jump inputs and whether or not they hit perfs
	for a number of their recent bunnyhops.
*/



// =========================  PUBLIC  ========================= //

void PrintBhopCheckToChat(int client, int target)
{
	GOKZ_PrintToChat(client, true, 
		"{lime}%N {grey}[{lime}%d%%%% {grey}%t | {lime}%.1f {grey}%t]", 
		target, 
		RoundFloat(GOKZ_AM_GetPerfRatio(target, 20) * 100.0), 
		"Perfs", 
		GOKZ_AM_GetAverageJumpInputs(target, 20), 
		"Average");
	GOKZ_PrintToChat(client, false, 
		" {grey}%t - %s", 
		"Pattern", 
		GenerateBhopPatternReport(target, 20));
}

void PrintBhopCheckToConsole(int client, int target)
{
	PrintToConsole(client, 
		"%N [%d%% %t | %.1f %t]\n %t - %s", 
		target, 
		RoundFloat(GOKZ_AM_GetPerfRatio(target, 20) * 100.0), 
		"Perfs", 
		GOKZ_AM_GetAverageJumpInputs(target, 20), 
		"Average", 
		"Pattern", 
		GenerateBhopPatternReport(target, 20, false));
}

// Generate 'scroll pattern' report
char[] GenerateBhopPatternReport(int client, int sampleSize = BHOP_SAMPLES, bool colours = true)
{
	char report[512];
	int maxIndex = IntMin(gI_BhopCount[client], sampleSize);
	bool[] perfs = new bool[sampleSize];
	GOKZ_AM_GetHitPerf(client, perfs, sampleSize);
	int[] jumpInputs = new int[sampleSize];
	GOKZ_AM_GetJumpInputs(client, jumpInputs, sampleSize);
	
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



// =========================  LISTENERS  ========================= //

void OnClientPutInServer_BhopTracking(int client)
{
	ResetBhopStats(client);
}

void OnPlayerRunCmd_BhopTracking(int client, int cmdnum)
{
	if (!IsPlayerAlive(client) || IsFakeClient(client))
	{
		return;
	}
	
	int nextIndex = NextIndex(gI_BhopIndex[client], BHOP_SAMPLES);
	
	// If bhop was last tick, then record the stats
	if (HitBhop(client, cmdnum))
	{
		if (cmdnum <= gI_BhopLastCmdnum[client] + BUTTON_SAMPLES)
		{
			// Record post bhop buttons since haven't for previous bhop
			gI_BhopPostJumpInputs[client][nextIndex] = CountJumpInputs(client, cmdnum - gI_BhopLastCmdnum[client]);
			gI_BhopIndex[client] = nextIndex;
			gI_BhopCount[client]++;
			
			// Records stats of the bhop
			gB_BhopHitPerf[client][nextIndex] = Movement_GetHitPerf(client);
			gI_BhopPreJumpInputs[client][nextIndex] = CountJumpInputs(client, cmdnum - gI_BhopLastCmdnum[client]);
		}
		else
		{
			// Records stats of the bhop
			gB_BhopHitPerf[client][nextIndex] = Movement_GetHitPerf(client);
			gI_BhopPreJumpInputs[client][nextIndex] = CountJumpInputs(client);
		}
		
		CheckForBhopMacro(client);
		gI_BhopLastCmdnum[client] = cmdnum;
	}
	else if (cmdnum == gI_BhopLastCmdnum[client] + BUTTON_SAMPLES)
	{
		gI_BhopPostJumpInputs[client][nextIndex] = CountJumpInputs(client);
		gI_BhopIndex[client] = nextIndex;
		gI_BhopCount[client]++;
	}
	
	// Records buttons every tick (after checking if b-hop occurred)
	RecordButtons(client, gI_OldButtons[client]);
}



// =========================  PRIVATE  ========================= //

static void CheckForBhopMacro(int client)
{
	// Make sure there are enough samples
	if (gI_BhopCount[client] < 20)
	{
		return;
	}
	
	int perfsOutOf20 = GOKZ_AM_GetPerfCount(client, 20);
	float averageJumpInputsOutOf20 = GOKZ_AM_GetAverageJumpInputs(client, 20);
	int perfsOutOf30 = GOKZ_AM_GetPerfCount(client, 30);
	
	// Check #1
	if (perfsOutOf20 >= 19)
	{
		char details[256];
		FormatEx(details, sizeof(details), 
			"High perf ratio - Perfs: %d/20, Pattern: %s", 
			perfsOutOf20, 
			GenerateBhopPatternReport(client, 20, false));
		SuspectPlayer(client, AMReason_BhopHack, details);
		return;
	}
	
	// Check #2
	if (perfsOutOf20 >= 16 && averageJumpInputsOutOf20 <= 2.0 + EPSILON)
	{
		char details[256];
		FormatEx(details, sizeof(details), 
			"1's or 2's pattern - Perfs: %d/20, Pattern: %s", 
			perfsOutOf20, 
			GenerateBhopPatternReport(client, 20, false));
		SuspectPlayer(client, AMReason_BhopHack, details);
		return;
	}
	
	// Check #3
	if (perfsOutOf20 >= 8 && averageJumpInputsOutOf20 >= 20.0 - EPSILON)
	{
		char details[256];
		FormatEx(details, sizeof(details), 
			"High pattern - Perfs: %d/20, Pattern: %s", 
			perfsOutOf20, 
			GenerateBhopPatternReport(client, 20, false));
		SuspectPlayer(client, AMReason_BhopMacro, details);
		return;
	}
	
	// Check #4
	if (perfsOutOf30 >= 15 && CheckForRepeatingJumpInputsCount(client, 0.85, 30) >= 2)
	{
		char details[256];
		FormatEx(details, sizeof(details), 
			"Repeating pattern - Perfs: %d/30, Pattern: %s", 
			perfsOutOf30, 
			GenerateBhopPatternReport(client, 30, false));
		SuspectPlayer(client, AMReason_BhopMacro, details);
		return;
	}
}

/**
 * Returns -1, or the repeating input count if there if there is 
 * an input count that repeats for more than the provided ratio.
 *
 * @param client		Client index.
 * @param ratio			Minimum ratio to be considered 'repeating'.
 * @param sampleSize	Maximum recent bhop samples to include in calculation.
 * @return				The repeating input, or else -1.
 */
static int CheckForRepeatingJumpInputsCount(int client, float ratio = 0.5, int sampleSize = BHOP_SAMPLES)
{
	int maxIndex = IntMin(gI_BhopCount[client], sampleSize);
	int[] jumpInputs = new int[sampleSize];
	GOKZ_AM_GetJumpInputs(client, jumpInputs, sampleSize);
	int maxJumpInputs = BUTTON_SAMPLES + 1;
	int[] jumpInputsFrequency = new int[maxJumpInputs];
	
	// Count up all the in jump patterns
	for (int i = 0; i < maxIndex; i++)
	{
		jumpInputsFrequency[jumpInputs[i]]++;
	}
	
	// Returns i if the given ratio of the sample size has the same jump input count
	int threshold = RoundFloat(float(sampleSize) * ratio);
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
	gI_BhopCount[client] = 0;
	gI_BhopIndex[client] = 0;
}

// Returns true if ther was a jump last tick and was within a number of ticks after landing
static bool HitBhop(int client, int cmdnum)
{
	return Movement_GetJumped(client)
	 && Movement_GetTakeoffCmdNum(client) == cmdnum - 1
	 && Movement_GetTakeoffCmdNum(client) - Movement_GetLandingCmdNum(client) <= BHOP_GROUND_TICKS;
}

// Records current button inputs
static int RecordButtons(int client, int buttons)
{
	gI_ButtonsIndex[client] = NextIndex(gI_ButtonsIndex[client], BUTTON_SAMPLES);
	gI_Buttons[client][gI_ButtonsIndex[client]] = buttons;
	gI_ButtonCount[client]++;
}

// Counts the number of times buttons went from !IN_JUMP to IN_JUMP
static int CountJumpInputs(int client, int sampleSize = BUTTON_SAMPLES)
{
	int[] recentButtons = new int[sampleSize];
	SortByRecent(gI_Buttons[client], BUTTON_SAMPLES, recentButtons, sampleSize, gI_ButtonsIndex[client]);
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