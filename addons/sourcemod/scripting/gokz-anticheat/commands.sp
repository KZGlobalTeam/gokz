void RegisterCommands()
{
	RegAdminCmd("sm_bhopcheck", CommandBhopCheck, ADMFLAG_ROOT, "[KZ] Show bunnyhop stats report including perf ratio and scroll pattern.");
	RegConsoleCmd("sm_simulate_cheater", CommandCheatSim, "[KZ] Pretend you're a cheater.");
	RegConsoleCmd("sm_remove_cheater", CommandRemoveCheat, "yes");
}

public Action CommandBhopCheck(int client, int args)
{
	if (args == 0)
	{
		if (GOKZ_AC_GetSampleSize(client) == 0)
		{
			GOKZ_PrintToChat(client, true, "%t", "Not Enough Bhops (Self)");
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
				COMMAND_FILTER_NO_IMMUNITY | COMMAND_FILTER_NO_BOTS, 
				targetName, 
				sizeof(targetName), 
				tnIsML)) <= 0)
	{
		ReplyToTargetError(client, targetCount);
		return Plugin_Handled;
	}
	
	if (targetCount >= 2)
	{
		GOKZ_PrintToChat(client, true, "%t", "See Console");
		for (int i = 0; i < targetCount; i++)
		{
			if (GOKZ_AC_GetSampleSize(targetList[i]) == 0)
			{
				PrintToConsole(client, "%t", "Not Enough Bhops (Console)", targetList[i]);
			}
			else
			{
				PrintBhopCheckToConsole(client, targetList[i]);
			}
		}
	}
	else
	{
		if (GOKZ_AC_GetSampleSize(targetList[0]) == 0)
		{
			if (targetList[0] == client)
			{
				GOKZ_PrintToChat(client, true, "%t", "Not Enough Bhops (Self)");
			}
			else
			{
				GOKZ_PrintToChat(client, true, "%t", "Not Enough Bhops", targetList[0]);
			}
		}
		else
		{
			PrintBhopCheckToChat(client, targetList[0]);
		}
	}
	
	return Plugin_Handled;
}

public Action CommandCheatSim(int client, int args)
{
	GOKZ_DB_SetCheater(client, true);
	return Plugin_Handled;
}

public Action CommandRemoveCheat(int client, int args)
{
	GOKZ_DB_SetCheater(client, false);
	return Plugin_Handled;
}