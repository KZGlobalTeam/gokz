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
	if (args == 0)
	{
		if (GOKZ_AM_GetSampleSize(client) == 0)
		{
			GOKZ_PrintToChat(client, true, "{grey}You have not bhopped enough for a bhop check.");
		}
		else
		{
			PrintBhopCheckToChat(client, client);
		}
		return Plugin_Handled;
	}
	
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	char targetName[MAX_TARGET_LENGTH];
	int targetList[MAXPLAYERS], targetCount;
	bool tnIsML;
	
	if ((targetCount = ProcessTargetString(
				arg, 
				client, 
				targetList, 
				MAXPLAYERS, 
				COMMAND_FILTER_NO_IMMUNITY | COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_CONNECTED, 
				targetName, 
				sizeof(targetName), 
				tnIsML)) <= 0)
	{
		ReplyToTargetError(client, targetCount);
		return Plugin_Handled;
	}
	
	if (targetCount >= 2)
	{
		GOKZ_PrintToChat(client, true, "{grey}See console for output.");
		for (int i = 0; i < targetCount; i++)
		{
			if (GOKZ_AM_GetSampleSize(targetList[i]) == 0)
			{
				PrintToConsole(client, "%n has not bhopped enough for a bhop check. Skipping...", targetList[i]);
				continue;
			}
			PrintBhopCheckToConsole(client, targetList[i]);
		}
	}
	else
	{
		if (GOKZ_AM_GetSampleSize(targetList[0]) == 0)
		{
			GOKZ_PrintToChat(client, true, "{lime}%N {grey}has not bhopped enough for a bhop check.", targetList[0]);
		}
		PrintBhopCheckToChat(client, targetList[0]);
	}
	
	return Plugin_Handled;
} 