/*
	Bhop Tracking
	
	Track player's jump inputs and whether or not they hit perfs
	for a number of their recent bunnyhops.
*/



// =========================  PUBLIC  ========================= //

// Returns the ratio of perfect bunnyhops to total bunnyhops
float GetPerfRatio(int client, int sampleSize = BHOP_SAMPLES)
{
	bool[] perfs = new bool[sampleSize];
	GOKZ_AM_GetHitPerf(client, perfs, sampleSize);
	int maxIndex = IntMin(gI_BhopCount[client], sampleSize);
	int bhopCount = 0, perfCount = 0;
	
	for (int i = 0; i < maxIndex; i++)
	{
		bhopCount++;
		if (perfs[i])
		{
			perfCount++;
		}
	}
	return float(perfCount) / float(bhopCount);
}

// Returns the number of perfect bunnyhops in a sample size
int GetPerfCount(int client, int sampleSize = BHOP_SAMPLES)
{
	bool[] perfs = new bool[sampleSize];
	GOKZ_AM_GetHitPerf(client, perfs, sampleSize);
	int maxIndex = IntMin(gI_BhopCount[client], sampleSize);
	int perfCount = 0;
	
	for (int i = 0; i < maxIndex; i++)
	{
		if (perfs[i])
		{
			perfCount++;
		}
	}
	return perfCount;
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
		if (perfs[i])
		{
			Format(report, sizeof(report), "%s %s%d", 
				report, 
				colours ? "{green}" : "P", 
				jumpInputs[i]);
		}
		else
		{
			Format(report, sizeof(report), "%s %s%d", 
				report, 
				colours ? "{default}" : "", 
				jumpInputs[i]);
		}
	}
	
	return report;
}



// =========================  LISTENERS  ========================= //

void OnClientPutInServer_BhopTracking(int client)
{
	ResetBhopStats(client);
}

void OnPlayerRunCmd_BhopTracking(int client, int buttons, int cmdnum)
{
	if (!IsPlayerAlive(client) || IsFakeClient(client))
	{
		return;
	}
	
	// If bhop was last tick, then record the stats
	if (HitBhop(client, cmdnum))
	{
		RecordBhopStats(client, Movement_GetHitPerf(client), CountJumpInputs(client));
		CheckForBhopMacro(client);
	}
	
	// Records buttons every tick (after checking if b-hop occurred)
	RecordButtons(client, buttons);
}



// =========================  PRIVATE  ========================= //

static void CheckForBhopMacro(int client)
{
	// Make sure there are enough samples
	if (gI_BhopCount[client] < 20)
	{
		return;
	}
	
	int perfCount = GOKZ_AM_GetPerfCount(client, 20);
	float perfRatio = GOKZ_AM_GetPerfRatio(client, 20);
	int repeatingJumpInput = CheckForRepeatingJumpInputCount(client, 20);
	
	// TODO Don't make these checks up.
	
	// Check #1
	if (perfCount >= 17) // 85%
	{
		char details[128];
		FormatEx(details, sizeof(details), 
			"Perfs: %.2f%% (20 samples), Pattern: %s", 
			perfRatio * 100, 
			GenerateBhopPatternReport(client, 20, false));
		Call_OnPlayerSuspected(client, AMReason_BhopMacro, details);
		return;
	}
	
	// Check #2	
	if (perfCount >= 14 && repeatingJumpInput >= 2) // 70%
	{
		char details[128];
		FormatEx(details, sizeof(details), 
			"Perfs: %.2f%% (20 samples), Pattern: %s", 
			perfRatio * 100, 
			GenerateBhopPatternReport(client, 20, false));
		Call_OnPlayerSuspected(client, AMReason_BhopMacro, details);
		return;
	}
}

// Returns -1, or the repeating input if there if there is a input repeating more than 75% of the time
static int CheckForRepeatingJumpInputCount(int client, int sampleSize = BHOP_SAMPLES)
{
	int maxIndex = IntMin(gI_BhopCount[client], sampleSize);
	int[] jumpInputs = new int[sampleSize];
	GOKZ_AM_GetJumpInputs(client, jumpInputs, sampleSize);
	int maxJumpInputs = RoundToCeil(BUTTON_SAMPLES / 2.0);
	int[] jumpInputsFrequency = new int[maxJumpInputs];
	
	// Count up all the in jump patterns
	for (int i = 0; i < maxIndex; i++)
	{
		jumpInputsFrequency[jumpInputs[i]]++;
	}
	
	// Returns i if more than 75% of the sample size is the same IN_JUMP count
	int threshold = RoundToCeil(float(sampleSize) * 0.75);
	for (int i = 1; i < maxJumpInputs; i++)
	{
		if (jumpInputsFrequency[i] > threshold)
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

// Records stats of the bhop
static void RecordBhopStats(int client, bool hitPerf, int jumpInputs)
{
	gI_BhopIndex[client] = NextIndex(gI_BhopIndex[client], BHOP_SAMPLES);
	gB_BhopHitPerf[client][gI_BhopIndex[client]] = hitPerf;
	gI_BhopJumpInputs[client][gI_BhopIndex[client]] = jumpInputs;
	gI_BhopCount[client]++;
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