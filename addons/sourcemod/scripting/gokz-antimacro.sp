#include <sourcemod>

#include <colorvariables>
#include <gokz>

#include <movementapi>
#include <gokz/core>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Anti-Macro", 
	author = "DanZay", 
	description = "GOKZ Macrodox Module", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define BUTTON_SAMPLES 16
#define BHOP_GROUND_TICKS 4
#define BHOP_SAMPLES 32

int gI_ButtonCount[MAXPLAYERS + 1];
int gI_ButtonsIndex[MAXPLAYERS + 1];
int gI_Buttons[MAXPLAYERS + 1][BUTTON_SAMPLES];

int gI_BhopCount[MAXPLAYERS + 1];
int gI_BhopIndex[MAXPLAYERS + 1];
bool gB_BhopHitPerf[MAXPLAYERS + 1][BHOP_SAMPLES];
int gI_BhopInJumps[MAXPLAYERS + 1][BHOP_SAMPLES];



// =========================  PLUGIN  ========================= //

public void OnPluginStart()
{
	RegConsoleCmd("sm_bhopcheck", CommandBhopCheck, "[KZ] Prints your bunnyhop stats report including perf ratio and scroll pattern.");
}

public Action CommandBhopCheck(int client, int args)
{
	// TODO Make this user friendly
	CPrintToChat(client, "SAMPLE SIZE | PERF RATIO | PATTERN");
	int sampleSizes[] =  { 1, 3, 5, 10, 15, 20 };
	for (int i = 0; i < sizeof(sampleSizes); i++)
	{
		CPrintToChat(client, "%d | %.3f | %s", 
			sampleSizes[i], 
			CalcPerfRatio(client, sampleSizes[i]), 
			GenerateBhopCheckReport(client, sampleSizes[i]));
	}
	return Plugin_Handled;
}



// =========================  CLIENT  ========================= //

public void OnClientPutInServer(int client)
{
	ResetStats(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	// If bhop was last tick, then record the stats
	if (HitBhop(client, tickcount))
	{
		RecordBhopStats(client, Movement_GetHitPerf(client), CountJumpInputs(client));
		// TODO Check stats if cheater, then flag them/ban them or something
	}
	
	// Records buttons every tick (after checking if b-hop occurred)
	RecordButtons(client, buttons);
	
	return Plugin_Continue;
}



// =========================  PRIVATE  ========================= //

// Returns true if ther was a jump last tick and was within a number of ticks after landing
static bool HitBhop(int client, int tickcount)
{
	return Movement_GetJumped(client)
	 && Movement_GetTakeoffTick(client) == tickcount - 1
	 && Movement_GetTakeoffTick(client) - Movement_GetLandingTick(client) <= BHOP_GROUND_TICKS;
}

// Reset the tracked stats of the client
static void ResetStats(int client)
{
	gI_ButtonCount[client] = 0;
	gI_ButtonsIndex[client] = 0;
	gI_BhopCount[client] = 0;
	gI_BhopIndex[client] = 0;
}

// Records current button inputs
static int RecordButtons(int client, int buttons)
{
	gI_ButtonsIndex[client] = NextIndex(gI_ButtonsIndex[client], BUTTON_SAMPLES);
	gI_Buttons[client][gI_ButtonsIndex[client]] = buttons;
	gI_ButtonCount[client]++;
}

// Records stats of the bhop
static void RecordBhopStats(int client, bool hitPerf, int inJumps)
{
	gI_BhopIndex[client] = NextIndex(gI_BhopIndex[client], BHOP_SAMPLES);
	gB_BhopHitPerf[client][gI_BhopIndex[client]] = hitPerf;
	gI_BhopInJumps[client][gI_BhopIndex[client]] = inJumps;
	gI_BhopCount[client]++;
}

// Counts the number of times buttons went from !IN_JUMP to IN_JUMP
static int CountJumpInputs(int client, int sampleSize = BUTTON_SAMPLES)
{
	int[] recentButtons = new int[sampleSize];
	SortByRecent(gI_Buttons[client], gI_ButtonsIndex[client], BUTTON_SAMPLES, recentButtons, sampleSize);
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

// Returns the ratio of perfect bunnyhops to total bunnyhops
static float CalcPerfRatio(int client, int sampleSize = BHOP_SAMPLES)
{
	bool[] perfs = new bool[sampleSize];
	SortByRecent(gB_BhopHitPerf[client], gI_BhopIndex[client], BHOP_SAMPLES, perfs, sampleSize);
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

// Generate 'scroll pattern' report
static char[] GenerateBhopCheckReport(int client, int sampleSize = BHOP_SAMPLES, bool colours = true)
{
	char report[512];
	int maxIndex = IntMin(gI_BhopCount[client], sampleSize);
	bool[] perfs = new bool[sampleSize];
	SortByRecent(gB_BhopHitPerf[client], gI_BhopIndex[client], BHOP_SAMPLES, perfs, sampleSize);
	int[] inJumps = new int[sampleSize];
	SortByRecent(gI_BhopInJumps[client], gI_BhopIndex[client], BHOP_SAMPLES, inJumps, sampleSize);
	
	for (int i = 0; i < maxIndex; i++)
	{
		if (colours)
		{
			if (perfs[i])
			{
				Format(report, sizeof(report), "%s {green}%d", report, inJumps[i]);
			}
			else
			{
				Format(report, sizeof(report), "%s {default}%d", report, inJumps[i]);
			}
		}
		else
		{
			Format(report, sizeof(report), "%s %d", report, inJumps[i]);
		}
	}
	return report;
}

// Increment an array index, looping back to the start if necessary
static int NextIndex(int index, int arraySize)
{
	index++;
	if (index == arraySize)
	{
		return 0;
	}
	return index;
}

// Reorders an array with current index at the front, and previous values after, including looping back to the end
static int SortByRecent(const int[] input, int index, int size, int[] buffer, int bufferSize)
{
	int reorderedIndex = 0;
	for (int i = index; reorderedIndex < bufferSize && i >= 0; i--)
	{
		buffer[reorderedIndex] = input[i];
		reorderedIndex++;
	}
	for (int i = size - 1; reorderedIndex < bufferSize && i > index; i--)
	{
		buffer[reorderedIndex] = input[i];
		reorderedIndex++;
	}
} 