void RegisterCommands()
{
	RegConsoleCmd("sm_jumpstats", CommandJumpstats, "[KZ] Open the jumpstats options menu.");
	RegConsoleCmd("sm_ljstats", CommandJumpstats, "[KZ] Open the jumpstats options menu.");
	RegConsoleCmd("sm_js", CommandJumpstats, "[KZ] Open the jumpstats options menu.");
	
	// Records
	RegConsoleCmd("sm_ljpb", CommandLJPB, "[KZ] Display your longjump personal best.");
	RegConsoleCmd("sm_bhpb", CommandBHPB, "[KZ] Display your bunnyhop personal best.");
	RegConsoleCmd("sm_mbhpb", CommandMBHPB, "[KZ] Display your multi bunnyhop personal best.");
	RegConsoleCmd("sm_wjpb", CommandWJPB, "[KZ] Display your weirdjump personal best.");
	RegConsoleCmd("sm_lajpb", CommandLAJPB, "[KZ] Display your ladderjump personal best.");
	RegConsoleCmd("sm_lahpb", CommandLAHPB, "[KZ] Display your ladderhop personal best.");
	RegConsoleCmd("sm_jstop", CommandJSTop, "[KZ] Display the top jumpstats on this server.");
}

public Action CommandJumpstats(int client, int args)
{
	DisplayJumpstatsOptionsMenu(client);
	return Plugin_Handled;
} 

public Action CommandLJPB(int client, int args)
{
	DisplayJumpstatRecordCommand(client, client, JumpType_LongJump);
	return Plugin_Handled;
}

public Action CommandBHPB(int client, int args)
{
	DisplayJumpstatRecordCommand(client, client, JumpType_Bhop);
	return Plugin_Handled;
}

public Action CommandMBHPB(int client, int args)
{
	DisplayJumpstatRecordCommand(client, client, JumpType_MultiBhop);
	return Plugin_Handled;
}

public Action CommandWJPB(int client, int args)
{
	DisplayJumpstatRecordCommand(client, client, JumpType_WeirdJump);
	return Plugin_Handled;
}

public Action CommandLAJPB(int client, int args)
{
	DisplayJumpstatRecordCommand(client, client, JumpType_LadderJump);
	return Plugin_Handled;
}

public Action CommandLAHPB(int client, int args)
{
	DisplayJumpstatRecordCommand(client, client, JumpType_Ladderhop);
	return Plugin_Handled;
}

public Action CommandJSTop(int client, int args)
{
	DisplayJumpTopModeMenu(client);
	return Plugin_Handled;
}

void DisplayJumpstatRecordCommand(int client, int args, int jumpType)
{
	if(args >= 1)
	{
		char argMap[33];
		GetCmdArg(1, argMap, sizeof(argMap));
		DisplayJumpstatRecord(client, jumpType, argMap);
	}
	else
	{
		DisplayJumpstatRecord(client, jumpType);
	}
}
