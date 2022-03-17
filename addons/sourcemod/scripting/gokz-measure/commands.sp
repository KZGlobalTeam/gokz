void RegisterCommands()
{
	RegConsoleCmd("+measure", CommandMeasureStart, "[KZ] Set the measure origin.");
	RegConsoleCmd("-measure", CommandMeasureEnd, "[KZ] Set the measure origin.");
	RegConsoleCmd("sm_measure", CommandMeasureMenu, "[KZ] Open the measurement menu.");
	RegConsoleCmd("sm_measuremenu", CommandMeasureMenu, "[KZ] Open the measurement menu.");
	RegConsoleCmd("sm_measureblock", CommandMeasureBlock, "[KZ] Measure the block distance.");
}

public Action CommandMeasureMenu(int client, int args)
{
	DisplayMeasureMenu(client);
	return Plugin_Handled;
}

public Action CommandMeasureStart(int client, int args)
{
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	gB_Measuring[client] = true;
	MeasureGetPos(client, 0);
	return Plugin_Handled;
}

public Action CommandMeasureEnd(int client, int args)
{
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	gB_Measuring[client] = false;
	MeasureGetPos(client, 1);
	MeasureDistance(client, MEASURE_MIN_DIST);
	CreateTimer(4.9, Timer_DeletePoints, GetClientUserId(client));
	return Plugin_Handled;
}

public Action CommandMeasureBlock(int client, int args)
{
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	MeasureBlock(client);
	CreateTimer(4.9, Timer_DeletePoints, GetClientUserId(client));
	return Plugin_Handled;
}