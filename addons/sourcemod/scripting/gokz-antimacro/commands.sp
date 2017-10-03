/*
	Commands
	
	Commands for player and admin use.
*/



// =========================  PUBLIC  ========================= //

void CreateCommands()
{
	RegConsoleCmd("sm_bhopcheck", CommandBhopCheck, "[KZ] Prints your bunnyhop stats report including perf ratio and scroll pattern.");
}



// =========================  COMMAND HANDLERS  ========================= //

public Action CommandBhopCheck(int client, int args)
{
	// TODO Make this user friendly
	
	if (GOKZ_AM_GetSampleSize(client) == 0)
	{
		GOKZ_PrintToChat(client, true, "NO SAMPLES");
		return Plugin_Handled;
	}
	
	GOKZ_PrintToChat(client, true, "SAMPLES | RATIO | PATTERN");
	int sampleSizes[] =  { 1, 3, 5, 10, 15, 20 };
	for (int i = 0; i < sizeof(sampleSizes); i++)
	{
		GOKZ_PrintToChat(client, false, "%d | %.3f | %s", 
			sampleSizes[i], 
			GOKZ_AM_GetPerfRatio(client, sampleSizes[i]), 
			GenerateBhopPatternReport(client, sampleSizes[i]));
		PrintToConsole(client, "%d | %.3f | %s", 
			sampleSizes[i], 
			GOKZ_AM_GetPerfRatio(client, sampleSizes[i]), 
			GenerateBhopPatternReport(client, sampleSizes[i], false));
	}
	return Plugin_Handled;
} 